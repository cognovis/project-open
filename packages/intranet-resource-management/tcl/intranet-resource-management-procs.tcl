# /packages/intranet-resource-management/tcl/intranet-resource-management.tcl
#
# Copyright (C) 2010-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Report on and modify resource assignments to tasks of various types.
    @author frank.bergmann@project-open.com
}



# ---------------------------------------------------------------
# Display Procedure for Resource Planning
# ---------------------------------------------------------------

ad_proc -public im_resource_mgmt_resource_planning_cell {
    mode 
    percentage
    color_code
    title 
    appendix
} {
    Takes a percentage value and returns a formatted HTML ready to be
    displayed as part of a cell. 
    - Mode "default" returns a blue bar when 'percentage' < 100,
      a red bar when 'percentage' > 100.  
    - Mode "custom" creates a gif using custom color code    
} {
    if {![string is double $percentage]} { return $percentage }
    if {0.0 == $percentage || "" == $percentage} { return "" }

    # Calculate the percentage / 10, so that height=10 with 100%
    # Always draw a line, even if percentage is < 5% 
    # (which would result in 0 height of the GIF...)
    set p 0
    catch {
        set p [expr round((1.0 * $percentage) / 10.0)]
    }
    set p [expr round((1.0 * $percentage) / 10.0)]
    if {0 == $p && $percentage > 0.0} { set p 1 }

    if { "default" == $mode} {
	    # Color selection
	    set color ""
	    if {$percentage > 0} { set color "bluedot" }
	    if {$percentage > 100} { set color "FF0000" }
	    set color "bluedot"    
	    set result [im_gif $color "$percentage" 0 15 $p]
    } else {
	set percentage [expr $percentage/5]
	set result "<img src='/intranet/images/cleardot.gif' title='$title $appendix' alt='$title $appendix' border='0' height='$percentage' width='15' style='background-color:$color_code'>"
    }
    return $result
}


# ---------------------------------------------------------------
# Auxillary procedures for Resource Report
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
    set quarter_of_year [expr 1 + int(($month_of_year-1) / 3)]

    set week_of_year [util_memoize [list db_string dow "select to_char(to_date($julian_date, 'J'),'IW')"]]
    set day_of_week [util_memoize [list db_string dow "select extract(dow from to_date($julian_date, 'J'))"]]
    if {0 == $day_of_week} { set day_of_week 7 }
   
    return [list year $year \
		month_of_year $month_of_year \
		day_of_month $day_of_month \
		week_of_year $week_of_year \
		quarter_of_year $quarter_of_year \
		day_of_year $day_of_year \
		day_of_week $day_of_week \
    ]
}


ad_proc -public im_date_julian_to_week_julian { julian_date } {
    Takes a Julian data and returns the julian date of the week's day "1" (=Monday)
} {
    array set week_info [im_date_julian_to_components $julian_date]
    set result [expr $julian_date - $week_info(day_of_week)]
}



ad_proc -public im_date_components_to_julian { top_vars top_entry} {
    Takes an entry from top_vars/top_entry and tries
    to figure out the julian date from this
} {
    set ctr 0
    foreach var $top_vars {
	set val [lindex $top_entry $ctr]
	# Remove trailing "0" in week_of_year
	set val [string trimleft $val "0"]
	if {"" == $val} { set val 0 }
	set $var $val
	incr ctr
    }

    set julian 0

    # Try to calculate the current data from top dimension
    switch $top_vars {
	"year week_of_year day_of_week" {
	    catch {
		set first_of_year_julian [dt_ansi_to_julian $year 1 1]
		set dow_first_of_year_julian [util_memoize [list db_string dow "select to_char('$year-01-07'::date, 'D')"]]
		set start_first_week_julian [expr $first_of_year_julian - $dow_first_of_year_julian]
		set julian [expr $start_first_week_julian + 7 * $week_of_year + $day_of_week]
	    }
	}
	"year week_of_year" {
	    catch {
		set first_of_year_julian [dt_ansi_to_julian $year 1 1]
		set dow_first_of_year_julian [util_memoize [list db_string dow "select to_char('$year-01-07'::date, 'D')"]]
		set start_first_week_julian [expr $first_of_year_julian - $dow_first_of_year_julian]
		set julian [expr $start_first_week_julian + 7 * $week_of_year]
	    }
	}
	"year month_of_year day_of_month" {
	    catch {
		if {1 == [string length $month_of_year]} { set month_of_year "0$month_of_year" }
		if {1 == [string length $day_of_month]} { set day_of_month "0$day_of_month" }
		set julian [db_string jul "select to_char('$year-$month_of_year-$day_of_month'::date,'J')"]
	    }
	}
	"year month_of_year" {
	    catch {
		if {1 == [string length $month_of_year]} { set month_of_year "0$month_of_year" }
		set julian [db_string jul "select to_char('$year-$month_of_year-01'::date,'J')"]
	    }
	}
    }

    if {0 == $julian} { 
	ad_return_complaint 1 "<b>Unable to calculate data from date dimension</b>:<br><pre>$top_vars<br>$top_entry" 
	ad_script_abort
    }

    ns_log Notice "im_date_components_to_julian: $julian, top_vars=$top_vars, top_entry=$top_entry"
    return $julian
}


# ---------------------------------------------------------------
# Resource Planning Report
# ---------------------------------------------------------------

ad_proc -public im_resource_mgmt_resource_planning {
    {-debug:boolean}
    {-start_date ""}
    {-end_date ""}
    {-show_all_employees_p ""}
    {-top_vars "year week_of_year day"}
    {-left_vars "cell"}
    {-project_id ""}
    {-project_status_id ""}
    {-project_type_id ""}
    {-employee_cost_center_id "" }
    {-user_id ""}
    {-customer_id 0}
    {-return_url ""}
    {-export_var_list ""}
    {-zoom ""}
    {-auto_open 0}
    {-max_col 8}
    {-max_row 20}
    {-calculation_mode "percentage" }
} {
    Gantt Resource "Cube"

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
} {

    set out ""
    set hours_per_day [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "TimesheetHoursPerDay" -default 8.0]
    set hours_per_absence [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "TimesheetHoursPerAbsence" -default 8.0]

    set html ""
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    set sigma "&Sigma;"
    set page_url "/intranet-resource-management/gantt-resources-planning"
    set current_user_id [ad_get_user_id]
    set return_url [im_url_with_query]

    set clicks([clock clicks -milliseconds]) null

    set project_base_url "/intranet/projects/view"
    set user_base_url "/intranet/users/view"
    set trans_task_base_url "/intranet-translation/trans-tasks/new"

    # The list of users/projects opened already
    set user_name_link_opened {}

    # Determine what aggregates to calculate
    set calc_day_p 0
    set calc_week_p 0
    set calc_month_p 0
    set calc_quarter_p 0
    switch $top_vars {
        "year week_of_year day_of_week" { set calc_day_p 1 }
        "year month_of_year day_of_month" { set calc_day_p 1 }
        "year week_of_year" { set calc_week_p 1 }
        "year month_of_year" { set calc_month_p 1 }
        "year quarter_of_year" { set calc_quarter_p 1 }
    }


    if {0 != $customer_id && "" == $project_id} {
	set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and company_id = :customer_id
        "]
    }

    db_1row date_calc "
	select	to_char(:start_date::date, 'J') as start_date_julian,
		to_char(:end_date::date, 'J') as end_date_julian
    "

    # ------------------------------------------------------------
    # URLs to different parts of the system

    set collapse_url "/intranet/biz-object-tree-open-close"
    set company_url "/intranet/companies/view?company_id="
    set project_url "/intranet/projects/view?project_id="
    set user_url "/intranet/users/view?user_id="
    set this_url [export_vars -base $page_url {start_date end_date customer_id} ]
    foreach pid $project_id { append this_url "&project_id=$pid" }

    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #
    
    set criteria [list]
    if {"" != $customer_id && 0 != $customer_id} { lappend criteria "parent.company_id = :customer_id" }
    if {"" != $project_id && 0 != $project_id} { lappend criteria "parent.project_id in ([join $project_id ", "])" }
    if {"" != $project_status_id && 0 != $project_status_id} { 
	lappend criteria "parent.project_status_id in ([join [im_sub_categories $project_status_id] ", "])" 
    }
    if {"" != $project_type_id && 0 != $project_type_id} { 
	lappend criteria "parent.project_type_id in ([join [im_sub_categories $project_type_id] ", "])" 
    }
    if {"" != $user_id && 0 != $user_id} { lappend criteria "u.user_id in ([join $user_id ","])" }
    if {"" != $employee_cost_center_id && 0 != $employee_cost_center_id} { 
	lappend criteria "u.user_id in (
		select	employee_id
		from	im_employees
		where	department_id = :employee_cost_center_id
	)"
    }


    set where_clause [join $criteria " and\n\t\t\t"]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    # ------------------------------------------------------------
    # Pre-calculate GIFs for performance reasons
    #
    set object_type_gif_sql "
	select	object_type,
		object_type_gif
	from	acs_object_types
	where	object_type in ('user', 'person', 'im_project', 'im_trans_task', 'im_timesheet_task')
    "
    db_foreach gif $object_type_gif_sql {
	set gif_hash($object_type) [im_gif $object_type_gif]
    }
    foreach gif {minus_9 plus_9 magnifier_zoom_in magnifier_zoom_out} {
	set gif_hash($gif) [im_gif $gif]
    }

    # ------------------------------------------------------------
    # Collapse lines in the report - store results in a Hash
    #
    set collapse_sql "
		select	object_id,
			open_p
		from	im_biz_object_tree_status
		where	user_id = :current_user_id and
			page_url = :page_url
    "
    db_foreach collapse $collapse_sql {
	set collapse_hash($object_id) $open_p
    }


    set clicks([clock clicks -milliseconds]) init

    # ------------------------------------------------------------
    # Store information about each day into hashes for speed
    #
    for {set i $start_date_julian} {$i <= $end_date_julian} {incr i} {
	array unset date_comps
	array set date_comps [im_date_julian_to_components $i]

	# Day of Week
	set dow $date_comps(day_of_week)
	set day_of_week_hash($i) $dow

	# Weekend
	if {0 == $dow || 6 == $dow || 7 == $dow} { set weekend_hash($i) 5 }

	# Start of Week Julian
	set start_of_week_julian_hash($i) [expr $i - $dow]
    }

    set clicks([clock clicks -milliseconds]) weekends


    # ------------------------------------------------------------
    # Absences - Determine when the user is away
    #
    set absences_sql "
	-- Direct absences for a user within the period
	select
		owner_id,
		to_char(start_date,'J') as absence_start_date_julian,
		to_char(end_date,'J') as absence_end_date_julian,
		absence_type_id
	from 
		im_user_absences
	where 
		group_id is null and
		start_date <= to_date(:end_date, 'YYYY-MM-DD') and
		end_date   >= to_date(:start_date, 'YYYY-MM-DD')
    UNION
	-- Absences via groups - Check if the user is a member of group_id
	select
		mm.member_id as owner_id,
		to_char(start_date,'J') as absence_start_date_julian,
		to_char(end_date,'J') as absence_end_date_julian,
		absence_type_id
	from 
		im_user_absences a,
		group_distinct_member_map mm
	where 
		a.group_id = mm.group_id and
		start_date <= to_date(:end_date, 'YYYY-MM-DD') and
		end_date   >= to_date(:start_date, 'YYYY-MM-DD')
    "

    db_foreach absences $absences_sql {
	for {set i $absence_start_date_julian} {$i <= $absence_end_date_julian} {incr i} {

	    # Aggregate per day
	    if {$calc_day_p} {
		set key "$i-$owner_id"
		set val ""
		if {[info exists absences_hash($key)]} { set val $absences_hash($key) }
		append val [expr $absence_type_id - 5000]
		set absences_hash($key) $val
	    }

	    # Aggregate per week, skip weekends
	    if {$calc_week_p && ![info exists weekend_hash($i)]} {
		set week_julian [util_memoize [list im_date_julian_to_week_julian $i]]
		set key "$week_julian-$owner_id"
		set val ""
		if {[info exists absences_hash($key)]} { set val $absences_hash($key) }
		append val [expr $absence_type_id - 5000]
		set absences_hash($key) $val
	    }

	}
    }

    set clicks([clock clicks -milliseconds]) absences

    # ------------------------------------------------------------
    # Projects - determine project & task assignments at the lowest level.
    #
    set percentage_sql "
		select
			child.project_id,
			parent.project_id as main_project_id,
			u.user_id,
			trunc(m.percentage) as percentage,
			to_char(child.start_date, 'J') as child_start_date_julian,
			to_char(child.end_date, 'J') as child_end_date_julian
		from
			im_projects parent,
			im_projects child,
			acs_rels r,
			im_biz_object_members m,
			users u
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
			and r.object_id_two = u.user_id
			and m.percentage is not null
			$where_clause
    "

    # ------------------------------------------------------------
    # Main Projects x Users:
    # Return all main projects where a user is assigned in one of the sub-projects
    #

    set show_all_employees_sql ""
    if {1 == $show_all_employees_p} {
	set show_all_employees_sql "
	UNION
		select
			0::integer as main_project_id,
			0::text as main_project_name,
			p.person_id as user_id,
			im_name_from_user_id(p.person_id) as user_name
		from
			persons p,
			group_distinct_member_map gdmm
		where
			gdmm.member_id = p.person_id and
			gdmm.group_id = [im_employee_group_id]
	"
    }

    set show_users_sql ""
    if {"" != $user_id && 0 != $user_id} {
	set show_users_sql "
	UNION
		select
			0::integer as main_project_id,
			0::text as main_project_name,
			p.person_id as user_id,
			im_name_from_user_id(p.person_id) as user_name
		from
			persons p
		where
			p.person_id in ([join $user_id ","])
	"
    }

    set main_projects_sql "
	select distinct
		main_project_id,
		main_project_name,
		user_id,
		user_name
	from
		(select
			parent.project_id as main_project_id,
			parent.project_name as main_project_name,
			u.user_id,
			im_name_from_user_id(r.object_id_two) as user_name
		from
			im_projects parent,
			im_projects child,
			acs_rels r,
			im_biz_object_members m,
			users u
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
			and r.object_id_two = u.user_id
			and m.percentage is not null
			$where_clause
		$show_users_sql
		$show_all_employees_sql
		) t
	order by
		user_name,
		main_project_id
    "
    db_foreach main_projects $main_projects_sql {
	set key "$user_id-$main_project_id"
	set member_of_main_project_hash($key) 1
	set object_name_hash($user_id) $user_name
	set object_name_hash($main_project_id) $main_project_name
	set has_children_hash($user_id) 1
	set indent_hash($main_project_id) 1
	set object_type_hash($main_project_id) "im_project"
	set object_type_hash($user_id) "person"
    }

    set clicks([clock clicks -milliseconds]) main_projects


    # ------------------------------------------------------------------
    # Check for translation tasks below a sub-project
    #
    set trans_task_sql "
		select
			t.*,
			t.project_id as trans_task_project_id,
			to_char(child.start_date, 'J') as trans_task_start_date_julian,
			to_char(t.end_date, 'J') as trans_task_end_date_julian,
			im_category_from_id(t.source_language_id) as source_language,
			im_category_from_id(t.target_language_id) as target_language
		from
			im_projects parent,
			im_projects child,
			im_trans_tasks t
		where
			parent.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
			and parent.parent_id is null
			and parent.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			and parent.start_date <= to_date(:end_date, 'YYYY-MM-DD')
			and child.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			and child.start_date <= to_date(:end_date, 'YYYY-MM-DD')
			and child.tree_sortkey
				between parent.tree_sortkey
				and tree_right(parent.tree_sortkey)
			and t.project_id = child.project_id
			and (t.end_date is null OR t.end_date >= to_date(:start_date, 'YYYY-MM-DD'))
		order by
			t.project_id,
			t.task_name,
			t.source_language_id,
			t.target_language_id
    "

    db_foreach trans_tasks $trans_task_sql {

	# collect trans_task per child.project_id
	set task_name_pretty "$task_name ($source_language -> $target_language)"
	set tasks {}
	if {[info exists trans_tasks_per_project_hash($trans_task_project_id)]} { set tasks $trans_tasks_per_project_hash($trans_task_project_id) }
	lappend tasks [list $task_id $task_name_pretty]
	set trans_tasks_per_project_hash($trans_task_project_id) $tasks
	set parent_hash($task_id) $trans_task_project_id

    }

    set clicks([clock clicks -milliseconds]) trans_tasks



    # ------------------------------------------------------------------
    # Calculate the hierarchy.
    # We have to go through all main-projects that have children with
    # assignments, and then we have to go through all of their children
    # in order to get a complete hierarchy.
    #
    set hierarchy_sql "
	select
		parent.project_id as parent_project_id,
		child.project_id,
		child.parent_id,
		child.tree_sortkey,
		child.project_name,
		child.project_nr,
		child.tree_sortkey,
		tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as tree_level,
		o.object_type
	from
		im_projects parent,
		im_projects child,
		acs_objects o
	where
		parent.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
		and parent.parent_id is null
		and parent.project_id in (
			select	main_project_id
			from	($percentage_sql) t
		)
		and child.project_id = o.object_id
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
	order by
		parent.project_id,
		child.tree_sortkey
    "

    set empty ""
    set name_hash($empty) ""
    set parent_project_id 0
    set old_parent_project_id 0
    set hierarchy_lol {}
    db_foreach project_hierarchy $hierarchy_sql {

	ns_log Notice "gantt-resources-planning: parent=$parent_project_id, child=$project_id, tree_level=$tree_level"
	# Store the list of sub-projects into the hash once the main project changes
	if {$old_parent_project_id != $parent_project_id} {
	    set main_project_hierarchy_hash($old_parent_project_id) $hierarchy_lol
	    set hierarchy_lol {}
	    set old_parent_project_id $parent_project_id
	}

	# Store project hierarchy information into hashes
	set parent_hash($project_id) $parent_id
	set has_children_hash($parent_id) 1
	set name_hash($project_id) $project_name
	set indent_hash($project_id) [expr $tree_level + 1]
	set object_name_hash($project_id) $project_name
	set object_type_hash($project_id) $object_type

	# Determine the project path that leads to the current sub-project
	# and aggregate the current assignment information to all parents.
	set hierarchy_row {}
	set level $tree_level
	set pid $project_id
	while {$level >= 0} {
	    lappend hierarchy_row $pid
	    set pid $parent_hash($pid)
	    incr level -1
	}

	# append the line to the list of sub-projects of the current main-project
	set project_path [f::reverse $hierarchy_row]
	lappend hierarchy_lol [list $project_id $project_name $tree_level $project_path]

	# ----------------------------------------------------------
	# Check if there are translation tasks associated with the current project
	# and add in a level below.
	set trans_tasks {}
	if {[info exists trans_tasks_per_project_hash($project_id)]} { set trans_tasks $trans_tasks_per_project_hash($project_id) }
	foreach task_row $trans_tasks {
	    set task_id [lindex $task_row 0]
	    set task_name [lindex $task_row 1]

	    set object_type_hash($task_id) "im_trans_task"
	    set object_name_hash($task_id) $task_name
	    set indent_hash($task_id) [expr 2+$tree_level]

	    lappend hierarchy_lol [list $task_id $task_name [expr 1+$tree_level] [linsert $project_path end $task_id]]
	}
    }

    # Save the list of sub-projects of the last main project (see above in the loop)
    set main_project_hierarchy_hash($parent_project_id) $hierarchy_lol


    set clicks([clock clicks -milliseconds]) hierarchy


    # ------------------------------------------------------------------
    # Calculate the left scale.
    #
    # The scale is composed by three different parts:
    #
    # - The user
    # - The outer "main_projects_sql" selects out users and their main_projects
    #   in which they are assigned with some percentage. All elements of this
    #   SQL are shown always.
    # - The inner "project_lol" look shows the _entire_ tree of sub-projects and
    #   tasks for each main_project. That's necessary, because no SQL could show
    #   us the 
    #
    # The scale starts with the "user" dimension, followed by the 
    # main_projects to which the user is a member. Then follows the
    # full hierarchy of the main_project.
    #
    set left_scale {}
    set old_user_id 0
    db_foreach left_scale_users $main_projects_sql {

	# ----------------------------------------------------------------------
	# Determine the user and write out the first line without projects

	# Add a line without project, only for the user
	if {$user_id != $old_user_id} {
	    # remember the type of the object
	    set otype_hash($user_id) "person"
	    # append the user_id to the left_scale
	    lappend left_scale [list $user_id ""]
	    # Remember that we have already processed this user
	    set old_user_id $user_id
	}

	# ----------------------------------------------------------------------
	# Write out the project-tree for the main-projects.

	# Make sure that the user is assigned somewhere in the main project
	# or otherwise skip the entire main_project:
	set main_projects_key "$user_id-$main_project_id"
 	if {![info exists member_of_main_project_hash($key)]} { continue }

	# Get the hierarchy for the main project as a list-of-lists (lol)
	set hierarchy_lol $main_project_hierarchy_hash($main_project_id)
	set open_p "c"
	if {[info exists collapse_hash($user_id)]} { set open_p $collapse_hash($user_id) }
	if {"c" == $open_p} { set hierarchy_lol [list] }

	# Loop through the project hierarchy
	foreach row $hierarchy_lol {

	    # Extract the pieces of a hierarchy row
	    set project_id [lindex $row 0]
	    set project_name [lindex $row 1]
	    set project_path [lindex $row 3]

	    # Iterate through the project_path, looking for:
	    # - the name of the project to display and
	    # - if any of the parents has been closed
	    ns_log Notice "gantt-resources-planning: pid=$project_id, name=$project_name, path=$project_path, row=$row"
	    set collapse_control_oid 0
	    set closed_p "c"
	    if {[info exists collapse_hash($user_id)]} { set closed_p $collapse_hash($user_id) }
	    for {set i 0} {$i < [llength $project_path]} {incr i} {
		set project_in_path_id [lindex $project_path $i]

		if {$i == [expr [llength $project_path] - 1]} {

		    # We are at the last element of the project "path" - This is the project to display.
		    set pid $project_in_path_id

		} else {

		    # We are at a parent (of any level) of the project
		    # Check if the parent is closed:
		    set collapse_p "c"
		    if {[info exists collapse_hash($project_in_path_id)]} { set collapse_p $collapse_hash($project_in_path_id) }
		    if {"c" == $collapse_p} { set closed_p "c" }

		}
	    }

	    # append the values to the left scale
	    if {"c" == $closed_p} { continue }
	    lappend left_scale [list $user_id $pid]

	}
    }

    set clicks([clock clicks -milliseconds]) left_scale


    # ------------------------------------------------------------------
    # Calculate the main resource assignment for "planned hours" and "absences" hash by looping
    # through the project hierarchy x looping through the date dimension
    #

    set planned_hours_sql "

	select 
		distinct sq.project_id,
		start_date_julian_planned_hours,
		end_date_julian_planned_hours,
		start_date,
		end_date,
		planned_units
	from 
                (
                select
                        child.project_id,
                        parent.project_id as main_project_id,
                        u.user_id,
                        trunc(m.percentage) as percentage,
                        to_char(child.start_date, 'J') as start_date_julian_planned_hours,
                        to_char(child.end_date, 'J') as end_date_julian_planned_hours,
    			child.start_date, 
			child.end_date,
			tt.planned_units
                from
                        im_projects parent,
                        im_projects child,
                        acs_rels r,
                        im_biz_object_members m,
                        users u,
			im_timesheet_tasks tt
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
                        and r.object_id_two = u.user_id
			and (parent.project_id = tt.task_id OR child.project_id = tt.task_id)
			$where_clause
		) sq
    "

    set min_date 1980-01-01
    set max_date 1980-01-02
    set next_workday 1980-01-01
    
    # Create hash containing the number of hours of a task distributed over the task length
    # These hours would need to be divided by the number of task members 

  
    db_foreach planned_hours_loop $planned_hours_sql {
	if {$calc_day_p} {
		# Determine members of task:  
		set user_list [list]
		set user_ctr 0 
		set user_percentage_list [list]

		set user_sql "
                        select
                                object_id_two as user_id, 
				bom.percentage as task_percentage
                        from
                                acs_rels r, 
				im_biz_object_members bom 
                        where
                                object_id_one = $project_id
                                and rel_type = 'im_biz_object_member'
				and bom.rel_id = r.rel_id
		"

                db_foreach user_list_sql $user_sql {
			lappend user_percentage_list [list $user_id $task_percentage]
			incr user_ctr
                }
		# Add one to end date since this day is included  
		set end_date_julian_planned_hours [expr $end_date_julian_planned_hours + 1]
		set end_date [db_string julian_date_select "select to_char( to_date($end_date_julian_planned_hours,'J'), 'YYYY-MM-DD') from dual"]

                # Sanity Check: Is there at least one user assigned to this task? 
		if { "0" == $user_ctr } { 
			ad_return_complaint 1 "Task (<a href='/intranet-timesheet2-tasks/new?task_id=project_id'>id:$project_id</a>) with no members. Each task should have at least one user assigned." 
		} 

		# Sanity Check: end_date needs to be >= start_date 
		if { $end_date_julian_planned_hours < $start_date_julian_planned_hours } { 
			ad_return_complaint 1 "End Date ($end_date) is earlier than start date ($start_date) of task id: <a href='/intranet-timesheet2-tasks/new?task_id=project_id'>$project_id</a>" 
		} 

		# Over how many work days do we have to distribute the planned hours,  
		set no_workdays [db_string get_view_id "select count(*) from im_absences_working_days_period_weekend_only('$start_date', '$end_date') as foo (days date)" -default 1]
		
		ns_log NOTICE "<br>no_workdays for project: $project_id: $no_workdays<br>"

		# In case no workday is found, we assign all planned hours to the next workday
		if { "0" == $no_workdays } {
			if { $start_date != $end_date} {
				# Find next workday - should be no longer than 2 days from start_date
				set next_julian_end_date [db_string get_data "select to_char( to_date('[expr $end_date_julian_planned_hours + 2]','J'), 'YYYY-MM-DD') from dual" -default 0]
				set next_workday [db_string get_view_id "select * from im_absences_working_days_period_weekend_only('$start_date', 'next_julian_end_date') as series_days (days date) limit 1" -default 0]
				set days_julian [db_string get_data "select to_char( to_date('next_workday','J'), 'YYYY-MM-DD') from dual" -default 0]
			} else { 
				ns_log NOTICE "Found start_date=end_date: $project_id,$user_id<br>"				
				set days_julian [db_string get_data "select to_char('$start_date'::date,'J')" -default 0]
			}

                        set user_ctr 0
                        foreach user_id $user_list {
                                set user_id [lindex [lindex $user_percentage_list $user_ctr] 0]
                                set user_percentage [lindex [lindex $user_percentage_list $user_ctr] 1]

				# Sanity check: Percentage assignment required
			        if { "" == user_percentage || ![info exists user_percentage] } {
					ad_return_complaint 1 "No assignment found for user_id: 
						<a href='/intranet/users/view?user_id=$user_id'>[im_name_from_user_id $user_id]</a> 
						on project task:<a href='/intranet/projects/view?project_id=$project_id'>$project_id</a>
					"
				} 

				if { [info exists user_day_task_array($user_id-$next_workday_julian-$project_id)] } {
					set user_day_task_array($user_id-$days_julian-$project_id) [expr [expr $planned_units.0 * $user_percentage/100] + $user_day_task_array($user_id-$days_julian-$project_id)]
				} else {
					set user_day_task_array($user_id-$days_julian-$project_id) [expr $planned_units.0 * $user_percentage/100]
				}
				incr user_ctr
                        }
		} else {
			# Distribute hours over workdays 
			set hours_per_day [expr $planned_units.0 / $no_workdays.0 ]
			set column_sql "select * from im_absences_working_days_period_weekend_only('$start_date', '$end_date') as series_days (days date)" 
			db_foreach column_list_sql $column_sql {		
			    	set days_julian [db_string get_data "select to_char('$days'::date,'J')" -default 0]
				set user_ctr 0
	                        foreach user_id $user_percentage_list {
					set user_id [lindex [lindex $user_percentage_list $user_ctr] 0]
					set user_percentage [lindex [lindex $user_percentage_list $user_ctr] 1]

        	                        # Sanity check: Percentage assignment required
	                                if { "" == $user_percentage || ![info exists user_percentage] } {
                        	                ad_return_complaint 1 "</br></br>No assignment found for user:
                                	                <a href='/intranet/users/view?user_id=$user_id'>[im_name_from_user_id $user_id]</a>
                                        	        on project task:<a href='/intranet/projects/view?project_id=$project_id'>$project_id</a>.<br>
							Please <a href='/intranet/projects/view?project_id=$project_id'>assign a occupation</a> for each task and try again</a>. 
							</br></br>
                                        	"
                	                }

        	                        set user_day_task_array($user_id-$days_julian-$project_id) [expr $hours_per_day * $user_percentage/100]
					#if {$project_id == 30961 } { append out " user_day_task_array($user_id-$days_julian-$project_id) = $hours_per_day * $user_percentage/100 <br>"}
					incr user_ctr
                	        }
        		}
			ns_log NOTICE "$project_id, $start_date, $end_date, workdays: $no_workdays, users: $user_list, Planned Units: $planned_units<br>$out"
		}	
	}

	# Evaluate min/max date to determine the start and end date of report 
	# Might be different from the dates set in the form because some tasks 
	# can start or and earlier 

	# if { $start_date > $min_date } { set min_date $start_date }
	# if { $end_date > $max_date } { set max_date $end_date }
	# if { $next_workday > $max_date } { set max_date $next_workday }

    }

    # ------------------------------------------------------------------
    # Calculate the main resource assignment hash by looping
    # through the project hierarchy x looping through the date dimension
    # 


    db_foreach percentage_loop $percentage_sql {

	# Loop through the days between start_date and end_data
	for {set i $child_start_date_julian} {$i <= $child_end_date_julian} {incr i} {

	    if {$i < $start_date_julian} { continue }
	    if {$i > $end_date_julian} { continue }

	    # Loop through the project hierarchy towards the top
	    set pid $project_id
	    set continue 1
	    while {$continue} {

		# Aggregate per day
		if {$calc_day_p} {
		    set key "$user_id-$pid-$i"
		    set perc 0
		    if {[info exists perc_day_hash($key)]} { set perc $perc_day_hash($key) }
		    set perc [expr $perc + $percentage]
		    set perc_day_hash($key) $perc
		}

		# Aggregate per week
		if {$calc_week_p} {
		    set week_julian $start_of_week_julian_hash($i)
		    set key "$user_id-$pid-$week_julian"
		    set perc 0
		    if {[info exists perc_week_hash($key)]} { set perc $perc_week_hash($key) }
		    set perc [expr $perc + $percentage]
		    set perc_week_hash($key) $perc
		}

		# Check if there is a super-project and continue there.
		# Otherwise allow for one iteration with an empty $pid
		# to deal with the user's level
		if {"" == $pid} { 
		    set continue 0 
		} else {
		    set pid $parent_hash($pid)
		}
	    }
	}
    }

    set clicks([clock clicks -milliseconds]) percentage_hash

    # ------------------------------------------------------------------
    # Calculate percentage numbers for translation tasks.
    # We are re-using the same SQL as for calculating the
    # trans_tasks for the hierarchy
    #
    set trans_task_percentage_sql "
		select
			t.*,
			t.project_id as trans_task_project_id,
			to_char(child.start_date, 'J') as trans_task_start_date_julian,
			to_char(t.end_date, 'J') as trans_task_end_date_julian,
			im_category_from_id(t.source_language_id) as source_language,
			im_category_from_id(t.target_language_id) as target_language
		from
			im_projects parent,
			im_projects child,
			(	select	t.*, 'trans' as transition, trans_id as user_id
				from	im_trans_tasks t
				where	t.trans_id is not null and
					t.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			UNION
				select	t.*, 'edit' as transition, edit_id as user_id
				from	im_trans_tasks t
				where	t.edit_id is not null and
					t.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			UNION
				select	t.*, 'proof' as transition, proof_id as user_id
				from	im_trans_tasks t
				where	t.proof_id is not null and
					t.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			UNION
				select	t.*, 'other' as transition, edit_id as user_id
				from	im_trans_tasks t
				where	t.other_id is not null and
					t.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			) t,
			users u
		where
			parent.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
			and parent.parent_id is null
			and parent.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			and parent.start_date <= to_date(:end_date, 'YYYY-MM-DD')
			and child.end_date >= to_date(:start_date, 'YYYY-MM-DD')
			and child.start_date <= to_date(:end_date, 'YYYY-MM-DD')
			and child.tree_sortkey
				between parent.tree_sortkey
				and tree_right(parent.tree_sortkey)
			and t.project_id = child.project_id
			and t.user_id = u.user_id
			and (t.end_date is null OR t.end_date >= to_date(:start_date, 'YYYY-MM-DD'))
			$where_clause
		order by
			t.project_id,
			t.task_name,
			t.source_language_id,
			t.target_language_id
    "
    db_foreach trans_task_percentage $trans_task_percentage_sql {

	# Calculate the percentage for the assigned user.
	# Input:
	# 	- task_units + task_uom: All UoMs are converted in Hours
	#	- task_type: Some task types take longer then others, influencing the conversion from S-Word to Hours.
	#	- trans_id, edit_id, proof_id, other_id: Assigning more people will increase overall time, but reduce individual time
	#	- quality_id: Higher quality may take longer.

	# How many hours does a translator work per day?
	set hours_per_day 8.0

	# How many words does a translator translate per hour? 3000 words/day is assumed average.
	# This factor may need adjustment depending on language pair (Japanese is a lot slower...)
	set words_per_hour [expr 3000.0 / $hours_per_day]

	# How many words does a "standard" page have?
	set words_per_page 400.0

	# How many words are there in a "standard" line?
	set words_per_line 4.5

	switch $task_uom_id {
	    320 { 
		#   320 | Hour
		set task_hours $task_units 
	    }
	    321 { 
		#   321 | Day
		set task_hours [expr $task_units * $hours_per_day] 
	    }
	    322 { 
		#   322 | Unit
		# No idea how to convert a "unit"...
		set task_hours [expr $task_units * $hours_per_day] 
	    }
	    323 { 
		#   323 | Page
		set task_hours [expr $task_units * $words_per_page / $words_per_hour] 
	    }
	    324 { 
		#   324 | S-Word
		set task_hours [expr $task_units / $words_per_hour] 
	    }
	    325 { 
		#   325 | T-Word
		# Here we should consider language specific conversion, but not yet...
		set task_hours [expr $task_units * $words_per_line / $words_per_hour] 
	    }
	    326 { 
		#   326 | S-Line
		# Here we should consider language specific conversion, but not yet...
		set task_hours [expr $task_units * $words_per_line / $words_per_hour] 
	    }
	    327 { 
		#   327 | T-Line
		# Should be adjusted to language specific swell
		set task_hours [expr $task_units * $words_per_line / $words_per_hour] 
	    }
	    328 { 
		#   328 | Week
		set task_hours [expr $task_units * 5 * $hours_per_day] 
	    }
	    329 { 
		#   329 | Month
		set task_hours [expr $task_units * 22 * $hours_per_day] 
	    }
	    default {
		# Strange UoM, maybe custom defined?
		set task_hours $task_units 
	    }
	}

	# Change the task_hours, depending on the transition to perform
	# Editing and proof reading takes about 1/10 of the time of translation.
	switch $transition {
	    trans { set task_hours [expr $task_hours * 1.0] }
	    edit  { set task_hours [expr $task_hours * 0.1] }
	    proof { set task_hours [expr $task_hours * 0.1] }
	    other { set task_hours [expr $task_hours * 1.0] }
	}


	# Calculate how many days are between start- and end date
	set task_duration_days [expr ($trans_task_end_date_julian - $trans_task_start_date_julian) * 5.0 / 7.0]

	# How much is the user available?
	set user_capacity_percent 100

	# Calculate the percentage of time required for the task divided by the time available for the task.
	set percentage [expr round(10.0 * 100.0 * $task_hours / ($task_duration_days * $hours_per_day * $user_capacity_percent * 0.01)) / 10.0]

	ns_log Notice "im_resource_mgmt_resource_planning: trans_tasks: task_name=$task_name, org_size=$task_units [im_category_from_id $task_uom_id], transition=$transition, user_id=$user_id, task_hours=$task_hours, task_duration_days=$task_duration_days => percentage=$percentage"

	# Calculate approx. dedication of users to tasks and aggregate per week
	# Loop through the days between start_date and end_data
	for {set i $trans_task_start_date_julian} {$i <= $trans_task_end_date_julian} {incr i} {
	    
	    # Skip dates before or after the currently displayed range for performance reasons
	    if {$i < $start_date_julian} { continue }
	    if {$i > $end_date_julian} { continue }
	    
	    # Loop through the project hierarchy towards the top
	    set pid $task_id
	    set continue 1
	    while {$continue} {
		
		# Aggregate per day
		if {$calc_day_p} {
		    set key "$user_id-$pid-$i"
		    set perc 0
		    if {[info exists perc_day_hash($key)]} { set perc $perc_day_hash($key) }
		    set perc [expr $perc + $percentage]
		    set perc_day_hash($key) $perc
		}
		
		# Aggregate per week
		if {$calc_week_p} {
		    set week_julian $start_of_week_julian_hash($i)
		    set key "$user_id-$pid-$week_julian"
		    set perc 0
		    if {[info exists perc_week_hash($key)]} { set perc $perc_week_hash($key) }
		    set perc [expr $perc + $percentage]
		    set perc_week_hash($key) $perc
		}
		
		# Check if there is a super-project and continue there.
		# Otherwise allow for one iteration with an empty $pid
		# to deal with the user's level
		if {"" == $pid} { 
		    set continue 0 
		} else {
		    set pid $parent_hash($pid)
		}
	    }
	}
    }




    set clicks([clock clicks -milliseconds]) percentage_trans_tasks_hash

    # ------------------------------------------------------------
    # Create upper date dimension

    # Top scale is a list of lists like {{2006 01} {2006 02} ...}
    set top_scale {}
    set last_top_dim {}
    for {set i $start_date_julian} {$i <= $end_date_julian} {incr i} {

	array unset date_hash
	array set date_hash [im_date_julian_to_components $i]
	
	set top_dim {}
	foreach top_var $top_vars {
	    set date_val ""
	    catch { set date_val $date_hash($top_var) }
	    lappend top_dim $date_val
	}

	# "distinct" clause: add the values of top_vars to the top scale, 
	# if it is different from the last one...
	# This is necessary for aggregated top scales like weeks and months.
	if {$top_dim != $last_top_dim} {
	    lappend top_scale $top_dim
	    set last_top_dim $top_dim
	}
    }

    set clicks([clock clicks -milliseconds]) top_scale


    # ------------------------------------------------------------
    # Display the Table Header
    
    # Determine how many date rows (year, month, day, ...) we've got
    set first_cell [lindex $top_scale 0]
    set top_scale_rows [llength $first_cell]
    set left_scale_size [llength [lindex $left_vars 0]]

    set header ""
    for {set row 0} {$row < $top_scale_rows} { incr row } {
	
	append header "<tr class=rowtitle>\n"
	set col_l10n [lang::message::lookup "" "intranet-resource-management.Dim_[lindex $top_vars $row]" [lindex $top_vars $row]]
	if {0 == $row} {
	    set zoom_in "<a href=[export_vars -base $this_url {top_vars {zoom "in"}}]>$gif_hash(magnifier_zoom_in)</a>\n" 
	    set zoom_out "<a href=[export_vars -base $this_url {top_vars {zoom "out"}}]>$gif_hash(magnifier_zoom_out)</a>\n" 
	    set col_l10n "<!-- $zoom_in $zoom_out --> $col_l10n\n" 
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

    set clicks([clock clicks -milliseconds]) display_table_header

    set left_clicks(start) 0
    set left_clicks(gif) 0
    set left_clicks(left) 0
    set left_clicks(write) 0
    set left_clicks(top_scale) 0
    set last_click [clock clicks]

    set left_clicks(top_scale_start) 0
    set left_clicks(top_scale_write_vars) 0
    set left_clicks(top_scale_to_julian) 0
    set left_clicks(top_scale_calc) 0
    set left_clicks(top_scale_cell) 0
    set left_clicks(top_scale_color) 0
    set left_clicks(top_scale_append) 0

    # ------------------------------------------------------------
    # Get absences 

    set absence_list [list]
     set absence_sql "
        select  category
        from    im_categories
        where   category_type = 'Intranet Absence Type'
        order by category_id
    "
    db_foreach absence $absence_sql { lappend absence_list $category }

    # ------------------------------------------------------------
    # Display the table body
    set row_ctr 0
    foreach left_entry $left_scale {

	set left_clicks(start) [expr $left_clicks(start) + [clock clicks] - $last_click]
	set last_click [clock clicks]

	ns_log Notice "gantt-resources-planning: left_entry=$left_entry"
	set row_html ""

	# ------------------------------------------------------------
	# Start the row and show the left_scale values at the left
	set class $rowclass([expr $row_ctr % 2])
	append row_html "<tr class=$class valign=bottom>\n"

	# Extract user and project. An empty project indicates 
	# an entry for a person only.
	set user_id [lindex $left_entry 0]
	set project_id [lindex $left_entry 1]

	# Determine what we want to show in this line
	set oid $user_id
	set otype "person"
	if {"" != $project_id} { 
	    set oid $project_id 
	    set otype "im_project"
	}
	if {[info exists object_type_hash($oid)]} { set otype $object_type_hash($oid) }

	# Display +/- logic
	set closed_p "c"
	if {[info exists collapse_hash($oid)]} { set closed_p $collapse_hash($oid) }
	if {"o" == $closed_p} {
	    set url [export_vars -base $collapse_url {page_url return_url {open_p "c"} {object_id $oid}}]
	    set collapse_html "<a href=$url>$gif_hash(minus_9)</a>"
	} else {
	    set url [export_vars -base $collapse_url {page_url return_url {open_p "o"} {object_id $oid}}]
	    set collapse_html "<a href=$url>$gif_hash(plus_9)</a>"
	}

	set left_clicks(gif) [expr $left_clicks(gif) + [clock clicks] - $last_click]
	set last_click [clock clicks]


	set object_has_children_p 0
	if {[info exists has_children_hash($oid)]} { set object_has_children_p $has_children_hash($oid) }
	if {!$object_has_children_p} { set collapse_html [util_memoize [list im_gif cleardot "" 0 9 9]] }

	switch $otype {
	    person {
		set indent_level 0
		set user_name "undef user $oid"
		if {[info exists object_name_hash($oid)]} { set user_name $object_name_hash($oid) }
		set cell_html "$collapse_html $gif_hash(user) <a href='[export_vars -base $user_base_url {{user_id $oid}}]'>$user_name</a>"
	    }
	    im_project {
		set indent_level 1
		set project_name "undef project $oid"
		if {[info exists object_name_hash($oid)]} { set project_name $object_name_hash($oid) }
		set cell_html "$collapse_html $gif_hash(im_project) <a href='[export_vars -base $project_base_url {{project_id $oid}}]'>$project_name</a>"
	    }
	    im_timesheet_task {
		set indent_level 1
		set project_name "undef project $oid"
		if {[info exists object_name_hash($oid)]} { set project_name $object_name_hash($oid) }
		set cell_html "$collapse_html $gif_hash(im_timesheet_task) <a href='[export_vars -base $project_base_url {{project_id $oid}}]'>$project_name</a>"
	    }
	    im_trans_task {
		set indent_level 1
		set task_id $oid
		set task_name "undef im_trans_task $oid"
		if {[info exists object_name_hash($oid)]} { set task_name $object_name_hash($oid) }
		set cell_html "$collapse_html $gif_hash(im_trans_task) <a href='[export_vars -base $trans_task_base_url {{task_id $oid}}]'>$task_name</a>"
	    }
	    default { 
		set cell_html "unknown object '$otype' type for object '$oid'" 
	    }
	}

	# Indent the object name
	if {[info exists indent_hash($oid)]} { set indent_level $indent_hash($oid) }
	set indent_html ""
	for {set i 0} {$i < $indent_level} {incr i} { append indent_html "&nbsp; &nbsp; &nbsp; " }

	append row_html "<td><nobr>$indent_html$cell_html</nobr></td>\n"

	set left_clicks(left) [expr $left_clicks(left) + [clock clicks] - $last_click]
	set last_click [clock clicks]

	# ------------------------------------------------------------
	# Write the left_scale values to their corresponding local 
	# variables so that we can access them easily when calculating
	# the "key".
	for {set i 0} {$i < [llength $left_vars]} {incr i} {
	    set var_name [lindex $left_vars $i]
	    set var_value [lindex $left_entry $i]
	    set $var_name $var_value
	}


	set left_clicks(write) [expr $left_clicks(write) + [clock clicks] - $last_click]
	set last_click [clock clicks]
	
	# ------------------------------------------------------------
	# Start writing out the matrix elements
	set last_julian 0
	foreach top_entry $top_scale {

	    set left_clicks(top_scale_start) [expr $left_clicks(top_scale_start) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    # Write the top_scale values to their corresponding local 
	    # variables so that we can access them easily for $key
	    for {set i 0} {$i < [llength $top_vars]} {incr i} {
		set var_name [lindex $top_vars $i]
		set var_value [lindex $top_entry $i]
		set $var_name $var_value
	    }

	    set left_clicks(top_scale_write_vars) [expr $left_clicks(top_scale_write_vars) + [clock clicks] - $last_click]
	    set last_click [clock clicks]


	    # Calculate the julian date for today from top_vars
	    set julian_date [util_memoize [list im_date_components_to_julian $top_vars $top_entry]]
	    if {$julian_date == $last_julian} {
		# We're with the second ... seventh entry of a week.
		continue
	    } else {
		set last_julian $julian_date
	    }

	    set left_clicks(top_scale_to_julian) [expr $left_clicks(top_scale_to_julian) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    # Fill 
	    # Get the value for this cell if mode = percentage 
	    set val ""

	    if { "percentage" == $calculation_mode } {
		if {$calc_day_p} {
		    set key "$user_id-$project_id-$julian_date"
		    if {[info exists perc_day_hash($key)]} { set val $perc_day_hash($key) }
		}
		if { $calc_week_p } {
		    set week_julian [util_memoize [list im_date_julian_to_week_julian $julian_date]]
		    ns_log Notice "intranet-resource-management-procs: julian_date=$julian_date, week_julian=$week_julian"
		    set key "$user_id-$project_id-$week_julian"
		    if {[info exists perc_week_hash($key)]} { set val $perc_week_hash($key) }
		    if {"" == [string trim $val]} { set val 0 }
		    set val [expr round($val / 7.0)]
		}
	    } else {
		# Show planned hours 
		if {$calc_day_p} {
		    # Determine availability of user (hours/day)  
    		    set availability_user_perc [db_string get_data "select availability from im_employees where employee_id=$user_id" -default 0]
		    set hours_availability_user [expr $hours_per_day * $availability_user_perc / 100 ]
                    set key "$user_id-$julian_date-$project_id"
		    append out "$key<br>"
		    if { [info exists user_day_task_array($key)] } { 
			set val [expr 100 * $user_day_task_array($key) / $hours_availability_user ] 
		    }
                }
	    }

	    if {"" == [string trim $val]} { set val 0 }

	    set left_clicks(top_scale_calc) [expr $left_clicks(top_scale_calc) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    set occupation_user 0
	    set occupation_user_total 0

	    switch $otype {
            	person {

		    if { "planned_hours" == $calculation_mode } {

			set cell_html "<div style='width:10px'>"

			# Accumulate "Planned Hours" over all tasks and create bar in case > 0   
			set user_jdate_key "$user_id-$julian_date"
			# append out "<br>key: $user_id-$julian_date"
	
			set acc_hours 0 
        		foreach {key value} [array get user_day_task_array] {
			    if { [string range $key 0 [expr [string length $user_jdate_key]-1]] == $user_jdate_key } {
				set acc_hours [expr $acc_hours + $value]
			    }
	        	}

			if { "0" != $acc_hours } { 
			        set occupation_user_total [expr $occupation_user_total + $acc_hours] 
				append cell_html [im_resource_mgmt_resource_planning_cell custom [expr 100*$acc_hours/$hours_availability_user] #666699 "$occupation_user_total" ""]
			}  
		
			# Check for absences create bar in case an absence is found 
			set absence_key "$julian_date-$user_id"
                        if {[info exists absences_hash($absence_key)]} {
                                set occupation_user [expr $occupation_user + $hours_per_absence]
			        set occupation_user_total [expr $occupation_user_total + $occupation_user] 
				append cell_html [im_resource_mgmt_resource_planning_cell custom 100 [im_absence_mix_colors $absences_hash($absence_key)] [lindex $absence_list $absences_hash($absence_key)] ""]
                        }

			# Evaluate total percentage of occupation and write it as a text  
			set perc_occupation_user_total [expr 100 * $occupation_user_total / $hours_availability_user]

			if { $perc_occupation_user_total > 100 } {
				set perc_occupation_user_total_color #ff3300 
			} else {
				set perc_occupation_user_total_color #000000
			} 

			if { $perc_occupation_user_total != 0 } {
				set perc_occupation_user_total [expr int($perc_occupation_user_total)]
				append cell_html "<span style='font: small/0.3em Tahoma,sans-serif; font-size:4px; color:$perc_occupation_user_total_color'><br><br>$perc_occupation_user_total</span>"
			}
			append cell_html "</div>"
		    } else {
			set cell_html "&nbsp;"    
		    }
            	}
	        default {
                    if { "percentage" == $calculation_mode } {
			set cell_html [util_memoize [list im_resource_mgmt_resource_planning_cell default $val "" "" ""]]
		    } else {
		        set cell_html [im_resource_mgmt_resource_planning_cell custom $val \#666699 "$val%" ""]
		    }
		}
	    }

	    set left_clicks(top_scale_cell) [expr $left_clicks(top_scale_cell) + [clock clicks] - $last_click]
	    set last_click [clock clicks]
	    
	    # Lookup the color of the absence for field background color
	    # Weekends
	    set list_of_absences ""
	    if {$calc_day_p && [info exists weekend_hash($julian_date)]} {
		set absence_key $julian_date
		append list_of_absences $weekend_hash($absence_key)
	    }
	
	    # Absences
	    set absence_key "$julian_date-$user_id"
	    if {[info exists absences_hash($absence_key)]} {
		# Color the entire column in case of an absence 
		# append list_of_absences $absences_hash($absence_key)
	    }
	
	    set col_attrib ""
	    if {"" != $list_of_absences} {
		if {$calc_week_p} {
		    while {[string length $list_of_absences] < 5} { append list_of_absences " " }
		}
		set color [util_memoize [list im_absence_mix_colors $list_of_absences]]
		set col_attrib "bgcolor=#$color"
	    }

	    set left_clicks(top_scale_color) [expr $left_clicks(top_scale_color) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    append row_html "<td $col_attrib>$cell_html</td>\n"

	    set left_clicks(top_scale_append) [expr $left_clicks(top_scale_append) + [clock clicks] - $last_click]
	    set last_click [clock clicks]
	}

	set left_clicks(top_scale) [expr $left_clicks(top_scale) + [clock clicks] - $last_click]
	set last_click [clock clicks]
	
	append html $row_html
	append html "</tr>\n"
	incr row_ctr
    }

    set clicks([clock clicks -milliseconds]) display_table_body
    # set clicks([clock clicks -milliseconds]) asfd

    # ------------------------------------------------------------
    # Close the table
    #
    set html "<table cellspacing=3 cellpadding=3 valign=bottom>\n$html\n</table>\n"

    if {0 == $row_ctr} {
	set no_rows_msg [lang::message::lookup "" intranet-resource-management.No_rows_selected "
		No rows found.<br>
		Maybe there are no assignments of users to projects in the selected period?
	"]
	append html "<br><b>$no_rows_msg</b>\n"
    }

    set clicks([clock clicks -milliseconds]) close_table

    # ------------------------------------------------------------
    # Profiling HTML
    #
    if {$debug_p} {
	set debug_html "<br>&nbsp;<br><table>\n"
	set last_click 0
	foreach click [lsort -integer [array names clicks]] {
	    if {0 == $last_click} { 
		set last_click $click 
		set first_click $click
	    }
	    append debug_html "<tr><td>$click</td><td>$clicks($click)</td><td>[expr ($click - $last_click) / 1000.0]</td></tr>\n"
	    set last_click $click
	}
	append debug_html "<tr><td> </td><td><b>Total</b></td><td>[expr ($last_click - $first_click) / 1000.0]</td></tr>\n"
	append debug_html "<tr><td colspan=3>&nbsp;</tr>\n"
	append debug_html "<tr><td> </td><td> start</td><td>$left_clicks(start)</td></tr>\n"
	append debug_html "<tr><td> </td><td> gif</td><td>$left_clicks(gif)</td></tr>\n"
	append debug_html "<tr><td> </td><td> left</td><td>$left_clicks(left)</td></tr>\n"
	append debug_html "<tr><td> </td><td> write</td><td>$left_clicks(write)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale</td><td>$left_clicks(top_scale)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_start </td><td>$left_clicks(top_scale_start)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_write_vars </td><td>$left_clicks(top_scale_write_vars)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_to_julian </td><td>$left_clicks(top_scale_to_julian)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_calc </td><td>$left_clicks(top_scale_calc)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_cell </td><td>$left_clicks(top_scale_cell)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_color </td><td>$left_clicks(top_scale_color)</td></tr>\n"
	append debug_html "<tr><td> </td><td> top_scale_append </td><td>$left_clicks(top_scale_append)</td></tr>\n"
	append debug_html "</table>\n"
	
	append html $debug_html
    }

    return $html
}


# ---------------------------------------------------------------
# Show the status of potential freelancers in the member-add page
# ---------------------------------------------------------------

ad_proc im_resource_mgmt_resource_planning_add_member_component { } {
    Component that returns a formatted HTML table.
    The table contains the availability for all persons with
    matching freelance profiles.
} {
    # ------------------------------------------------
    # Security
    # Check that the user has the right to "read" the group Freelancers
  
    set user_id [ad_get_user_id]
    set perm_p [db_string freelance_read "select im_object_permission_p([im_profile_freelancers], :user_id, 'read')"]
    if {"t" != $perm_p} {
        return ""
    }

    # Only show if the freelance package is installed.
    if {![db_table_exists im_freelance_skills]} { return "" }



    # ------------------------------------------------
    # Parameter Logic
    # 
    # Get the freel_trans_order_by variable from the http header
    # because we can't trust that the embedding page will pass
    # this param into this component.

    set current_url [ad_conn url]
    set header_vars [ns_conn form]
    set var_list [ad_ns_set_keys $header_vars]

    # set local TCL vars from header vars
    ad_ns_set_to_tcl_vars $header_vars

    # Remove the "freel_trans_order_by" from the var_list
    set order_by_pos [lsearch $var_list "freel_trans_order_by"]
    if {$order_by_pos > -1} {
	set var_list [lreplace $var_list $order_by_pos $order_by_pos]
    }

    

    # ------------------------------------------------
    # Constants

    set source_lang_skill_type 2000
    set target_lang_skill_type 2002

    set order_freelancer_sql "user_name"

    # Project's Source & Target Languages
    set project_source_lang [db_string source_lang "
                select  substr(im_category_from_id(source_language_id), 1, 2)
                from    im_projects
                where   project_id = :object_id" \
    -default 0]

    set project_target_langs [db_list target_langs "
		select '''' || substr(im_category_from_id(language_id), 1, 2) || '''' 
		from	im_target_languages 
		where	project_id = :object_id
    "]
    if {0 == [llength $project_target_langs]} { set project_target_langs [list "'none'"]}


    # ------------------------------------------------
    # Get the list of users that meet source- and target language requirements

    set freelance_sql "
	select distinct
		u.user_id,
		im_name_from_user_id(u.user_id) as user_name
	from
		users u,
		group_member_map m, 
		membership_rels mr,
		(	select	user_id
			from	im_freelance_skills
			where	skill_type_id = :source_lang_skill_type
				and substr(im_category_from_id(skill_id), 1, 2) = :project_source_lang
		) sls,
		(	select	user_id
			from	im_freelance_skills
			where	skill_type_id = :target_lang_skill_type
				and substr(im_category_from_id(skill_id), 1, 2) in ([join $project_target_langs ","])
		) tls
	where
		m.group_id = acs__magic_object_id('registered_users'::character varying) AND 
		m.rel_id = mr.rel_id AND 
		m.container_id = m.group_id AND 
		m.rel_type::text = 'membership_rel'::text AND 
		mr.member_state::text = 'approved'::text AND 
		u.user_id = m.member_id AND
		sls.user_id = u.user_id AND
		tls.user_id = u.user_id
	order by
		$order_freelancer_sql
    "
    
    set user_list {}
    db_foreach freelancers $freelance_sql {
	lappend user_list $user_id
    }

    # ------------------------------------------------
    # Call the resource planning compoment
    #

    db_1row date "
	select	now()::date as start_date,
		now()::date + 30 as end_date
    "

    set result [im_resource_mgmt_resource_planning \
		-start_date $start_date \
		-end_date $end_date \
		-top_vars "year week_of_year day_of_week" \
		-user_id $user_list
    ]

    return $result
}

