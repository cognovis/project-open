# /packages/intranet-reporting-finance/www/finance-costs-monthly.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Report showing the project hierarchy, together with financial information
    and timesheet hours
} {
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { project_id:integer 0}
    { prov_id:integer 0}
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

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

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
	select	c.*,
		to_char(c.effective_date, 'YYYY-MM') as effective_month,
	        round(c.amount * im_exchange_rate(c.effective_date::date, c.currency, :default_currency)::numeric, 2) as amount_converted,
		im_category_from_id(c.cost_type_id) as cost_type,
		prov.company_name as provider_name
	from	im_companies prov,
		im_costs c
		LEFT OUTER JOIN im_expenses e ON (c.cost_id = e.expense_id)
	where	c.provider_id = prov.company_id and
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

db_foreach costs $sql {

    # Setup left dimension
    set costs_providers($provider_id) $provider_name

    # Setup top dimension
    set costs_months($effective_month) $effective_month

    # append the amount to the provider/month cell
    set key "$provider_id-$effective_month"
    set cell ""
    if {[info exists costs_hash($key)]} { set cell $costs_hash($key) }
    append cell "<a href=\"[export_vars]\">$amount_converted</a><br>\n"
    set costs_hash($key) $cell
}


# ------------------------------------------------------------
# Render the Upper dimension
# ------------------------------------------------------------

set upper_dim_html "
	<tr class=rowtitle>
	<td class=rowtitle>&nbsp;</td>
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
foreach provider_id [lsort [array names costs_providers]] {

    # Get the name of the provider
    set provider_name $costs_providers($provider_id)


    append body_html "
	<tr $bgcolor([expr $ctr % 2]) >
	<td>$provider_name</td>
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

