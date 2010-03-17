# /packages/intranet-reporting/www/gantt-resources-planning.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Gantt Resource Planning.
    This page is similar to the gantt-resources-cube, but using a different
    approach and showing absences and translation tasks as well

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param level_of_details Details of date axis: 1 (month), 2 (week) or 3 (day)
    @param left_vars Variables to show at the left-hand side
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
    @param user_name_link_opened List of users with details shown
} {
    { start_date "2000-01-01" }
    { end_date "2011-01-01" }
    { top_vars "" }
    { left_vars "user_name_link project_name_link" }
    { project_id:multiple "" }
    { customer_id:integer 0 }
    { zoom "" }
    { max_col 20 }
    { max_row 100 }
    { pre_config "" }
}


# ---------------------------------------------------------------
# Display Procedure
# ---------------------------------------------------------------


ad_proc -public im_ganttproject_resource_planning {
    { -start_date "" }
    { -end_date "" }
    { -top_vars "" }
    { -left_vars "user_name_link project_name_link" }
    { -project_id "" }
    { -user_id "" }
    { -customer_id 0 }
    { -user_name_link_opened "" }
    { -return_url "" }
    { -export_var_list "" }
    { -zoom "" }
    { -auto_open 0 }
    { -max_col 8 }
    { -max_row 20 }
} {
    Gantt Resource "Cube"

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param left_vars Variables to show at the left-hand side
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
    @param user_name_link_opened List of users with details shown
} {
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    set sigma "&Sigma;"

    if {0 != $customer_id && "" == $project_id} {
	set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and company_id = :customer_id
        "]
    }
    
    # ------------------------------------------------------------
    # Start and End-Dat as min/max of selected projects.
    # Note that the sub-projects might "stick out" before and after
    # the main/parent project.
    
    if {"" == $start_date} {
	set start_date [db_string start_date "select to_char(now()::date, 'YYYY-MM-01')"]
    }

    if {"" == $end_date} {
	set end_date [db_string end_date "select to_char(now()::date + 4*7, 'YYYY-MM-01')"]
    }

    db_1row date_calc "
	select	to_char(:start_date, 'J') as start_date_julian,
		to_char(:end_date, 'J') as end_date_julian
    "


    # Adaptive behaviour - limit the size of the component to a summary
    # suitable for the left/right columns of a project.
    if {$auto_open | "" == $top_vars} {
	set duration_days [db_string dur "select to_date(:end_date, 'YYYY-MM-DD') - to_date(:start_date, 'YYYY-MM-DD')"]
	if {"" == $duration_days} { set duration_days 0 }
	if {$duration_days < 0} { set duration_days 0 }

	set duration_weeks [expr $duration_days / 7]
	set duration_months [expr $duration_days / 30]
	set duration_quarters [expr $duration_days / 91]

	set days_too_long [expr $duration_days > $max_col]
	set weeks_too_long [expr $duration_weeks > $max_col]
	set months_too_long [expr $duration_months > $max_col]
	set quarters_too_long [expr $duration_quarters > $max_col]

	set top_vars "week_of_year day_of_month"
	if {$days_too_long} { set top_vars "month_of_year week_of_year" }
	if {$weeks_too_long} { set top_vars "quarter_of_year month_of_year" }
	if {$months_too_long} { set top_vars "year quarter_of_year" }
	if {$quarters_too_long} { set top_vars "year quarter_of_year" }
    }

    set top_vars [im_ganttproject_zoom_top_vars -zoom $zoom -top_vars $top_vars]

    # ------------------------------------------------------------
    # Define Dimensions
    
    # The complete set of dimensions - used as the key for
    # the "cell" hash. Subtotals are calculated by dropping on
    # or more of these dimensions
    set dimension_vars [concat $top_vars $left_vars]


    # ------------------------------------------------------------
    # URLs to different parts of the system

    set company_url "/intranet/companies/view?company_id="
    set project_url "/intranet/projects/view?project_id="
    set user_url "/intranet/users/view?user_id="
    set this_url [export_vars -base "/intranet-ganttproject/gantt-resources-cube" {start_date end_date left_vars customer_id} ]
    foreach pid $project_id { append this_url "&project_id=$pid" }

    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #
    
    set criteria [list]
    if {"" != $customer_id && 0 != $customer_id} { lappend criteria "parent.company_id = :customer_id" }
    if {"" != $project_id && 0 != $project_id} { lappend criteria "parent.project_id in ([join $project_id ", "])" }
    if {"" != $user_id && 0 != $user_id} { lappend criteria "u.user_id in ([join $user_id ","])" }

    set where_clause [join $criteria " and\n\t\t\t"]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }
    

    # ------------------------------------------------------------
    # Projects - work from the sub-sub-sub-sub-tasks up the hierarchy
    #

    set projects_sql "
		select
			child.project_id as child_project_id,
			parent.project_id as main_project_id,
			substring(child.project_name for 20) as object_name,
			substring(child.project_nr for 20) as object_nr,
			r.object_id_two as user_id,
			m.percentage,
			child.start_date::date,
			to_char(child.start_date, 'J') as start_date_julian,
			child.end_date::date,
			to_char(child.end_date, 'J') as end_date_julian,
			tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as object_level,
			child.tree_sortkey
		from
			im_projects parent,
			im_projects child,
			acs_rels r,
			im_biz_object_members m
		where
			parent.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
			and parent.parent_id is null
			and parent.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			and parent.start_date <= to_date(:end_date, 'YYYY-MM-DD')
			and child.tree_sortkey
				between parent.tree_sortkey
				and tree_right(parent.tree_sortkey)
			and r.rel_id = m.rel_id
			and r.object_id_one = child.project_id
			and m.percentage is not null
			$where_clause
    "

    # ------------------------------------------------------------------
    # Store the relevant project hierarchy (for the projects selected)
    # in a hash array.
    set project_hierarchy_sql "
	select	child.project_id,
		child.parent_id
	from
		im_projects parent,
		im_projects child
	where
		parent.parent_id is null and
		parent.project_id in (
			select	main_project_id
			from	($projects_sql) ps
		)
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
    "

    db_foreach project_hierarchy $project_hierarchy_sql {
	set parent_hash($project_id) $parent_id
    }


    # ------------------------------------------------------------------
    # Loop through the project absences and set values for weekly hash cells
    db_foreach project_loop $projects_sql {
	
	# Loop through the days between start_date and end_data
	for {set i $start_date_julian} {$i <= $end_date_julian} {incr i} {

	    # Loop through the project hierarchy towards the top
	    set pid $project_id
	    while {"" != $pid} {
		    set key "$user_id-$project_id-$i"
		    set perc 0
		    if {[info exists perc_hash($key)]} { set perc $perc_hash($key) }
		    set perc [expr $perc + $percentage]
		    set perc_hash($key) $perc

		    # Check if there is a super-project and continue there.
		    set pid $parent_hash($pid)
	    }
	}
    }

    set absences_sql "
		select
			'im_user_absence'::varchar as type,
			100::numeric as percentage,
			a.owner_id as user_id,
			a.absence_id as object_id,
			a.absence_name as object_name,
			a.absence_id::varchar as object_nr,
			a.start_date::date,
			a.end_date::date,
			1 as object_level
		from
			im_user_absences a
		where
			a.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			and a.start_date <= to_date(:end_date, 'YYYY-MM-DD')
			$where_clause
    "

    # ------------------------------------------------------------
    # Create upper date dimension

    # Top scale is a list of lists like {{2006 01} {2006 02} ...}
    set top_scale_plain {}
    for {set i $start_date_julian} {$i <= $end_date_julian} {incr i} {
	append top_scale_plain [list $i]
    }

    # ------------------------------------------------------------
    # Create a sorted left dimension
    
    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale_plain [db_list_of_lists left_scale "
	select distinct	[join $left_vars ", "]
	from		($middle_sql) c
	order by	[join $left_vars ", "]
    "]

    set last_sigma [list]
    foreach t [lindex $left_scale_plain 0] { lappend last_sigma $sigma }
    lappend left_scale_plain $last_sigma


    # Add a "subtotal" (= {$user_id $sigma}) before every new ocurrence of a user_id
    set left_scale [list]
    set last_user_id 0
    foreach scale_item $left_scale_plain {
	set user_id [lindex $scale_item 0]
	if {$last_user_id != $user_id} {
	    lappend left_scale [list $user_id $sigma]
	    set last_user_id $user_id
	}
	lappend left_scale $scale_item
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
	set col_l10n [lang::message::lookup "" "intranet-ganttproject.Dim_[lindex $top_vars $row]" [lindex $top_vars $row]]
	if {0 == $row} {
	    set zoom_in "<a href=[export_vars -base $this_url {top_vars {zoom "in"}}]>[im_gif "magnifier_zoom_in"]</a>\n" 
	    set zoom_out "<a href=[export_vars -base $this_url {top_vars {zoom "out"}}]>[im_gif "magifier_zoom_out"]</a>\n" 
	    set col_l10n "$zoom_in $zoom_out $col_l10n\n" 
	}
	append header "<td class=rowtitle colspan=$left_scale_size align=right>$col_l10n</td>\n"
	
	for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {
	    
	    set scale_entry [lindex $top_scale $col]
	    set scale_item [lindex $scale_entry $row]
	    
	    # Skip the last line with all sigmas - doesn't sum up...
	    set all_sigmas_p 1
	    foreach e $scale_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	    if {$all_sigmas_p} { continue }

	    
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
    append html $header

    # ------------------------------------------------------------
    # Execute query and aggregate values into a Hash array

    set cnt_outer 0
    set cnt_inner 0
    db_foreach query $outer_sql {

	# Skip empty percentage entries. Improves performance...
	if {"" == $percentage} { continue }
	
	# Get all possible permutations (N out of M) from the dimension_vars
	set perms [im_report_take_all_ordered_permutations $dimension_vars]
	
	# Add the gantt hours to ALL of the variable permutations.
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
	    
	    if {"" == $percentage} { set percentage 0 }
	    set sum [expr $sum + $percentage]
	    set hash($key) $sum
	    
	    incr cnt_inner
	}
	incr cnt_outer
    }

    # Skip component if there are not items to be displayed
    if {0 == $cnt_outer} { return "" }

    # ------------------------------------------------------------
    # Display the table body
    
    set ctr 0
    foreach left_entry $left_scale {
	
	# ------------------------------------------------------------
	# Check open/close logic of user's projects
	set project_pos [lsearch $left_vars "project_name_link"]
	set project_val [lindex $left_entry $project_pos]
	
	set user_pos [lsearch $left_vars "user_name_link"]
	set user_val [lindex $left_entry $user_pos]
	# A bit ugly - extract the user_id from user's URL...
	regexp {user_id\=([0-9]*)} $user_val match user_id
	
	if {$sigma != $project_val} {
	    # The current line is not the summary line (which is always shown).
	    # Start checking the open/close logic
	    
	    if {[lsearch $user_name_link_opened $user_id] < 0} { continue }
	}

	# ------------------------------------------------------------
	# Add empty line before the total sum. The total sum of percentage
	# shows the overall resource assignment and doesn't make much sense...
	set user_pos [lsearch $left_vars "user_name_link"]
	set user_val [lindex $left_entry $user_pos]
	if {$sigma == $user_val} {
	    continue
	}
	
	set class $rowclass([expr $ctr % 2])
	incr ctr
	

	# ------------------------------------------------------------
	# Start the row and show the left_scale values at the left
	append html "<tr class=$class>\n"
	set left_entry_ctr 0
	foreach val $left_entry { 
	    
	    # Special logic: Add +/- in front of User name for drill-in
	    if {"user_name_link" == [lindex $left_vars $left_entry_ctr] & $sigma == $project_val} {
		
		if {[lsearch $user_name_link_opened $user_id] < 0} {
		    set opened $user_name_link_opened
		    lappend opened $user_id
		    set open_url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
		    set val "<a href=$open_url>[im_gif "plus_9"]</a> $val"
		} else {
		    set opened $user_name_link_opened
		    set user_id_pos [lsearch $opened $user_id]
		    set opened [lreplace $opened $user_id_pos $user_id_pos]
		    set close_url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
		    set val "<a href=$close_url>[im_gif "minus_9"]</a> $val"
		} 
	    } else {
		
		# Append a spacer for better looks
		set val "[im_gif "cleardot" "" 0 9 9] $val"
	    }
	    
	    append html "<td><nobr>$val</nobr></td>\n" 
	    incr left_entry_ctr
	}


	# ------------------------------------------------------------
	# Write the left_scale values to their corresponding local 
	# variables so that we can access them easily when calculating
	# the "key".
	for {set i 0} {$i < [llength $left_vars]} {incr i} {
	    set var_name [lindex $left_vars $i]
	    set var_value [lindex $left_entry $i]
	    set $var_name $var_value
	}
	
   
	# ------------------------------------------------------------
	# Start writing out the matrix elements
	foreach top_entry $top_scale {
	    
	    # Skip the last line with all sigmas - doesn't sum up...
	    set all_sigmas_p 1
	    foreach e $top_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	    if {$all_sigmas_p} { continue }
	    
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
	    
	    set val ""
	    if {[info exists hash($key)]} { set val $hash($key) }
	    
	    # ------------------------------------------------------------
	    # Format the percentage value for percent-arithmetics:
	    # - Sum up percentage values per day
	    # - When showing percentag per week then sum up and divide by 5 (working days)
	    # ToDo: Include vacation calendar and resource availability in
	    # the future.
	    
	    if {"" == $val} { set val 0 }

	    set period "day_of_month"
	    for {set top_idx 0} {$top_idx < [llength $top_vars]} {incr top_idx} {
		set top_var [lindex $top_vars $top_idx]
		set top_value [lindex $top_entry $top_idx]
		if {$sigma != $top_value} { set period $top_var }
	    }

	    set val_day $val
	    set val_week [expr round($val/5)]
	    set val_month [expr round($val/22)]
	    set val_quarter [expr round($val/66)]
	    set val_year [expr round($val/260)]

	    switch $period {
		"day_of_month" { set val $val_day }
		"week_of_year" { set val "$val_week" }
		"month_of_year" { set val "$val_month" }
		"quarter_of_year" { set val "$val_quarter" }
		"year" { set val "$val_year" }
		default { ad_return_complaint 1 "Bad period: $period" }
	    }

	    # ------------------------------------------------------------
	    
	    if {![regexp {[^0-9]} $val match]} {
		set color "\#000000"
		if {$val > 100} { set color "\#800000" }
		if {$val > 150} { set color "\#FF0000" }
	    }

	    if {0 == $val} { 
		set val "" 
	    } else { 
		set val "<font color=$color>$val%</font>\n"
	    }
	    
	    append html "<td>$val</td>\n"
	    
	}
	append html "</tr>\n"
    }


    # ------------------------------------------------------------
    # Show a line to open up an entire level

    # Check whether all user_ids are included in $user_name_link_opened
    set user_ids [lsort -unique [db_list user_ids "select distinct user_id from ($inner_sql) h order by user_id"]]
    set intersect [lsort -unique [set_intersection $user_name_link_opened $user_ids]]

    if {$user_ids == $intersect} {

	# All user_ids already opened - show "-" sign
	append html "<tr class=rowtitle>\n"
	set opened [list]
	set url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
	append html "<td class=rowtitle><a href=$url>[im_gif "minus_9"]</a></td>\n"
	append html "<td class=rowtitle colspan=[expr [llength $top_scale]+3]>&nbsp;</td></tr>\n"

    } else {

	# Not all user_ids are opened - show a "+" sign
	append html "<tr class=rowtitle>\n"
	set opened [lsort -unique [concat $user_name_link_opened $user_ids]]
	set url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
	append html "<td class=rowtitle><a href=$url>[im_gif "plus_9"]</a></td>\n"
	append html "<td class=rowtitle colspan=[expr [llength $top_scale]+3]>&nbsp;</td></tr>\n"

    }

    # ------------------------------------------------------------
    # Close the table

    set html "<table>\n$html\n</table>\n"

    return $html
}




# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "view_projects_all"]} {
    ad_return_complaint 1 "You don't have permissions to see this page"
    ad_script_abort
}

# ------------------------------------------------------------
# Defaults

set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources "Gantt Resources"]


switch $pre_config {
    resource_planning_report {
	# Configure the parameters to show the current month only
	set start_date [db_string start_date "select to_char(now()::date, 'YYYY-MM-DD')"]
	set end_date [db_string start_date "select to_char(now()::date+14, 'YYYY-MM-DD')"]
	set max_col 30
    }
}


# ------------------------------------------------------------
# Contents

set html [im_ganttproject_resource_planning \
	-start_date $start_date \
	-end_date $end_date \
	-top_vars $top_vars \
	-left_vars $left_vars \
	-project_id $project_id \
	-customer_id $customer_id \
	-user_name_link_opened ""  \
	-zoom $zoom \
	-max_col $max_col \
	-max_row $max_row \
]

if {"" == $html} { 
    set html [lang::message::lookup "" intrant-ganttproject.No_resource_assignments_found "No resource assignments found"]
    set html "<p>&nbsp;<p><blockquote><i>$html</i></blockquote><p>&nbsp;<p>\n"
}


