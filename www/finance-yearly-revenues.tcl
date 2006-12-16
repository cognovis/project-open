# /packages/intranet-reporting/www/finance-yearly-revenues.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { start_date "" }
    { end_date "" }
    { date_scale_vars "year month_of_year" }
    { left_scale1 "customer_name" }
    { left_scale2 "" }
    { left_scale3 "" }
    { cost_type_id "3700" }
    { customer_type_id:integer 0 }
    { customer_id:integer 0 }
}


# ------------------------------------------------------------
# Define Dimensions

set left_vars [list]
if {"" != $left_scale1} { lappend left_vars $left_scale1 }
if {"" != $left_scale2} { lappend left_vars $left_scale2 }
if {"" != $left_scale3} { lappend left_vars $left_scale3 }


set date_scale_vars [ns_urldecode $date_scale_vars]
set top_vars $date_scale_vars
set group_vars [concat $top_vars $left_vars]


# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-finance-yearly-revenues"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

set read_p "t"

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}


# ------------------------------------------------------------
# Check Parameters

# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}


# ------------------------------------------------------------
# Page Title & Help Text

set cost_type [db_string cost_type "select im_category_from_id(:cost_type_id)"]
set page_title [lang::message::lookup "" intranet-reporting.Yearly_Evolution_of_by_Project_Type "Yearly Evolution of '%cost_type%' by Project Type"]
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>

This report shows the evolution of sales of different service 
types on a monthly scale.<br>

The purpose of this report is to check if customers suddenly stop
to purchase certain service types and start buying something else.
An example could be a customer that still buys one type of service,
while changing the provider for a different type of service.
<p>
Please Note: Financial documents associated with multiple projects
are not included in this overview.
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set gray "gray"
set sigma "&Sigma;"
set days_in_past 365

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

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
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { 
    set end_date "$end_year-$end_month-01"
}


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/finance-quotes-pos" {start_date end_date} ]


# ------------------------------------------------------------
# Options

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_weeks {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31 32 32 33 33 34 34 35 35 36 36 37 37 38 38 39 39 40 40 41 41 42 42 43 43 44 44 45 45 46 46 47 47 48 48 49 49 50 50 51 51 52 52}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}

set date_scale_vars_options {
	"year month_of_year" "Year and Month" 
	"year quarter_of_year month_of_year" "Year, Quarter and Month" 
	"year quarter_of_year month_of_year day_of_month" "Year, Quarter, Month and Day" 
	"year week_of_year" "Year and Week"
	"month_of_year year" "Month and Year (compare years)"
}

set left_scale_options {
	"" ""
	"project_name" "Project Name"
	"project_nr" "Project Nr"
	"project_type" "Project Type"
	"project_status" "Project Status"

	"customer_name" "Customer Name"
	"customer_path" "Customer Nr"
	"customer_type" "Customer Type"
	"customer_status" "Customer Status"

	"cost_type" "Cost Type"
	"cost_status" "Cost Status"
}


# ------------------------------------------------------------
# Start formatting the page
#

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format "html"

ns_write "
[im_header]
[im_navbar]
<table cellspacing=0 cellpadding=0 border=0>

<form>
[export_form_vars project_id]

<tr valign=top>
<td>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Start Date</td>
	  <td class=form-widget>
	    <input type=textfield name=start_date value=$start_date>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>End Date</td>
	  <td class=form-widget>
	    <input type=textfield name=end_date value=$end_date>
	  </td>
	</tr>

	<tr>
	  <td class=form-label>Date Dimension</td>
	    <td class=form-widget>
	      [im_select -translate_p 0 date_scale_vars $date_scale_vars_options $date_scale_vars]
	    </td>
	</tr>
	<tr>
	  <td class=form-label>Cost Type</td>
	  <td class=form-widget>
	    [im_category_select -include_empty_p 1 -translate_p 1 "Intranet Cost Type" cost_type_id $cost_type_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Customer Type</td>
	  <td class=form-widget>
	    [im_category_select -include_empty_p 1 "Intranet Company Type" customer_type_id $customer_type_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Customer</td>
	  <td class=form-widget>
	    [im_company_select customer_id $customer_id]
	  </td>
	</tr>

	<tr>
	  <td class=form-label>Left 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_scale1 $left_scale_options $left_scale1]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_scale2 $left_scale_options $left_scale2]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 3</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_scale3 $left_scale_options $left_scale3]
	  </td>
	</tr>

	<tr>
	  <td class=form-label></td>
	  <td class=form-widget><input type=submit value=Submit></td>
	</tr>
	</table>
</td>
<td>
	<table>
	</table>
</td>
<td>
	<table cellspacing=2 width=90%>
	<tr><td>$help_text</td></tr>
	</table>
</td>
</tr>
</form>
</table>
<table border=0 cellspacing=1 cellpadding=1>
"



# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]


if {"" != $customer_id && 0 != $customer_id} {
    lappend criteria "c.customer_id = :customer_id"
}

if {"" != $cost_type_id && 0 != $cost_type_id} {
    lappend criteria "c.cost_type_id in (
	select  child_id
	from    im_category_hierarchy
	where   (parent_id = :cost_type_id or child_id = :cost_type_id)
    )"
}

if {"" != $customer_type_id && 0 != $customer_type_id} {
    lappend criteria "pcust.company_type_id in (
	select  child_id
	from    im_category_hierarchy
	where   (parent_id = :customer_type_id or child_id = :customer_type_id)
    )"
}

set where_clause [join $criteria " and\n	    "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

# Inner - Try to be as selective as possible and select
# the relevant data from the fact table.
set inner_sql "
		select
			trunc((c.paid_amount * 
			  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
			  , 2) as paid_amount_converted,
			trunc((c.amount * 
			  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
			  , 2) as amount_converted,
			c.*
		from
			im_costs c
		where
			1=1
			and c.effective_date::date >= to_date(:start_date, 'YYYY-MM-DD')
			and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
			and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
"

# Aggregate additional/important fields to the fact table.
set middle_sql "
	select
		c.*,
		im_category_from_id(c.cost_type_id) as cost_type,
		to_char(c.effective_date, 'YYYY') as year,
		to_char(c.effective_date, 'MM') as month_of_year,
		to_char(c.effective_date, 'Q') as quarter_of_year,
		to_char(c.effective_date, 'IW') as week_of_year,
		to_char(c.effective_date, 'DD') as day_of_month,
		CASE WHEN c.cost_type_id = 3700 THEN c.amount_converted ELSE 0 END as invoice_amount,
		CASE WHEN c.cost_type_id = 3702 THEN c.amount_converted ELSE 0 END as quote_amount,
		CASE WHEN c.cost_type_id = 3724 THEN c.amount_converted ELSE 0 END as delnote_amount,
		substring(c.cost_name, 1, 14) as cost_name_cut,
		p.project_name,
		p.project_nr,
		p.project_type_id,
		im_category_from_id(p.project_type_id) as project_type,
		cust.company_name as customer_name,
		cust.company_path as customer_path,
		cust.company_type_id as customer_type_id,
		im_category_from_id(cust.company_type_id) as customer_type,
		cust.company_status_id as customer_status_id,
		im_category_from_id(cust.company_status_id) as customer_status,
		prov.company_name as provider_name,
		prov.company_path as provider_path,
		prov.company_type_id as provider_type_id,
		im_category_from_id(prov.company_type_id) as provider_type,
		prov.company_status_id as provider_status_id,
		im_category_from_id(prov.company_status_id) as provider_status,

		0 as zero
	from
		($inner_sql) c
		LEFT OUTER JOIN im_projects p ON (c.project_id = p.project_id)
		LEFT OUTER JOIN im_companies cust ON (c.customer_id = cust.company_id)
		LEFT OUTER JOIN im_companies prov ON (c.provider_id = prov.company_id)
	where
		1 = 1
		$where_clause
"

set sql "
select
	sum(c.invoice_amount) as invoice_amount,
	sum(c.quote_amount) as quote_amount,
	sum(c.delnote_amount) as delnote_amount,
	sum(c.paid_amount) as paid_amount,
	[join $group_vars ",\n\t"]
from
	($middle_sql) c
group by
	[join $group_vars ",\n\t"]
"


# ------------------------------------------------------------
# Create a sorted and contiguous upper date dimension

# Date scale is a list of lists.
# Example: {{2006 01} {2006 02} ...}
set date_scale_plain [db_list_of_lists date_scale "
	select distinct
		[join $top_vars ", "]
	from
		(select	im_day_enumerator as day,
		        to_char(im_day_enumerator, 'YYYY') as year,
		        to_char(im_day_enumerator, 'MM') as month_of_year,
		        to_char(im_day_enumerator, 'Q') as quarter_of_year,
		        to_char(im_day_enumerator, 'IW') as week_of_year,
		        to_char(im_day_enumerator, 'DD') as day_of_month
		from
			im_day_enumerator(:start_date, :end_date)
		) d
	order by
		[join $top_vars ", "]
"]


# Add subtotals whenever a "main" (not the most detailed) scale changes
set date_scale [list]
set last_item [lindex $date_scale_plain 0]
foreach scale_item $date_scale_plain {
    set diff_idx -1
    for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
	set last_var [lindex $last_item $i]
	set cur_var [lindex $scale_item $i]
	if {$last_var != $cur_var} {

	    set item [lrange $last_item 0 $i]
	    while {[llength $item] < [llength $last_item]} { lappend item $sigma }
	    lappend date_scale $item
	}
    }
    lappend date_scale $scale_item
    set last_item $scale_item
}

# Add some last elements with total sums etc.
for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
    set item [lrange $last_item 0 $i]
    while {[llength $item] < [llength $last_item]} { lappend item $sigma }
    lappend date_scale $item
}

# Add a very last row with grand total sum over all years and months...
set item [list]
while {[llength $item] < [llength $last_item]} { lappend item $sigma }
lappend date_scale $item



# ------------------------------------------------------------
# Create a sorted left dimension

# Scale is a list of lists.
# Example: {{2006 01} {2006 02} ...}
set left_scale_plain [db_list_of_lists left_scale "
	select distinct
		[join $left_vars ", "]
	from
		($middle_sql) c
	order by
		[join $left_vars ", "]
"]


# Add subtotals whenever a "main" (not the most detailed) scale changes
set left_scale [list]
set last_item [lindex $left_scale_plain 0]
foreach scale_item $left_scale_plain {
    set diff_idx -1
    for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
	set last_var [lindex $last_item $i]
	set cur_var [lindex $scale_item $i]
	if {$last_var != $cur_var} {

	    set item [lrange $last_item 0 $i]
	    while {[llength $item] < [llength $last_item]} { lappend item $sigma }
	    lappend left_scale $item
	}
    }
    lappend left_scale $scale_item
    set last_item $scale_item
}

# Add some last elements with total sums etc.
for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
    set item [lrange $last_item 0 $i]
    while {[llength $item] < [llength $last_item]} { lappend item $sigma }
    lappend left_scale $item
}

# Add a very last row with grand total sum over all years and months...
set item [list]
while {[llength $item] < [llength $last_item]} { lappend item $sigma }
lappend left_scale $item





# ------------------------------------------------------------
# Display the Table Header

set header ""

# Determine how many date rows (year, month, day, ...) we've got
set first_cell [lindex $date_scale 0]
set date_scale_rows [llength $first_cell]
set left_scale_size [llength [lindex $left_scale 0]]

for {set row 0} {$row < $date_scale_rows} { incr row } {
    append header "<tr class=rowtitle>\n"
    append header "<td colspan=$left_scale_size></td>\n"
    for {set col 0} {$col <= [expr [llength $date_scale]-1]} { incr col } {
	set scale_entry [lindex $date_scale $col]
	set scale_item [lindex $scale_entry $row]
	# Check if the previous item was of the same content
	set prev_scale_entry [lindex $date_scale [expr $col-1]]
	set prev_scale_item [lindex $prev_scale_entry $row]
	if {$prev_scale_item == $scale_item} {
	    # Prev and current are same => just skip.
	    # The cell was already covered by the previous entry via "colspan"
	} else {
	    # This is the first entry of a new content.
	    # Look forward to check if we can issue a "colspan" command
	    set colspan 1
	    set next_col [expr $col+1]
	    while {$scale_item == [lindex [lindex $date_scale $next_col] $row]} {
		incr next_col
		incr colspan
	    }
	    append header "\t<td class=rowtitle colspan=$colspan>$scale_item</td>\n"	    
	}
    }
    append header "</tr>\n"
}

ns_write $header


# ------------------------------------------------------------
# Execute query and aggregate values into a Hash array

db_foreach query $sql {

    # Get all possible permutations (N out of M) from the group_vars
    set perms [im_report_take_all_ordered_permutations $group_vars]

    # Add the invoice amount to ALL of the variable permutations.
    # The "full permutation" (all elements of the list) corresponds
    # to the individual cell entries.
    # The "empty permutation" (no variable) corresponds to the
    # gross total of all values.
    # Permutations with less elements correspond to subtotals
    # of the values along the missing dimension. Clear?
    #
    foreach perm $perms {

	# Calculate the key for this permutation
	# something like "$year-$month-$customer_id"
	set key_expr "\$[join $perm "-\$"]"
	set key [eval "set a \"$key_expr\""]

	# Sum up the values for the matrix cells
	set sum 0
	if {[info exists hash($key)]} { set sum $hash($key) }
	
	set amount $invoice_amount
	if {"" == $amount} { set amount 0 }
	set sum [expr $sum + $amount]
	set hash($key) $sum
	
	ns_log Notice "finance-yearly: hash($key) = $sum"
    }
}


# ------------------------------------------------------------
# Display the table body

set ctr 0
foreach left_entry $left_scale {

    set class $rowclass([expr $ctr % 2])
    incr ctr

    # Start the row and show the left_scale values at the left
    ns_write "<tr class=$class>\n"
    foreach val $left_entry { ns_write "<td>$val</td>\n" }

    # Write the left_scale values to their corresponding local 
    # variables so that we can access them easily when calculating
    # the "key".
    for {set i 0} {$i < [llength $left_vars]} {incr i} {
	set var_name [lindex $left_vars $i]
	set var_value [lindex $left_entry $i]
	set $var_name $var_value
    }
    
    foreach top_entry $date_scale {

	# Write the top_scale values to their corresponding local 
	# variables so that we can access them easily for $key
	for {set i 0} {$i < [llength $top_vars]} {incr i} {
	    set var_name [lindex $top_vars $i]
	    set var_value [lindex $top_entry $i]
	    set $var_name $var_value
	}

	# Calculate the key for this permutation
	# something like "$year-$month-$customer_id"
	set key_expr_list [list]
	foreach var_name $group_vars {
	    set var_value [eval set a "\$$var_name"]
	    if {$sigma != $var_value} { lappend key_expr_list $var_name }
	}
	set key_expr "\$[join $key_expr_list "-\$"]"
	set key [eval "set a \"$key_expr\""]

	set val "&nbsp;"
	if {[info exists hash($key)]} { set val $hash($key) }

	ns_log Notice "finance-yearly: hash($key) -> $val"

	ns_write "<td>$val</td>\n"

    }
    ns_write "</tr>\n"
}


# ------------------------------------------------------------
# Finish up the table

ns_write "</table>\n[im_footer]\n"


