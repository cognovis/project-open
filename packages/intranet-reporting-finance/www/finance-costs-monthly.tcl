# /packages/intranet-reporting-finance/www/finance-costs-monthly.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Report showing the project hierarchy, together with financial information
    and timesheet hours.
    @param sort_by Sort by the nth element of the provider_list list.
	   1 = sum over interval
	   2 = alphabetic
} {
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { project_id:integer 0}
    { prov_id:integer 0}
    { min_sum 100.0 }
    { sort_by 1 }
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-finance-costs-monthly"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

set read_p "t"

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}



# ------------------------------------------------------------
# Constants & Options

set page_title [lang::message::lookup "" intranet-reporting.Finance_Costs_Monthly_title "Finance Provider Costs per Month"]
set context_bar [im_context_bar $page_title]
set context ""
set return_url [im_url_with_query]

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

set sort_by_options {
	1 {By Sum}
	2 {Alphabetic}
}

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set days_in_past 7

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} {
    set start_date "$todays_year-$todays_month-01"
}

db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} {
    set end_date "$end_year-$end_month-01"
}


set provider_url "/intranet/companies/view?customer_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-finance/finance-costs-monthly" {start_date end_date} ]
set current_url [im_url_with_query]


# ------------------------------------------------------------
# Construct SQL
# ------------------------------------------------------------

set criteria [list]
if {"" != $project_id && 0 != $project_id} {
    lappend criteria "p.project_id = :project_id"
}
if {"" != $prov_id && 0 != $prov_id} {
    lappend criteria "p.company_id = :prov_id"
}
set where_clause [join $criteria "\n\tand "]
if {"" != $where_clause} { set where_clause "and $where_clause" }


set sql "
	select	c.cost_id,
		c.cost_name,
		c.cost_nr,
		c.provider_id,
		prov.company_name as provider_name,
		im_category_from_id(c.cost_type_id) as cost_type,
		to_char(c.effective_date, 'YYYY-MM') as effective_month,
	        round(c.amount * im_exchange_rate(c.effective_date::date, c.currency, :default_currency)::numeric, 2) as amount_converted,
		trim(e.external_company_name) as external_company_name,
		bou.url as bou_url
	from	im_costs c
		LEFT OUTER JOIN im_companies prov ON (c.provider_id = prov.company_id)
		LEFT OUTER JOIN persons pe ON (c.provider_id = pe.person_id)
		LEFT OUTER JOIN im_expenses e ON (c.cost_id = e.expense_id),
		acs_objects o,
		(select * from im_biz_object_urls where url_type = 'view') bou
	where	c.cost_id = o.object_id and
		o.object_type = bou.object_type and
		c.cost_type_id in (
			[im_cost_type_expense_item],
			[im_cost_type_bill]
		)
	        and c.effective_date >= to_date(:start_date, 'YYYY-MM-DD')
	        and c.effective_date < to_date(:end_date, 'YYYY-MM-DD')
	        and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
"

# ------------------------------------------------------------
# Stuff the SQL results in a 2 dimensional provider/month matrix
# ------------------------------------------------------------

array set costs_hash {}
array set costs_providers {}
array set costs_months {}
array set costs_sum {}

db_foreach costs $sql {

    # Expenses have the user_id as provider.
    # So we use the "external_company_name" instead.
    if {"" == $provider_name} { 
	set provider_name $external_company_name 
	set provider_id $external_company_name 
    }

    # Deal with empty amounts (should be an exception...)
    if {"" == $amount_converted} { set amount_converted 0.0 }

    # Setup left dimension
    set costs_providers($provider_id) $provider_name

    # Setup top dimension
    set costs_months($effective_month) $effective_month

    # Append the amount to the provider/month cell
    set key "$provider_id-$effective_month"
    set cell ""
    if {[info exists costs_hash($key)]} { set cell $costs_hash($key) }
    append cell "<a href=\"$bou_url$cost_id\">$amount_converted</a><br>\n"
    set costs_hash($key) $cell

    # Aggregate sum per provider
    set sum 0.0
    if {[info exists costs_sum($provider_id)]} { set sum $costs_sum($provider_id) }
    set sum [expr $sum + abs($amount_converted)]
    set costs_sum($provider_id) $sum

}


# ------------------------------------------------------------
# Sort the list of providers according to sum
# ------------------------------------------------------------

set provider_list [list]
foreach provider_id [array names costs_sum] {
    set sum $costs_sum($provider_id)
    set provider_name $costs_providers($provider_id)
    lappend provider_list [list $provider_id $sum [string tolower $provider_name]]
}

# Sort the keys according to sum (2nd element)
switch $sort_by {
    1 { 
	set lambda [lambda {s} { lindex $s 1 } ] 
        set sorted_provider_list [reverse [qsort $provider_list $lambda]]
    }
    2 { 
	set lambda [lambda {s} { lindex $s 2 } ] 
        set sorted_provider_list [qsort $provider_list $lambda]
    }
    default { 
	set lambda [lambda {s} { lindex $s 1 } ] 
        set sorted_provider_list [reverse [qsort $provider_list $lambda]]
    }
}



# ------------------------------------------------------------
# Render the Upper dimension
# ------------------------------------------------------------

set upper_dim_html "
	<tr class=rowtitle>
	<td class=rowtitle>Provider</td>
	<td class=rowtitle>Sum</td>
"
foreach month [lsort [array names costs_months]] {
    append upper_dim_html "	<td class=rowtitle>$month</td>\n"
}
append upper_dim_html "
	</td>
"



# ------------------------------------------------------------
# Render the Table Body
# ------------------------------------------------------------

set body_html ""
set ctr 0
foreach provider_tuple $sorted_provider_list {

    # Get the name of the provider
    set provider_id [lindex $provider_tuple 0]
    set provider_sum [lindex $provider_tuple 1]
    set provider_name $costs_providers($provider_id)

    # Skip providers below min_sum
    if {$provider_sum < $min_sum} { continue }

    append body_html "
	<tr $bgcolor([expr $ctr % 2]) >
	<td>
	$provider_name 
	<a href=[export_vars -base "finance-costs-monthly-update-external-company" {{external_company_name $provider_name} return_url}]>[im_gif arrow_right]</a>
	</td>
	<td align=right>$provider_sum</td>
    "
    foreach month [lsort [array names costs_months]] {
	set key "$provider_id-$month"
	set cell ""
	if {[info exists costs_hash($key)]} { set cell $costs_hash($key) }
	append body_html "\t<td align=right>$cell</td>\n"
    }
    append body_html "
	</tr>
    "
    incr ctr
}

