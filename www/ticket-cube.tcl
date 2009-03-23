# /packages/intranet-reporting-cubes/www/ticket-cube.tcl
#
# Copyright (c) 2003-2008 ]ticket-open[
#
# All rights reserved. Please check
# http://www.ticket-open.com/ for licensing details.


ad_page_contract {
    Cost Cube
} {
    { start_date "" }
    { end_date "" }
    { top_var1 "year quarter_of_year" }
    { top_var2 "" }
    { top_var3 "" }
    { left_var1 "customer_name" }
    { left_var2 "" }
    { left_var3 "" }
    { ticket_status_id:multiple "" }
    { ticket_type_id "" }
    { customer_type_id:integer "" }
    { customer_id:integer "" }
    { aggregate "one" }

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


# Top Dimension
set top_var1 [ns_urldecode $top_var1]


if {"" != $top_vars} {
    # override top vars with elements from list
    # Special logic for top_var1 for date dimension - very ugly...
    set top_var1 [lindex $top_vars 0]

    if {[lrange $top_vars 0 3] == {year quarter_of_year month_of_year day_of_month}} {
	set top_var1 [lrange $top_vars 0 3]
	set top_vars [lrange $top_vars 3 end]
    }
    if {[lrange $top_vars 0 2] == {year quarter_of_year month_of_year}} {
	set top_var1 [lrange $top_vars 0 2]
	set top_vars [lrange $top_vars 2 end]
    }
    if {[lrange $top_vars 0 1] == {year quarter_of_year}} {
	set top_var1 [lrange $top_vars 0 1]
	set top_vars [lrange $top_vars 1 end]
    }
    if {[lrange $top_vars 0 1] == {year month_of_year}} {
	set top_var1 [lrange $top_vars 0 1]
	set top_vars [lrange $top_vars 1 end]
    }
    if {[lrange $top_vars 0 1] == {year week_of_year}} {
	set top_var1 [lrange $top_vars 0 1]
	set top_vars [lrange $top_vars 1 end]
    }
    if {[lrange $top_vars 0 1] == {quarter_of_year year}} {
	set top_var1 [lrange $top_vars 0 1]
	set top_vars [lrange $top_vars 1 end]
    }
    if {[lrange $top_vars 0 1] == {month_of_year year}} {
	set top_var1 [lrange $top_vars 0 1]
	set top_vars [lrange $top_vars 1 end]
    }

    set top_var2 [lindex $top_vars 1]
    set top_var3 [lindex $top_vars 2]
}


set top {}
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
set menu_label "reporting-cubes-ticket"
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


# ------------------------------------------------------------
# Page Title & Help Text

set page_title [lang::message::lookup "" intranet-reporting.Ticket_Cube "Ticket Cube"]
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>

This Pivot Table ('cube') is a kind of report that shows 
a number of characteristics of helpdesk tickets.
This cube effectively replaces a dozen of specific reports and allows
you to 'drill down' into results.
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
set ticket_url "/intranet/tickets/view?ticket_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/ticket-cube" {start_date end_date} ]


# ------------------------------------------------------------
# Options

set aggregate_options {
	"one"				"Number of Tickets"
	"reaction_time"			"Reaction Time"
	"solution_time"			"Solution Time"
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
	"ticket_name" "Ticket Name"
	"ticket_nr" "Ticket Nr"
	"ticket_type" "Ticket Type"
	"ticket_status" "Ticket Status"

	"ticket_creation_user" "Ticket Creator"
	"ticket_creation_user_dept" "Ticket Creator's Department"

	"customer_name" "Customer Name"
	"customer_type" "Customer Type"
	"customer_status" "Customer Status"
}


# ------------------------------------------------------------
# add all DynField attributes from Tickets with datatype integer and a
# CategoryWidget for display. This widget shows distinct values suitable
# as dimension.

set dynfield_sql "
	select	aa.attribute_name,
		aa.pretty_name,
		w.widget as tcl_widget,
		w.widget_name as dynfield_widget
	from
		im_dynfield_attributes a,
		im_dynfield_widgets w,
		acs_attributes aa
	where
		a.widget_name = w.widget_name
		and a.acs_attribute_id = aa.attribute_id
		and w.widget in ('select', 'generic_sql', 'im_category_tree', 'im_cost_center_tree', 'checkbox')
		and aa.object_type in ('im_ticket','im_company')
		and aa.attribute_name not like 'default%'
" 

set derefs [list]
db_foreach dynfield_attributes $dynfield_sql {

    lappend left_scale_options ${attribute_name}_deref
    lappend left_scale_options $pretty_name

    # How to dereferentiate the attribute_name to attribute_name_deref?
    # The code is going to be executed as part of an SQL

    # Skip adding "deref" stuff if the variable is not looked at...
    if {[lsearch $dimension_vars ${attribute_name}_deref] < 0} { 
	continue 
    }

    # Catch the generic ones - We know how to dereferentiate integer references of these fields.
    set deref ""
    switch $tcl_widget {
	im_category_tree {
	    set deref "im_category_from_id($attribute_name) as ${attribute_name}_deref"
	}
	im_cost_center_tree {
	    set deref "im_cost_center_name_from_id($attribute_name) as ${attribute_name}_deref"
	}
    }

    switch $dynfield_widget {
	gender_select { set deref "im_category_from_id($attribute_name) as ${attribute_name}_deref" }
	employees { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	employees_and_customers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	customers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	bit_member { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	active_tickets { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	cost_centers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	ticket_account_manager { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	pl_fachbereich { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
    }
	
    if {"" == $deref} { set deref "$attribute_name as ${attribute_name}_deref" }
    lappend derefs $deref
}

# ------------------------------------------------------------
# Determine which "dereferenciations" we need (pulling out nice value for integer reference)
foreach var $dimension_vars {
    switch $var {
	year { lappend derefs "to_char(p.start_date, 'YYYY') as year" }
	month_of_year { lappend derefs "to_char(p.start_date, 'MM') as month_of_year" }
	quarter_of_year { lappend derefs "to_char(p.start_date, 'Q') as quarter_of_year" }
	week_of_year { lappend derefs "to_char(p.start_date, 'IW') as week_of_year" }
	day_of_month { lappend derefs "to_char(p.start_date, 'DD') as day_of_month" }

	ticket_type { lappend derefs "im_category_from_id(p.ticket_type_id) as ticket_type" }
	ticket_status { lappend derefs "im_category_from_id(p.ticket_status_id) as ticket_status" }

	ticket_creation_user { lappend derefs "im_name_from_user_id(p.creation_user_id) as ticket_creation_user" }
	ticket_creation_user_dept { lappend derefs "im_dept_from_user_id(p.creation_user_id) as ticket_creation_user_dept" }
    }
}

if {[llength $derefs] == 0} { lappend derefs "1 as dummy"}


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
[export_form_vars ticket_id]
<tr valign=top><td>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-widget colspan=4 align=center>Constraints</td>
	</tr>
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
	  <td class=form-label>Ticket Type</td>
	  <td class=form-widget colspan=3>
	    [im_category_select -include_empty_p 1 "Intranet Ticket Type" ticket_type_id $ticket_type_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Ticket Status</td>
	  <td class=form-widget colspan=3>
	    [im_category_select -include_empty_p 1 "Intranet Ticket Status" ticket_status_id $ticket_status_id]
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
	    [im_company_select -include_empty_name "All" customer_id $customer_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-widget colspan=4 align=center>&nbsp;<br>Aggregate</td>
	</tr>
	<tr>
	  <td class=form-label>Show:</td>
	  <td class=form-widget colspan=3>
	    [im_select -translate_p 1 aggregate $aggregate_options $aggregate]
	</td>
	<tr>
	  <td class=form-widget colspan=2 align=center>&nbsp;<br>Left-Dimension</td>
	  <td class=form-widget colspan=2 align=center>&nbsp;<br>Top-Dimension</td>
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

set cube_array [im_reporting_cubes_cube \
    -cube_name "ticket" \
    -start_date $start_date \
    -end_date $end_date \
    -left_vars $left \
    -top_vars $top \
    -ticket_type_id $ticket_type_id \
    -ticket_status_id $ticket_status_id \
    -customer_type_id $customer_type_id \
    -customer_id $customer_id \
    -aggregate $aggregate \
    -derefs $derefs \
    -no_cache_p 1 \
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


