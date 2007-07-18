# /packages/intranet-reporting/www/finance-yearly-revenues.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Cost Cube
} {
    { start_date "" }
    { end_date "" }
    { top_vars "year month_of_year" }
    { top_scale1 "" }
    { top_scale2 "" }
    { left_scale1 "project_type" }
    { left_scale2 "project_name" }
    { left_scale3 "" }
    { customer_type_id:integer 0 }
    { project_type_id:integer 0 }
    { customer_id:integer 0 }
}


# ------------------------------------------------------------
# Define Dimensions

# Left Dimension - defined by users selects
set left_vars [list]
if {"" != $left_scale1} { lappend left_vars $left_scale1 }
if {"" != $left_scale2} { lappend left_vars $left_scale2 }
if {"" != $left_scale3} { lappend left_vars $left_scale3 }

# Top Dimension
set top_vars [ns_urldecode $top_vars]
if {"" != $top_scale1} { lappend top_vars $top_scale1 }
if {"" != $top_scale2} { lappend top_vars $top_scale2 }

# No top dimension at all gives an error...
if {![llength $top_vars]} { set top_vars [list year] }

# The complete set of dimensions - used as the key for
# the "cell" hash. Subtotals are calculated by dropping on
# or more of these dimensions
set dimension_vars [concat $top_vars $left_vars]

# Check for duplicate variables
set unique_dimension_vars [lsort -unique $dimension_vars]
if {[llength $dimension_vars] != [llength $unique_dimension_vars]} {
    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-reporting.Duplicate_dimension "Duplicate Dimension"]</b>:
	<br>[lang::message::lookup "" intranet-reporting.You_have_specified_a_dimension_multiple "
	You have specified a dimension more then once."
    ]
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
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "
	You don't have the necessary permissions to view this page"]
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

set page_title [lang::message::lookup "" intranet-reporting.Timesheet_Cube "Timesheet Cube"]
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>

This Pivot Table ('cube') is a kind of report that shows timesheet
hours according to a number of 'dimensions' that you can specify.
This cube effectively replaces a dozen of specific reports and allows
you to 'drill down' into results.<p>
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set gray "gray"
set sigma "&Sigma;"
set days_in_past 31

set date_format [im_l10n_sql_date_format]

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} { set start_date "$todays_year-$todays_month-01" }

db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { set end_date "$end_year-$end_month-01" }


# ------------------------------------------------------------
# URLs to different parts of the system

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/timesheet-cube" {start_date end_date} ]


# ------------------------------------------------------------
# Options

set top_vars_options {
	"" "No Date Dimension" 
	"year" "Year" 
	"year quarter_of_year" "Year and Quarter" 
	"year month_of_year" "Year and Month" 
	"year quarter_of_year month_of_year" "Year, Quarter and Month" 
	"year quarter_of_year month_of_year day_of_month" "Year, Quarter, Month and Day" 
	"year week_of_year" "Year and Week"
	"month_of_year year" "Month and Year (compare years)"
}

set left_scale_options {
	"" ""
	"main_project_name" "Main Project Name"
	"main_project_nr" "Main Project Nr"
	"main_project_type" "Main Project Type"
	"main_project_status" "Main Project Status"

	"project_name" "SubProject Name"
	"project_nr" "SubProject Nr"
	"project_type" "SubProject Type"
	"project_status" "SubProject Status"

	"user_name" "User Name"
	"department" "User Department"
	"customer_name" "Customer Name"
	"customer_type" "Customer Type"
	"customer_status" "Customer Status"
	"project_manager_name" "Project Manager"
}


# ------------------------------------------------------------
# add all DynField attributes from Projects with datatype integer and a
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
		and aa.object_type in ('im_project','im_company')
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
	active_projects { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	cost_centers { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	project_account_manager { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
	pl_fachbereich { set deref "acs_object__name($attribute_name) as ${attribute_name}_deref" }
    }
	
    if {"" == $deref} { set deref "$attribute_name as ${attribute_name}_deref" }
    lappend derefs $deref
}

# ------------------------------------------------------------
# Determine which "dereferenciations" we need (pulling out nice value for integer reference)
foreach var $dimension_vars {
    switch $var {
	company_type { lappend derefs "im_category_from_id(h.company_type_id) as company_type" }
	year { lappend derefs "to_char(h.day, 'YYYY') as year" }
	month_of_year { lappend derefs "to_char(h.day, 'MM') as month_of_year" }
	quarter_of_year { lappend derefs "to_char(h.day, 'Q') as quarter_of_year" }
	week_of_year { lappend derefs "to_char(h.day, 'IW') as week_of_year" }
	day_of_month { lappend derefs "to_char(h.day, 'DD') as day_of_month" }

	main_project_type { lappend derefs "im_category_from_id(p.project_type_id) as main_project_type" }
	main_project_status { lappend derefs "im_category_from_id(p.project_status_id) as main_project_status" }

	project_type { lappend derefs "im_category_from_id(h.project_type_id) as project_type" }
	project_status { lappend derefs "im_category_from_id(h.project_status_id) as project_status" }

	customer_type { lappend derefs "im_category_from_id(h.company_type_id) as customer_type" }
	customer_status { lappend derefs "im_category_from_id(h.company_status_id) as customer_status" }

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
	  <td class=form-label>Customer Type</td>
	  <td class=form-widget colspan=3>
	    [im_category_select -include_empty_p 1 "Intranet Company Type" customer_type_id $customer_type_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Customer</td>
	  <td class=form-widget colspan=3>
	    [im_company_select customer_id $customer_id]
	  </td>
	</tr>
	<tr>
	  <td class=form-widget colspan=2 align=center>Left-Dimension</td>
	  <td class=form-widget colspan=2 align=center>Top-Dimension</td>
	</tr>
	<tr>
	  <td class=form-label>Left 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_scale1 $left_scale_options $left_scale1]
	  </td>

	  <td class=form-label>Date Dimension</td>
	    <td class=form-widget>
	      [im_select -translate_p 0 top_vars $top_vars_options $top_vars]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_scale2 $left_scale_options $left_scale2]
	  </td>

	  <td class=form-label>Top 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 top_scale1 $left_scale_options $top_scale1]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 3</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_scale3 $left_scale_options $left_scale3]
	  </td>
	  <td class=form-label>Top 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 top_scale2 $left_scale_options $top_scale2]
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
<table border=0 cellspacing=1 cellpadding=1>
"



# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {"" != $customer_id && 0 != $customer_id} {
    lappend criteria "p.company_id = :customer_id"
}

if {"" != $project_type_id && 0 != $project_type_id} {
    lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
}

if {"" != $customer_type_id && 0 != $customer_type_id} {
    lappend criteria "c.company_type_id in ([join [im_sub_categories $customer_type_id] ","])"
}

set where_clause [join $criteria " and\n\t\t\t"]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

# Inner - Try to be as selective as possible for the relevant data from the fact table.
set inner_sql "
		select	
			h.*, 
			p.*,
			im_name_from_user_id(p.project_lead_id) as project_manager_name,
			c.*,
			c.company_name as customer_name,
			u.*,
			e.*,
			im_cost_center_name_from_id(e.department_id) as department,
			im_name_from_user_id(u.user_id) as user_name,
			tree_ancestor_key(p.tree_sortkey, 1) as main_project_sortkey
		from
			im_hours h,
			im_projects p,
			im_companies c,
			cc_users u
			LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
		where
			h.project_id = p.project_id
			and p.project_status_id not in ([im_project_status_deleted])
			and h.user_id = u.user_id
			and p.company_id = c.company_id
			and h.day::date >= to_date(:start_date, 'YYYY-MM-DD')
			and h.day::date < to_date(:end_date, 'YYYY-MM-DD')
			$where_clause
"


# Aggregate additional/important fields to the fact table.
set middle_sql "
	select
		h.*,
		p.project_name as main_project_name,
		p.project_nr as main_project_nr,
		p.project_type_id as main_project_type_id,
		p.project_status_id as main_project_status_id,
		[join $derefs ",\n\t\t"]
	from	($inner_sql) h,
		im_projects p
	where	h.main_project_sortkey = p.tree_sortkey
"

set outer_sql "
select
	sum(h.hours) as hours,
	[join $dimension_vars ",\n\t"]
from
	($middle_sql) h
group by
	[join $dimension_vars ",\n\t"]
"


# ------------------------------------------------------------
# Create upper date dimension

# Top scale is a list of lists such as {{2006 01} {2006 02} ...}
# The last element of the list the grand total sum.
set top_scale_plain [db_list_of_lists top_scale "
	select distinct	[join $top_vars ", "]
	from		($middle_sql) c
	order by	[join $top_vars ", "]
"]
lappend top_scale_plain [list $sigma $sigma $sigma $sigma $sigma $sigma]


# Insert subtotal columns whenever a scale changes
set top_scale [list]
set last_item [lindex $top_scale_plain 0]
foreach scale_item $top_scale_plain {
    for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {

	set last_var [lindex $last_item $i]
	set cur_var [lindex $scale_item $i]
	if {$last_var != $cur_var} {
	    set item [lrange $last_item 0 $i]
	    while {[llength $item] < [llength $last_item]} { lappend item $sigma }
	    lappend top_scale $item
	}
    }
    lappend top_scale $scale_item
    set last_item $scale_item
}


# ------------------------------------------------------------
# Create a sorted left dimension

# No left dimension at all gives an error...
if {![llength $left_vars]} {
    ns_write "
	<p>&nbsp;<p>&nbsp;<p>&nbsp;<p><blockquote>
	[lang::message::lookup "" intranet-reporting.No_left_dimension "No 'Left' Dimension Specified"]:<p>
	[lang::message::lookup "" intranet-reporting.No_left_dimension_message "
		You need to specify atleast one variable for the left dimension.
	"]
	</blockquote><p>&nbsp;<p>&nbsp;<p>&nbsp;
    "
    ns_write "</table>\n[im_footer]\n"
    return
}

# Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
# The last element is the grand total.
set left_scale_plain [db_list_of_lists left_scale "
	select distinct	[join $left_vars ", "]
	from		($middle_sql) c
	order by	[join $left_vars ", "]
"]
set last_sigma [list]
foreach t [lindex $left_scale_plain 0] {
    lappend last_sigma $sigma
}
lappend left_scale_plain $last_sigma


# Add subtotals whenever a "main" (not the most detailed) scale changes
set left_scale [list]
set last_item [lindex $left_scale_plain 0]
foreach scale_item $left_scale_plain {

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


# ------------------------------------------------------------
# Display the Table Header

# Determine how many date rows (year, month, day, ...) we've got
set first_cell [lindex $top_scale 0]
set top_scale_rows [llength $first_cell]
set left_scale_size [llength [lindex $left_scale 0]]

set header ""
for {set row 0} {$row < $top_scale_rows} { incr row } {

    append header "<tr class=rowtitle>\n"
    append header "<td colspan=$left_scale_size></td>\n"

    for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {

	set scale_entry [lindex $top_scale $col]
	set scale_item [lindex $scale_entry $row]

	# Check if the previous item was of the same content
	set prev_scale_entry [lindex $top_scale [expr $col-1]]
	set prev_scale_item [lindex $prev_scale_entry $row]

	# Check for the "sigma" sign. We want to display the sigma
	# every time (disable the colspan logic)
	if {$scale_item == $sigma} { 
	    append header "\t<td class=rowtitle>$scale_item</td>\n"
	    continue
	}

	# Prev and current are same => just skip.
	# The cell was already covered by the previous entry via "colspan"
	if {$prev_scale_item == $scale_item} { continue }

	# This is the first entry of a new content.
	# Look forward to check if we can issue a "colspan" command
	set colspan 1
	set next_col [expr $col+1]
	while {$scale_item == [lindex [lindex $top_scale $next_col] $row]} {
	    incr next_col
	    incr colspan
	}
	append header "\t<td class=rowtitle colspan=$colspan>$scale_item</td>\n"	    

    }
    append header "</tr>\n"
}
ns_write $header


# ------------------------------------------------------------
# Execute query and aggregate values into a Hash array

db_foreach query $outer_sql {

    # Get all possible permutations (N out of M) from the dimension_vars
    set perms [im_report_take_all_ordered_permutations $dimension_vars]

    # Add the timesheet hours to ALL of the variable permutations.
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
	
	if {"" == $hours} { set hours 0 }
	set sum [expr $sum + $hours]
	set hash($key) $sum
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
    
    foreach top_entry $top_scale {

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
	foreach var_name $dimension_vars {
	    set var_value [eval set a "\$$var_name"]
	    if {$sigma != $var_value} { lappend key_expr_list $var_name }
	}
	set key_expr "\$[join $key_expr_list "-\$"]"
	set key [eval "set a \"$key_expr\""]

	set val "&nbsp;"
	if {[info exists hash($key)]} { set val $hash($key) }

	ns_write "<td>$val</td>\n"

    }
    ns_write "</tr>\n"
}


# ------------------------------------------------------------
# Finish up the table

ns_write "</table>\n[im_footer]\n"


