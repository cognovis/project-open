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
    { start_date "2008-01-01" }
    { end_date "2009-01-01" }
    { top_vars "year week_of_year day_of_week" }
    { left_vars "user_name_link project_name_link" }
    { project_id:multiple "" }
    { customer_id:integer 0 }
    { zoom "" }
    { max_col 20 }
    { max_row 100 }
}


# ---------------------------------------------------------------
# Display Procedure
# ---------------------------------------------------------------

ad_proc -public im_date_julian_to_components { julian_date } {
    Takes a Julian data and returns an array of its components:
    Year, MonthOfYear, DayOfMonth, WeekOfYear, Quarter
} {
    set ansi [dt_julian_to_ansi $julian_date]
    regexp {(....)-(..)-(..)} $ansi match year month_of_year day_of_month
    set month_of_year [string trim $month_of_year 0]
    set first_year_julian [dt_ansi_to_julian $year 1 1]
    set day_of_year [expr $julian_date - $first_year_julian + 1]
    set week_of_year [expr int($day_of_year / 7)]
    set day_of_week [expr 1 + $day_of_year - 7*$week_of_year]
    set quarter_of_year [expr 1 + int(($month_of_year-1) / 3)]
    
    return [list year $year \
		month_of_year $month_of_year \
		day_of_month $day_of_month \
		week_of_year $week_of_year \
		quarter_of_year $quarter_of_year \
		day_of_year $day_of_year \
		day_of_week $day_of_week \
    ]
}


ad_proc -public im_date_components_to_julian { top_vars top_entry} {
    Takes an entry from top_vars/top_entry and tries
    to figure out the julian date from this
} {
    set ctr 0
    foreach var $top_vars {
	set val [lindex $top_entry $ctr]
	set $var $val
	incr ctr
    }

    # Try to calculate the current data from top dimension
    set julian 0
#    catch { set julian [dt_ansi_to_julian $year $month_of_year $day_of_month] }
    catch { 
	set first_of_year_julian [dt_ansi_to_julian $year 1 1] 
	set julian [expr $first_of_year_julian + $week_of_year * 7 + $day_of_week]
    }
 
    if {0 == $julian} { ad_return_complaint 1 "Unable to calculate data from date dimension: '$top_vars'" }
    return $julian
}

ad_proc -public im_ganttproject_resource_planning {
    { -start_date "" }
    { -end_date "" }
    { -top_vars "year week_or_year day" }
    { -left_vars "user_name_link project_name_link" }
    { -project_id "" }
    { -user_id "" }
    { -customer_id 0 }
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
} {
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    set sigma "&Sigma;"

    set project_base_url "/intranet/projects/view"
    set user_base_url "/intranet/users/view"

    # The list of users/projects opened already
    set user_name_link_opened {}

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
	select	to_char(:start_date::date, 'J') as start_date_julian,
		to_char(:end_date::date, 'J') as end_date_julian
    "

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
    # Projects - determine project & task assignments at the lowest level.
    #

    set projects_sql "
		select
			child.project_id,
			child.project_name,
			child.parent_id,
			parent.project_id as main_project_id,
			r.object_id_two as user_id,
			im_name_from_user_id(r.object_id_two) as user_name,
			m.percentage,
			child.start_date::date as child_start_date,
			to_char(child.start_date, 'J') as child_start_date_julian,
			child.end_date::date as child_end_date,
			to_char(child.end_date, 'J') as child_end_date_julian,
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
    # Calculate the hierarchy.
    # We have to go through all main-projects that have children with
    # assignments, and then we have to go through all of their children
    # in order to get a complete hierarchy.
    #

    set hierarchy_sql "
	select
		child.project_id,
		child.parent_id,
		child.tree_sortkey,
		child.project_name,
		child.project_nr
	from
		im_projects parent,
		im_projects child
	where
		parent.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
		and parent.parent_id is null
		and parent.tree_sortkey in (
			select	tree_ancestor_key(t.tree_sortkey,1) as tree_level
			from	($projects_sql) t
		)
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
    "

    set empty ""
    set name_hash($empty) ""
    db_foreach project_hierarchy $hierarchy_sql {

	# Store project hierarchy information into hashes
	set parent_hash($project_id) $parent_id
	set sortkey_hash($tree_sortkey) $project_id
	set name_hash($project_id) $project_name

    }


    # ------------------------------------------------------------------
    # The left_scale is a list of lists like {{project_name project_path project_name_link user_name_link}}
    # The variables from the left_scale will be used to display the left dimension,
    # depending on the selected left_vars
    #
    set left_scale {}
    db_foreach left_scale $projects_sql {

	# Iterate through the projects level to calculate the "project path".
	# The project path is a list starting with the main-project down to the
	# current project.
	set proj_path [list]
	for {set i [string len $tree_sortkey]} {$i > 0} { set i [expr $i - 8]} {
	    set tsk [string range $tree_sortkey 0 [expr $i-1]]
	    if {[info exists sortkey_hash($tsk)]} {
		set pid $sortkey_hash($tsk)
		lappend proj_path $pid
	    }
	}

	# Calculated variables
	set project_path [f::reverse $proj_path]
	set project_name_link "<a href='[export_vars -base $project_base_url {project_id}]'>$project_name</a>"
	set user_name_link "<a href='[export_vars -base $user_base_url {user_id}]'>$user_name</a>"

	# Select out the variables to go to the left scale
	set left_dim {}
	foreach left_var $left_vars { lappend left_dim [eval set a $$left_var] }
	lappend left_scale $left_dim
    }


    # ------------------------------------------------------------------
    # Calculate the main resource assignment hash by looping
    # through the project hierarchy x looping through the date dimension
    # 
    db_foreach project_loop $projects_sql {
	
	# Loop through the days between start_date and end_data
	for {set i $child_start_date_julian} {$i <= $child_end_date_julian} {incr i} {

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
    
#	ad_return_complaint 1 [array get perc_hash]
#	ad_return_complaint 1 "$start_date_julian $end_date_julian [expr $end_date_julian - $start_date_julian]"
# 	ad_return_complaint 1 "$child_start_date $child_end_date"
    
   

    # ------------------------------------------------------------
    # Create upper date dimension

    # Top scale is a list of lists like {{2006 01} {2006 02} ...}
    set top_scale {}
    for {set i $start_date_julian} {$i <= $end_date_julian} {incr i} {
	array set date_hash [im_date_julian_to_components $i]
	set top_dim {}
	foreach top_var $top_vars {
	    lappend top_dim $date_hash($top_var)
	}
	lappend top_scale $top_dim
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
    # Display the table body
    
    set ctr 0
    foreach left_entry $left_scale {
	
	# ------------------------------------------------------------
	# Check open/close logic of user's projects
	set project_pos [lsearch $left_vars "project_name_link"]
	set project_val [lindex $left_entry $project_pos]
	# A bit ugly - extract the project_id from URL...
	regexp {project%5fid\=([0-9]*)} $project_val match project_id
	
	set user_pos [lsearch $left_vars "user_name_link"]
	set user_val [lindex $left_entry $user_pos]
	# A bit ugly - extract the user_id and project_ids from URL...
	regexp {user%5fid\=([0-9]*)} $user_val match user_id

	# Start checking the open/close logic
#	if {[lsearch $user_name_link_opened $user_id] < 0} { continue }

	# ------------------------------------------------------------
	# Start the row and show the left_scale values at the left
	set class $rowclass([expr $ctr % 2])
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
	    
	    # Write the top_scale values to their corresponding local 
	    # variables so that we can access them easily for $key
	    for {set i 0} {$i < [llength $top_vars]} {incr i} {
		set var_name [lindex $top_vars $i]
		set var_value [lindex $top_entry $i]
		set $var_name $var_value
	    }
	    
	    # Calculate the julian date for today from top_vars
	    set julian_date [im_date_components_to_julian $top_vars $top_entry]

	    # Calculate the key for this permutation
	    # of structure: "$user_id-$project_id-$julian_date"
	    set key "$user_id-$project_id-$julian_date"

	    set val ""
	    if {[info exists perc_hash($key)]} { set val $perc_hash($key) }

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
		"day_of_year" { set val $val_day }
		"day_of_week" { set val $val_day }
		"week_of_year" { set val "$val_week" }
		"month_of_year" { set val "$val_month" }
		"quarter_of_year" { set val "$val_quarter" }
		"year" { set val "$val_year" }
		default { ad_return_complaint 1 "Bad period: $period" }
	    }

	    # ------------------------------------------------------------
	    
	    set color "\#000000"
	    if {![regexp {[^0-9]} $val match]} {
		if {$val > 100} { set color "\#800000" }
		if {$val > 150} { set color "\#FF0000" }
	    }

	    if {0 == $val} { 
		set val "" 
	    } else { 
		set val "<font color=$color>$val</font>\n"
	    }
	    
	    append html "<td>$val</td>\n"
	    
	}
	append html "</tr>\n"
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


# ------------------------------------------------------------
# Contents

set html [im_ganttproject_resource_planning \
	-start_date $start_date \
	-end_date $end_date \
	-top_vars $top_vars \
	-left_vars $left_vars \
	-project_id $project_id \
	-customer_id $customer_id \
	-zoom $zoom \
	-max_col $max_col \
	-max_row $max_row \
]

if {"" == $html} { 
    set html [lang::message::lookup "" intrant-ganttproject.No_resource_assignments_found "No resource assignments found"]
    set html "<p>&nbsp;<p><blockquote><i>$html</i></blockquote><p>&nbsp;<p>\n"
}


ad_return_complaint 1 $html

