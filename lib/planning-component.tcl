# -------------------------------------------------------------
# /packages/intranet-planning/lib/planning-component.tcl
#
# Copyright (c) 2011 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables from intranet-planning-procs:
#	object_id:integer
#	planning_type_id
#	planning_time_dim_id 73202
#	planning_dim1 ""
#	planning_dim2 ""
#	planning_dim3 ""
#	restrict_to_main_project_p 1

# Set default values from parameters
if {![info exists planning_type_id] || "" == $planning_type_id} { 
    set planning_type_id [parameter::get_from_package_key -package_key intranet-planning -parameter "PlanningType" -default 73102] 
}
if {![info exists top_vars] || "" == $top_vars} { 
    set top_vars [parameter::get_from_package_key -package_key intranet-planning -parameter "TopDimension" -default "73202"] 
}
if {![info exists left_vars] || "" == $left_vars} { 
    set left_vars [parameter::get_from_package_key -package_key intranet-planning -parameter "LeftDimension" -default "project_phase"] 
}
if {![info exists planning_dimension_date] || "" == $planning_dimension_date} { 
    set planning_dimension_date [parameter::get_from_package_key -package_key intranet-planning -parameter "DimensionTime" -default "month"] 
}
if {![info exists planning_dimension_cost_type] || "" == $planning_dimension_cost_type} { 
    set planning_dimension_cost_type [parameter::get_from_package_key -package_key intranet-planning -parameter "DimensionCostType" -default "3704 3736 3722"] 
}

set top_vars "item_cost_type_id"
set left_vars "item_project_member_id"

set sigma ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# -------------------------------------------------------------
# Other Parameters
#
set user_id [ad_maybe_redirect_for_registration]
set new_item_url [export_vars -base "/intranet-planning/new" {object_id return_url}]
if {![info exists return_url] || "" == $return_url} { 
    set return_url [im_url_with_query] 
}

# Size of the input field
set input_field_size [parameter::get_from_package_key -package_key intranet-planning -parameter "PlanningValueInputFieldSize" -default 6] 

# Rounding precision of the displayed values
# The database by default contains a numeric(12,2) field,
# so there are max. 2 digits stored in the DB. You can 
# change this in the DB if you need more precision.
set rounding_digits [parameter::get_from_package_key -package_key intranet-planning -parameter "PlanningValueRoundingDigits" -default 0] 


# -------------------------------------------------------------
# Check the permissions
# Permissions for all usual projects, companies etc.
if {![info exists object_id]} { ad_return_complaint 1 "planning-component: object_id not defined" }
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd
# object_read is evaluated by .adp which will return nothing if not set.


# -------------------------------------------------------------
# Get the start date of the project or now() as a default.
db_1row start_date "
	select	to_char(now()::date, 'YYYY-MM-DD') as start_date,
		to_char(now()::date, 'YYYY') as start_year,
		to_char(now()::date, 'MM') as start_month,
		to_char(now()::date, 'DD') as start_day,
		to_char(now()::date, 'YYYY-MM-DD') as end_date,
		to_char(now()::date, 'YYYY') as end_year,
		to_char(now()::date, 'MM') as end_month,
		to_char(now()::date, 'DD') as end_day
"
db_0or1row start_date "
	select	to_char(start_date, 'YYYY-MM-DD') as start_date,
		to_char(start_date, 'YYYY') as start_year,
		to_char(start_date, 'MM') as start_month,
		to_char(start_date, 'DD') as start_day,
		to_char(end_date, 'YYYY-MM-DD') as end_date,
		to_char(end_date, 'YYYY') as end_year,
		to_char(end_date, 'MM') as end_month,
		to_char(end_date, 'DD') as end_day
	from	im_projects
	where	project_id = :object_id
"


# -------------------------------------------------------------
# Time Dimension: Calculate value range
# 
set dimension_date_list [list]
switch $planning_dimension_date {
    year { set date_format "YYYY" }
    quarter { set date_format "YYYY-Q" }
    month { set date_format "YYYY-MM" }

    quarter { set date_format "" }
    week { set date_format "" }
    week { set date_format "" }
    week { set date_format "" }
}

set dimension_date_list [db_list_of_lists time_dimension "
		select distinct
			to_char(im_day_enumerator, :date_format),
			to_char(im_day_enumerator, :date_format)
		from	im_day_enumerator(:start_date, :end_date)
"]


# -------------------------------------------------------------
# Project Phase Dimension: Calculate value range
#
set dimension_project_phase_list [db_list_of_lists dim_project_phase "
	select	p.project_id,
		p.project_name
	from	im_projects p
	where	p.parent_id = :object_id and
		p.project_status_id not in (select * from im_sub_categories([im_project_status_deleted]))
"]


# -------------------------------------------------------------
# Member Dimension: Calculate value range
#
set dimension_member_list [db_list_of_lists dim_members "
	select	p.party_id,
		'<a href=/intranet/users/view?user_id=' || p.party_id || '>' || acs_object__name(p.party_id) || '</a>'
	from	acs_rels r,
		parties p
	where	r.object_id_two = p.party_id and
		r.object_id_one = :object_id
"]


# -------------------------------------------------------------
# Cost Type Dimension
#
set dimension_cost_type_list [list]
foreach c_id $planning_dimension_cost_type {
    lappend dimension_cost_type_list [list $c_id [im_category_from_id $c_id]]
}


# ----------------------------------------------------
# Calculate the dimension header and body
# ----------------------------------------------------

# The complete set of dimensions - used as the key for
# the "cell" hash. Subtotals are calculated by dropping on
# or more of these dimensions
set dimension_vars [concat $top_vars $left_vars]
set unique_dimension_vars [lsort -unique $dimension_vars]
set err_mess "<b>"
append err_mess [lang::message::lookup "" intranet-reporting.Duplicate_dimension "Duplicate Dimension"] "</b>:" "<br>"
append err_mess [lang::message::lookup "" intranet-reporting.You_have_specified_a_dimension_multiple "You have specified a dimension more then once"]
if {[llength $dimension_vars] != [llength $unique_dimension_vars]} {
    ad_return_complaint 1 $err_mess
}



# ----------------------------------------------------
# Inner SQL
# Try to be as selective as possible for the relevant data from the fact table.
#
set inner_sql "
		select	
			pi.*
		from
			im_planning_items pi
		where
			pi.item_object_id = :object_id
"

# Aggregate additional/important fields to the fact table.
set middle_sql "
	select
		pi.*,
		acs_object__name(pi.item_project_member_id) as item_project_member,
		im_category_from_id(pi.item_cost_type_id) as item_cost_type,
		to_char(pi.item_date, 'YYYY-MM-DD') as item_date_pretty,
		acs_object__name(pi.item_project_phase_id) as item_project_phase
	from	($inner_sql) pi
	where	1=1
"


# ------------------------------------------------------------
# Execute the query to fill the "hash"
#
set sql "
	select	round(item_value, :rounding_digits) as item_value,
		[join $dimension_vars ",\n\t\t"]
	from	($middle_sql) m
"
db_foreach planning_items $sql {
    # Calculate the key for this permutation
    # something like "$year-$month-$customer_id"
    set key_expr "\$[join $dimension_vars "-\$"]"
    set key [eval "set a \"$key_expr\""]
    set hash($key) $item_value
}


# ad_return_complaint 1 "<pre>dimension_member_list=$dimension_member_list</pre>"


# ------------------------------------------------------------
# Create scales
#
set top_scale [list]
set left_scale [list]

switch $top_vars {
    item_cost_type_id		{ foreach e $dimension_cost_type_list { lappend top_scale [list $e] } }
    item_projec_member_id	{ foreach e $dimension_member_list { lappend top_scale [list $e] } }
    default 			{ ad_return_complaint 1 "planning-component: top_vars=$top_vars not implemented yet" }
}

switch $left_vars {
    item_cost_type_id 		{ foreach e $dimension_cost_type_list { lappend left_scale [list $e] } }
    item_project_member_id	{ foreach e $dimension_member_list { lappend left_scale [list $e] } }
    default			{ ad_return_complaint 1 "planning-component: left_vars=$left_vars not implemented yet" }
}

# ad_return_complaint 1 "<pre>top_vars=$top_vars\nleft_vars=$left_vars\nleft='$left_scale'\ntop='$top_scale'\n</pre>"


# ------------------------------------------------------------
# Display the Table Header

# Determine how many date rows (year, month, day, ...) we've got
set first_cell [lindex $top_scale 0]
set top_scale_rows [llength $first_cell]
set left_scale_size [llength [lindex $left_scale 0]]

set header ""
for {set row 0} {$row < $top_scale_rows} { incr row } {

    append header "<tr class=rowtitle>\n"
    append header "<td class=rowtitle colspan=$left_scale_size>&nbsp;</td>\n"

    for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {

	set scale_entry [lindex $top_scale $col]
	set scale_item [lindex $scale_entry $row]
	set scale_item_key [lindex $scale_item 0]
	set scale_item_pretty [lindex $scale_item 1]
	# ad_return_complaint 1 "$scale_entry - $scale_item - $scale_item_key - $scale_item_pretty"

	# Check if the previous item was of the same content
	set prev_scale_entry [lindex $top_scale [expr $col-1]]
	set prev_scale_item_key [lindex $prev_scale_entry $row]

	# Check for the "sigma" sign. We want to display the sigma
	# every time (disable the colspan logic)
	if {$scale_item_key == $sigma} { 
	    append header "\t<td class=rowtitle>$scale_item_key</td>\n"
	    continue
	}

	# Prev and current are same => just skip.
	# The cell was already covered by the previous entry via "colspan"
	if {$prev_scale_item_key == $scale_item_key} { continue }

	# This is the first entry of a new content.
	# Look forward to check if we can issue a "colspan" command
	set colspan 1
	set next_col [expr $col+1]
	while {$scale_item_key == [lindex [lindex $top_scale $next_col] $row]} {
	    incr next_col
	    incr colspan
	}
	append header "\t<td class=rowtitle colspan=$colspan>$scale_item_pretty</td>\n"	    
    }
    append header "</tr>\n"
}

# ------------------------------------------------------------
# Display the Table Body

set body ""
set row_cnt 0
set cell_cnt 0
foreach left_scale_item $left_scale {

    # Start the row
    set row "<tr $bgcolor([expr $row_cnt % 2])>\n"

    # Show the pretty values from the left scale
    set left_scale_cnt 0
    foreach left_scale_entry $left_scale_item {
	set left_var [lindex $left_vars $left_scale_cnt]
	set left_scale_key [lindex $left_scale_entry 0]
	set left_scale_pretty [lindex $left_scale_entry 1]

	# Append pretty values to the row
	append row "<td>$left_scale_pretty</td>\n"

	# Write the ID value to a local variable
	set $left_var $left_scale_key

	incr left_scale_cnt
    }

    set top_scale_cnt 0
    foreach top_scale_item $top_scale {

	# Write the top_scale value to a local variable
	# names according to top_var
	set top_scale_cnt 0
	foreach top_scale_entry $top_scale_item {
	    set top_var [lindex $top_vars $top_scale_cnt]
	    set top_scale_item [lindex $top_scale_entry $top_scale_cnt]
	    set top_scale_key [lindex $top_scale_item 0]
	    
	    # Write the value to a local variable
	    set $top_var $top_scale_key
	    incr top_scale_cnt
	}

	# -----------------------------------------------------------
	# Calculate the key for this permutation
	# something like "$year-$month-$customer_id"
	set key_expr "\$[join $dimension_vars "-\$"]"
	set key [eval "set a \"$key_expr\""]
	
	# -----------------------------------------------------------
	# Extract the value for this planning cell
	set sum ""
	if {[info exists hash($key)]} { set sum $hash($key) }

	append row "\t<td align=right>\n"
	append row "<input type=text name=item_value.$cell_cnt value=\"$sum\" size=$input_field_size>\n"
	append row "<input type=hidden name=item_project_phase_id.$cell_cnt value=[im_opt_val item_project_phase_id]>\n"
	append row "<input type=hidden name=item_project_member_id.$cell_cnt value=[im_opt_val item_project_member_id]>\n"
	append row "<input type=hidden name=item_cost_type_id.$cell_cnt value=[im_opt_val item_cost_type_id]>\n"
	append row "<input type=hidden name=item_date.$cell_cnt value=\"[im_opt_val item_date]\">\n"
        append row "</td>\n"
	incr cell_cnt

    }
    append row "</tr>\n"
    append body $row
    incr row_cnt
}

