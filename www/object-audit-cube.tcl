# /packages/intranet-reporting-cubes/www/object-audit-cube.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Object Audit Cube
} {
    { start_date "" }
    { end_date "" }
    { top_vars "year month_of_year" }
    { top_scale1 "" }
    { top_scale2 "" }
    { left_scale1 "object_type" }
    { left_scale2 "" }
    { left_scale3 "" }
    { object_type "" }
    { user_id:integer 0 }
    { object_id:integer 0 }
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

set read_p "t"

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

set page_title [lang::message::lookup "" intranet-reporting.Object_Audi_Cube "Object Audit Cube"]
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>

This Pivot Table ('cube') shows who has created objects
according to a number of 'dimensions' that you can specify.<p>
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
set this_url [export_vars -base "/intranet-reporting-cubes/object-audit-cube" {start_date end_date} ]


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
	"creation_user_name" "Creation User"
	"object_type" "Object Type"
	"biz_object_type" "Business Object Type"
	"biz_object_status" "Business Object Status"
	"object_name" "Object Name"
}

set object_type_options [db_list_of_lists otypes "
	select pretty_name, object_type
	from acs_object_types
	order by pretty_name
"]
set object_type_options [linsert $object_type_options 0 {"" ""}]

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
	  <td class=form-label>Object Type</td>
	  <td class=form-widget colspan=3>
	    [im_select -ad_form_option_list_style_p 1 -translate_p 0 object_type $object_type_options $object_type]
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

if {"" != $object_type} {
    lappend criteria "o.object_type = :object_type"
}

set where_clause [join $criteria " and\n\t\t\t"]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Determine which "dereferenciations" we need (pulling out nice value for integer reference)

set derefs [list]
foreach var $dimension_vars {
    switch $var {
        company_type { lappend derefs "im_category_from_id(o.company_type_id) as company_type" }
        year { lappend derefs "to_char(o.creation_date, 'YYYY') as year" }
        month_of_year { lappend derefs "to_char(o.creation_date, 'MM') as month_of_year" }
        quarter_of_year { lappend derefs "to_char(o.creation_date, 'Q') as quarter_of_year" }
        week_of_year { lappend derefs "to_char(o.creation_date, 'IW') as week_of_year" }
        day_of_month { lappend derefs "to_char(o.creation_date, 'DD') as day_of_month" }

        object_name { lappend derefs "acs_object__name(o.object_id) as object_name" }
	biz_object_type { lappend derefs "im_category_from_id(im_biz_object__get_type_id(o.object_id)) as biz_object_type" }
	biz_object_status { lappend derefs "im_category_from_id(im_biz_object__get_status_id(o.object_id)) as biz_object_status" }
    }
}

if {[llength $derefs] == 0} { lappend derefs "1 as dummy"}

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

# Inner - Try to be as selective as possible for the relevant data from the fact table.
set inner_sql "
		select	
			o.object_id,
			ot.pretty_name as object_type,
			o.creation_user,
			o.creation_date,
			o.creation_ip,
			1 as cnt
		from
			acs_objects o,
			acs_object_types ot
		where
			o.object_type = ot.object_type
			and o.creation_date >= to_date(:start_date, 'YYYY-MM-DD')::timestamptz
			and o.creation_date < to_date(:end_date, 'YYYY-MM-DD')::timestamptz
			$where_clause
"


# Aggregate additional/important fields to the fact table.
set middle_sql "
	select
		o.*,
		im_name_from_user_id(o.creation_user) as creation_user_name,
		[join $derefs ",\n\t\t"]
	from	($inner_sql) o
"

set outer_sql "
select
	sum(o.cnt) as cnt,
	[join $dimension_vars ",\n\t"]
from
	($middle_sql) o
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

    foreach perm $perms {

	# Calculate the key for this permutation
	# something like "$year-$month-$customer_id"
	set key_expr "\$[join $perm "-\$"]"
	set key [eval "set a \"$key_expr\""]

	# Sum up the values for the matrix cells
	set sum 0
	if {[info exists hash($key)]} { set sum $hash($key) }
	
	if {"" == $cnt} { set cnt 0 }
	set sum [expr $sum + $cnt]
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


