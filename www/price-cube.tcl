# /packages/intranet-reporting-cubes/www/price-cube.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Cost Cube
} {
    { start_date "" }
    { end_date "" }
    { top_var1 "year quarter_of_year" }
    { top_var2 "" }
    { top_var3 "" }
    { left_var1 "item_uom" }
    { left_var2 "" }
    { left_var3 "" }
    { cost_type_id:multiple "3700" }
    { customer_type_id:integer 0 }
    { customer_id:integer 0 }
    { provider_id:integer 0 }
    { uom_id:integer 0 }
    { left_vars "" }
    { top_vars "" }
}

# ------------------------------------------------------------
# Define Dimensions

# Left Dimension - defined by users selects
set left {}
if {"" != $left_vars} {
    # override left vars with elements from list
    set left_var1 [lindex $left_vars 0]
    set left_var2 [lindex $left_vars 1]
    set left_var3 [lindex $left_vars 2]
}
if {"" != $left_var1} { lappend left $left_var1 }
if {"" != $left_var2} { lappend left $left_var2 }
if {"" != $left_var3} { lappend left $left_var3 }

set top {}
set top_var1 [ns_urldecode $top_var1]
if {"" != $top_var1} { lappend top $top_var1 }
if {"" != $top_var2} { lappend top $top_var2 }
if {"" != $top_var3} { lappend top $top_var3 }

# Flatten lists - kinda dirty...
regsub -all {[\{\}]} $top "" top
regsub -all {[\{\}]} $left "" left


# The complete set of dimensions - used as the key for
# the "cell" hash. Subtotals are calculated by dropping on
# or more of these dimensions
set dimension_vars [concat $top $left]

# Check for duplicate variables
set unique_dimension_vars [lsort -unique $dimension_vars]
if {[llength $dimension_vars] != [llength $unique_dimension_vars]} {
    ad_return_complaint 1 "<b>Duplicate Variable</b>:<br>
    You have specified a variable more then once."
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-cubes-finance"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

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

set cost_type [db_list cost_type "
	select	im_category_from_id(category_id)
	from	im_categories
	where	category_id in ([join $cost_type_id ", "])
"]

set page_title [lang::message::lookup "" intranet-reporting.Price_Cube "Price Cube"]
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>

This Pivot Table ('cube') is a kind of report that shows the prices
for each line of each quote, invoice, bill order purchase order
in the specified interval.
<p>
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
set this_url [export_vars -base "/intranet-reporting/price-cube" {start_date end_date} ]


# ------------------------------------------------------------
# Options

set cost_type_options {
	3700 "Customer Invoice"
	3702 "Quote"
	3724 "Delivery Note"
	3704 "Provider Bill"
	3706 "Purchase Order"
	3722 "Expense Report"
	3718 "Timesheet Cost"
}

set non_active_cost_type_options {
	3714 "Employee Salary"
	3720 "Expense Item"
}

set top_vars_options {
	"" "No Date Dimension" 
	"year" "Year" 
	"year quarter_of_year" "Year and Quarter" 
	"year month_of_year" "Year and Month" 
	"year quarter_of_year month_of_year" "Year, Quarter and Month" 
	"year quarter_of_year month_of_year day_of_month" "Year, Quarter, Month and Day" 
	"year week_of_year" "Year and Week"
	"quarter_of_year year" "Quarter and Year (compare quarters)"
	"month_of_year year" "Month and Year (compare months)"
}

set left_scale_options {
	"" ""
	"item_uom" "Price Unit of Measure"
	"item_type" "Price Type"

	"main_project_name" "Main Project Name"
	"main_project_nr" "Main Project Nr"
	"main_project_type" "Main Project Type"
	"main_project_status" "Main Project Status"
	"main_project_manager" "Main Project Manager"

	"sub_project_name" "Sub Project Name"
	"sub_project_nr" "Sub Project Nr"
	"sub_project_type" "Sub Project Type"
	"sub_project_status" "Sub Project Status"

	"customer_name" "Customer Name"
	"customer_path" "Customer Nr"
	"customer_type" "Customer Type"
	"customer_status" "Customer Status"

	"provider_name" "Provider Name"
	"provider_path" "Provider Nr"
	"provider_type" "Provider Type"
	"provider_status" "Provider Status"

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
<tr valign=top><td>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Start Date</td>
	  <td class=form-widget colspan=3>
	    <input type=textfield name=start_date value=$start_date>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>End Date</td>
	  <td class=form-widget colspan=3>
	    <input type=textfield name=end_date value=$end_date>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Cost Type</td>
	  <td class=form-widget colspan=3>
	    [im_select -translate_p 1 -multiple_p 1 -size 7 cost_type_id $cost_type_options $cost_type_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Unit of Measure</td>
	  <td class=form-widget colspan=3>
	    [im_category_select -include_empty_p 1 "Intranet UoM" uom_id $uom_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Customer Type</td>
	  <td class=form-widget colspan=3>
	    [im_category_select -include_empty_p 1 "Intranet Company Type" customer_type_id $customer_type_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Customer</td>
	  <td class=form-widget colspan=3>
	    [im_company_select customer_id $customer_id "" "Customer"]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Provider</td>
	  <td class=form-widget colspan=3>
	    [im_company_select provider_id $provider_id "" "Provider"]
	  </td>
	</tr>
	<tr>
	  <td class=form-widget colspan=2 align=center>Left-Dimension</td>
	  <td class=form-widget colspan=2 align=center>Top-Dimension</td>
	</tr>
	<tr>
	  <td class=form-label>Left 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_var1 $left_scale_options $left_var1]
	  </td>

	  <td class=form-label>Date Dimension</td>
	    <td class=form-widget>
	      [im_select -translate_p 0 top_var1 $top_vars_options $top_var1]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_var2 $left_scale_options $left_var2]
	  </td>

	  <td class=form-label>Top 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 top_var2 $left_scale_options $top_var2]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 3</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_var3 $left_scale_options $left_var3]
	  </td>
	  <td class=form-label>Top 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 top_var3 $left_scale_options $top_var3]
	  </td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget colspan=3><input type=submit value=Submit></td>
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
"


# ------------------------------------------------------------
# Get the cube data
#

# set cube_array [im_reporting_cubes_cube \
#     -cube_name "price" \
#     -start_date $start_date \
#     -end_date $end_date \
#     -left_vars $left \
#     -top_vars $top \
#     -cost_type_id $cost_type_id \
#     -customer_type_id $customer_type_id \
#     -customer_id $customer_id \
# ]


    ad_return_complaint 1 $cost_type_id


set cube_array [im_reporting_cubes_price \
    -start_date $start_date \
    -end_date $end_date \
    -left_vars $left \
    -top_vars $top \
    -cost_type_id $cost_type_id \
    -customer_type_id $customer_type_id \
    -customer_id $customer_id \
    -provider_id $provider_id \
    -uom_id $uom_id \
]

if {"" != $cube_array} {
    array set cube $cube_array

    # Extract the variables from cube
    set left_scale $cube(left_scale)
    set top_scale $cube(top_scale)
    array set hash $cube(hash_array)


    # ------------------------------------------------------------
    # Display the Cube Table
    
    ns_write [im_reporting_cubes_display \
	      -hash_array [array get hash] \
	      -left_vars $left \
	      -top_vars $top \
	      -top_scale $top_scale \
	      -left_scale $left_scale \
    ]
}


# ------------------------------------------------------------
# Finish up the table

ns_write "[im_footer]\n"


