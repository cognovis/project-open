# /packages/intranet-resource-management/tcl/intranet-resource-management.tcl
#
# Copyright (C) 2010-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Report on and modify resource assignments to tasks of various types.
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
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
    limit_height_p 
} {
    Takes a percentage value and returns a formatted HTML ready to be
    displayed as part of a cell. 
    - Mode "default" returns a gif   
    - Mode "custom" creates a bar using a pixel and bg color    
} {

    if {![string is double $percentage]} { return $percentage }
    if { (0.0 == $percentage || "" == $percentage) && !$limit_height_p } { return "" }

    # Calculate the percentage / 10, so that height=10 with 100%
    # Always draw a line, even if percentage is < 5% 
    # (which would result in 0 height of the GIF...)
    set p 0
    catch {
        set p [expr round((1.0 * $percentage) / 10.0)]
    }
    set p [expr round((1.0 * $percentage) / 10.0)]
    if {0 == $p && $percentage > 0.0} { set p 1 }

    # 
    if { $p > 10 && $limit_height_p } { set p 10 }

    if { "default" == $mode} {
	    # Color selection
	    set color ""
	    if {$percentage > 0} { set color "bluedot" }
	    if {$percentage > 100} { set color "FF0000" }
	    set color "bluedot"    
	    set result [im_gif $color "$percentage" 0 15 $p]
    } else {
	if { $limit_height_p } { 
	    set percentage 10 
	} else {
	    set percentage [expr $percentage/5]
	}
	set result "<span class='img-cap' title='$title'>
			<img src='/intranet/images/cleardot.gif' title='$title' alt='$title $appendix' border='0' height='$percentage' width='15' style='background-color:$color_code'>
			<cite>$appendix</cite>
		</span>"
    }
    return $result
}


ad_proc -public im_resource_mgmt_get_bar_color {
    mode
    val
} {
    - returns a color code considering package parameter etc. 
} {
    # green: 33ff00; yellow: #FFFF00; red: #ff0000

	switch $mode {
 		"traffic_light" {
			set bar_chart_color "\#33ff00"
		        if { $val > 70 } { set bar_chart_color "\#FFFF00" }
		        if { $val > 100 } { set bar_chart_color "\#ff0000" }
		}
		"gradient" {
		    # http://stackoverflow.com/questions/340209/generate-colors-between-red-and-green-for-a-power-meter
		    if { $val > 100 } { set val 100 }
		    set val abs([expr $val - 100])		    
		    set val [expr $val / 100]
		    set h [expr $val * 0.38]
		    set s 0.9 			
    		    set b 0.9 			
		    set bar_chart_color [hsv2hex $h $s $b]

		    # fool extreme red & extreme green 
		    if { $bar_chart_color == "#e61717" } {set bar_chart_color "#ff0000"}
		    if { $bar_chart_color == "#17e651" } {set bar_chart_color "#33ff00"}

		}
 		default {
			set bar_chart_color "\#666699"
		}
	}
    return $bar_chart_color
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

    # Trim zero for months JAN-SEPT
    if { $month_of_year < 10  } { set month_of_year [string trim $month_of_year 0]}	

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
		set julian [dt_ansi_to_julian_single_arg "$year-$month_of_year-$day_of_month"]

	    }
	}
	"year month_of_year" {
	    catch {
		if {1 == [string length $month_of_year]} { set month_of_year "0$month_of_year" }
                set julian [dt_ansi_to_julian_single_arg "$year-$month_of_year-01"]
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
    {-show_all_employees_p "1"}
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
    {-excluded_group_ids "" }
    {-show_departments_only_p "0" }
} {

    Creates Resource Report 

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show

    ToDo: 
    	- excluded_group_ids currently only accepts a single int

} {

    # ---------------------------------------
    # DEFAULTS
    # ---------------------------------------

    set start_date_request $start_date
    set end_date_request $end_date

    # Write iregularities to protocoll
    set err_protocoll ""

    # Department to use, when user is not assigned to one 
    set default_department [parameter::get -package_id [apm_package_id_from_key intranet-resource-management] -parameter "DefaultCostCenterId" -default 525]

    if { ![info exists show_departments_only_p] || "" == $show_departments_only_p } { set show_departments_only_p 0 }
    if {"" == $excluded_group_ids} { set excluded_group_ids 0 }

    set limit_height 1
    set bar_type "traffic_light"
    set seperate_bars_for_plannedhours_and_absences_p 0
    
    set out ""
    set hours_per_day [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "TimesheetHoursPerDay" -default 8.0]
    set hours_per_day_glob $hours_per_day 

    set hours_per_absence [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "TimesheetHoursPerAbsence" -default 8.0]

    set html ""
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    set sigma "&Sigma;"
    # set page_url "/intranet-resource-management/gantt-resources-planning"
    set page_url "/intranet-cust-lippokwolf/resources-planning"

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

    set union_criteria ""
    if {"" != $employee_cost_center_id && 0 != $employee_cost_center_id} { 
	lappend criteria "u.user_id in (
		select	employee_id
		from	im_employees
		where	department_id = :employee_cost_center_id
	)"

	set union_criteria " 
                    and     e.employee_id in (
                                select  employee_id
                                from    im_employees
                                where   department_id = $employee_cost_center_id
			    )
	"
    } 

    if { "" != $excluded_group_ids } {
        lappend criteria "u.user_id not in (
                                select  object_id_two from acs_rels
                                where   object_id_one = $excluded_group_ids and
                                        rel_type = 'membership_rel'
                        )
	"
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

    # ad_return_complaint 1 [array get day_of_week_hash]
    # ad_return_complaint 1 [array get start_of_week_julian_hash]

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
			CASE m.percentage IS NULL
	                	WHEN true THEN
				0 
                		ELSE
				trunc(m.percentage)
		        END as percentage,
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
			-- and m.percentage is not null
			$where_clause
    "

    # ------------------------------------------------------------
    # Main Projects x Users:
    # Return all main projects where a user is assigned in one of the sub-projects
    #

    set show_all_employees_p 1

    set show_all_employees_sql ""
    if {1 == $show_all_employees_p} {
	set show_all_employees_sql "
	UNION
		select
			0::integer as main_project_id,
			0::text as main_project_name,
			p.person_id as user_id,
			im_name_from_user_id(p.person_id) as user_name, 
			e.department_id as department_id
		from
			persons p,
			group_distinct_member_map gdmm, 
			im_employees e
		where
			gdmm.member_id = p.person_id and
			gdmm.group_id = [im_employee_group_id] and
			e.employee_id = p.person_id
		and 	e.employee_id not in (
                              select  object_id_two from acs_rels
                              where   object_id_one = $excluded_group_ids and
                                      rel_type = 'membership_rel'
                        )
		$union_criteria
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
			im_name_from_user_id(p.person_id) as user_name,
                        e.department_id as department_id
		from
			persons p, 
                        im_employees e

		where
			p.person_id in ([join $user_id ","]) and
                        e.employee_id = p.person_id
		$union_criteria
	"
    }

    set main_projects_sql "
	select distinct
		main_project_id,
		main_project_name,
		user_id,
		user_name,
		department_id
	from
		(select
			parent.project_id as main_project_id,
			parent.project_name as main_project_name,
			u.user_id,
			im_name_from_user_id(r.object_id_two) as user_name, 
			department_id
		from
			im_projects parent,
			im_projects child,
			acs_rels r,
			im_biz_object_members m,
			users u,
			im_employees e
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
			-- and m.percentage is not null
			and u.user_id = e.employee_id
			$where_clause
		$show_users_sql
		$show_all_employees_sql
		) t
	order by
		department_id,
		user_name,
		main_project_id
    "
    db_foreach main_projects $main_projects_sql {
	set key "$user_id-$main_project_id"
	set member_of_main_project_hash($key) 1
	set object_name_hash($user_id) "$user_name"
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

	    if { [info exists parent_hash($pid)] } {
		set pid $parent_hash($pid)
	    } else {
		ad_return_complaint 1 "We have found an issue with project id: <a href='/intranet/projects/view?project_id=$pid'>$pid</a>."
	    }
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
    set total_user_ctr 0

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
	    # Count users listed in this whole report  
	    incr total_user_ctr 
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
	    ns_log Notice "intranet-resource-management: pid=$project_id, name=$project_name, path=$project_path, row=$row"
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
		planned_units,
		percent_completed
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
			child.percent_completed,
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
    
    # Create an array (user_day_task_arr) that contains for each user the number of hours 
    # planned for each unit (day/week) and project. 
    # Key Sample: user_day_task_arr($user_id-$days_julian-$project_id)
    # Tasks > 1 day are distributed over the entire task length
    # If number of task members > 1, planned units are distributed
    # considering availability of project memeber portlet (percentage) 

    # At the same time build an array that shows the users total 
    # for a particular day: user_day_total_plannedhours_arr($user_id-$days_julian)

    db_foreach planned_hours_loop $planned_hours_sql {

	# Check the number of tasks this task is parent to  
	set no_parents [db_string get_data "select count(*) from im_projects where parent_id = $project_id" -default 0]

	if { "0" == $no_parents } {

	    # Consider completion status of task 
	    if { [info exists percent_completed] && $percent_completed > 0 } {
		set planned_units [expr $planned_units - [expr $planned_units * $percent_completed / 100]]
	    }

	    # There are no other tasks having this task as a parent, so we pick only planned hours for those:
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
		# set end_date [db_string julian_date_select "select to_char( to_date($end_date_julian_planned_hours,'J'), 'YYYY-MM-DD') from dual"]
                set end_date [im_date_julian_to_ansi  "$end_date_julian_planned_hours"]

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

				# set next_julian_end_date [db_string get_next_julian_end_date "select to_char( to_date('[expr $end_date_julian_planned_hours + 2]','J'), 'YYYY-MM-DD') from dual" -default 0]
			    	set next_julian_end_date [im_date_julian_to_ansi [expr $end_date_julian_planned_hours + 2]] 				

				set next_workday [db_string get_next_workday "select * from im_absences_working_days_period_weekend_only('$start_date', 'next_julian_end_date') as series_days (days date) limit 1" -default 0]
				# set days_julian-startdate-ne-end-date [db_string get_days_julian "select to_char( to_date('next_workday','J'), 'YYYY-MM-DD') from dual" -default 0]
				set days_julian-startdate-ne-end-date [im_date_julian_to_ansi "$next_workday"]   
			} else { 
				ns_log NOTICE "Found start_date=end_date: $project_id,$user_id<br>"				
                                set days_julian [dt_ansi_to_julian_single_arg "$start_date"]
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

				if { [info exists user_day_task_arr($user_id-$next_workday_julian-$project_id)] } {
					set user_day_task_arr($user_id-$days_julian-$project_id) [expr [expr $planned_units.0 * $user_percentage/100] + $user_day_task_arr($user_id-$days_julian-$project_id)]
				} else {
					set user_day_task_arr($user_id-$days_julian-$project_id) [expr $planned_units.0 * $user_percentage/100]
				}
			    
				# Set USER totals
				if { [info exists user_day_total_plannedhours_arr($user_id-$days_julian)] } {
				    set user_day_total_plannedhours_arr($user_id-$days_julian) [expr $user_day_task_arr($user_id-$days_julian-$project_id) + $user_day_total_plannedhours_arr($user_id-$days_julian)]
				} else {
	   			    set user_day_total_plannedhours_arr($user_id-$days_julian) $user_day_task_arr($user_id-$days_julian-$project_id)
				}	
				incr user_ctr
                        }
		} else {
			# Distribute hours over workdays 
		    	if { [string first "." $planned_units] == -1 } { set planned_units $planned_units.0 }  
		    	if { [string first "." $no_workdays] == -1 } { set no_workdays $no_workdays.0 }  
			set hours_per_day [expr $planned_units / $no_workdays ]

			set column_sql "select * from im_absences_working_days_period_weekend_only('$start_date', '$end_date') as series_days (days date)" 
			set no_users [db_string get_number_users "select count(*) from im_absences_working_days_period_weekend_only('$start_date', '$end_date') as series_days (days date)" -default 1] 

			db_foreach column_list_sql $column_sql {		
			    	set days_julian [dt_ansi_to_julian_single_arg "$days"]
				set user_ctr 0
	                        foreach user_id $user_percentage_list {
					set user_id [lindex [lindex $user_percentage_list $user_ctr] 0]
					set user_percentage [lindex [lindex $user_percentage_list $user_ctr] 1]
        	                        # Sanity check: Percentage assignment required
	                                if { "" == $user_percentage || ![info exists user_percentage] } {
					    set user_percentage [expr 100 / $no_users]
					    # ad_return_complaint 1 "</br></br>No assignment found for user:
                                	    #            <a href='/intranet/users/view?user_id=$user_id'>[im_name_from_user_id $user_id]</a>
                                            #	        on project task:<a href='/intranet/projects/view?project_id=$project_id'>$project_id</a>.<br>
					    #		Please <a href='/intranet/projects/view?project_id=$project_id'>assign a occupation</a> for each task and try again</a>. 
					    #		</br></br>
                                            # "
                	                }

        	                        set user_day_task_arr($user_id-$days_julian-$project_id) [expr $hours_per_day * $user_percentage/100]

					# Set USER totals
					if { [info exists user_day_total_plannedhours_arr($user_id-$days_julian)] } {
					    set user_day_total_plannedhours_arr($user_id-$days_julian) [expr $user_day_task_arr($user_id-$days_julian-$project_id) + $user_day_total_plannedhours_arr($user_id-$days_julian)]
					} else {
						set user_day_total_plannedhours_arr($user_id-$days_julian) $user_day_task_arr($user_id-$days_julian-$project_id)
					}	
					#if {$project_id == 30961 } { append out " user_day_task_arr($user_id-$days_julian-$project_id) = $hours_per_day * $user_percentage/100 <br>"}
					incr user_ctr
                	        }
        		}
			ns_log NOTICE "$project_id, $start_date, $end_date, workdays: $no_workdays, users: $user_list, Planned Units: $planned_units<br>$out"
		    }	
	}

	# Evaluate min/max date to determine the start and end date of report 
	# Might be different from the dates set in the form because some tasks 
	# can start or end earlier 

	# if { $start_date > $min_date } { set min_date $start_date }
	# if { $end_date > $max_date } { set max_date $end_date }
	# if { $next_workday > $max_date } { set max_date $next_workday }

	}
    }


    # ------------------------------------------------------------------
    # Calculate the main resource assignment hash by looping
    # through the project hierarchy x looping through the date dimension  

    db_foreach percentage_loop $percentage_sql {
	
	# sanity check for empty start/end date
	if {""==$start_date_julian || ""==$end_date_julian} {
		ad_return_complaint 1 "Empty date found. Please verify start/end date of Project ID: <a href='/intranet/projects/view?project_id=$project_id'>$project_id</a>" 
	}

	# Skip if no data
	if {"" == $child_start_date_julian} { continue }
	if {"" == $child_end_date_julian} { continue }
	
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
		    if { [info exists parent_hash($pid)] } {
			set pid $parent_hash($pid)
		    } else {
			ad_return_complaint 1 "We have found an issue with project id: <a href='/intranet/projects/view?project_id=$pid'>$pid</a>."
		    }
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

	ns_log Notice "im_resource_mgmt_resource_planning: trans_tasks: task_name=$task_name, org_size=$task_units 
                       [im_category_from_id $task_uom_id], transition=$transition, user_id=$user_id, task_hours=$task_hours, 
                       task_duration_days=$task_duration_days => percentage=$percentage"

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
		    if { [info exists parent_hash($pid)] } {
			set pid $parent_hash($pid)
		    } else {
			ad_return_complaint 1 "We have found an issue with project id: <a href='/intranet/projects/view?project_id=$pid'>$pid</a>."
		    }
		}
	    }
	}
    }


    set clicks([clock clicks -milliseconds]) percentage_trans_tasks_hash

    # -------------------
    # Define Top Scale 
    # -------------------

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

    # Determine how many date rows (year, month, day, ...) we've got
    set first_cell [lindex $top_scale 0]

    set top_scale_rows [llength $first_cell]
    set left_scale_size [llength [lindex $left_vars 0]]

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

    # ------------------------------------------------------------------------------------------------------------------------
    # ------------------------------------------------------------------------------------------------------------------------
    # Create OUTPUT
    # ------------------------------------------------------------------------------------------------------------------------
    # ------------------------------------------------------------------------------------------------------------------------

    # -----------------------------------------------------------
    # | For all elements left column (employees)
    # |  --------------------------------------------------------
    # |  |  ?? Change of Department ?? 
    # |  |-------------------------------------------------------
    # |  |  Y                               |           N  
    # |  |------------------------------------------------------
    # |  | Show row accumulation department |          - 
    # |  | Show rows employees              |
    # |  |------------------------------------------------------
    # |  |
    # |  |  tbc. ... 

    set row_ctr 0
    set show_row_task_p 0 

    foreach left_entry $left_scale {
	# example for left scale: {8892 {}} {624 {}} {30730 {}} {29622 {}} {29622 29946} ... 

	# This boolean is needed to calculate the total of hours available for the minimum UOM (day/week/month)
        set row_shows_employee_p 0

	set left_clicks(start) [expr $left_clicks(start) + [clock clicks] - $last_click]
	set last_click [clock clicks]

	ns_log Notice "gantt-resources-planning: left_entry=$left_entry"
	set row_html ""

	# Extract user and project. An empty project indicates 
	# an entry for a person only.
	set user_id [lindex $left_entry 0]

	set user_department_id [util_memoize [list db_string get_data "select department_id from im_employees where employee_id = $user_id" -default 0]]
	if { ""==$user_department_id } { set user_department_id $default_department }

	# -----------------------------------------------
        # Determine availability of user (hours/day)  
	# -----------------------------------------------
        set availability_user_perc [util_memoize [list db_string get_data "select availability from im_employees where employee_id=$user_id" -default 0]]
        if { ![info exists availability_user_perc] } { set availability_user_perc 100 }
        # Make it 100% when no value found -> ToDo: Print hint on bottom of report 
	if { "" == $availability_user_perc } { set availability_user_perc 100 }

	set hours_availability_user [expr $hours_per_day_glob * $availability_user_perc / 100 ]

	set project_id [lindex $left_entry 1]

	# Determine what we want to show in this line
	set oid $user_id
	set otype "person"

	if {"" != $project_id} { 
	    set oid $project_id 
	    set otype "im_project"
	} else {
	    # no project_id found, row shows employee
	    set row_shows_employee_p 1
	}

	# --------------------------------------------------------------------
	# Write department Row when user_department_id has changed ...   
	# -------------------------------------------------------------------

	if { $row_shows_employee_p } {
	    if { 0 == $row_ctr } {
		set user_department_id_predecessor $user_department_id
	    } else {
		if { $user_department_id_predecessor != $user_department_id } {
		    set first_department_p 0
		    # Change of department -> show subtotals and print rows 
			append html [write_department_row \
					$department_row_html \
					$user_department_id_predecessor \
					[array get totals_department_absences_arr] \
					[array get totals_department_planned_hours_arr] \
					[array get totals_department_availability_arr] \
					$top_scale $top_vars $show_departments_only_p \
				] 

		    set user_department_id_predecessor $user_department_id

		    # Reset department arrays 
		    array unset totals_department_absences_arr
		    array unset totals_department_availability_arr
		    array unset totals_department_planned_hours_arr

		    set department_row_html ""
	        }
	    }
	}

	# ------------------------------------------------------------
	# Start the row and show the left_scale values at the left

	set class $rowclass([expr $row_ctr % 2])
	append department_row_html_tmp "<tr class=$class valign=bottom>\n"

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

	append department_row_html_tmp "<td><nobr>$indent_html$cell_html</nobr></td>\n"

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
	# ------------------------------------------------------------

	set last_julian 0
	set column_ctr 0 

	# topscale example: {2011 9 01} {2011 9 02}
	
	foreach top_entry $top_scale {
	    
	    set left_clicks(top_scale_start) [expr $left_clicks(top_scale_start) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    # Write the top_scale values to their corresponding local 
	    # variables so that we can access them easily for $key 
	    # Example: year month_of_year day_of_month
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

	    # Get the value for this cell 
	    set val ""
	    set val_hours ""

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
                    set key "$user_id-$julian_date-$project_id"
		    # Are there any planned hours for this day and this user?   
		    if { [info exists user_day_task_arr($key)] } { 
			if { 0 == $hours_availability_user } {
			     set val 0
			} else {
			    set val [expr 100 * $user_day_task_arr($key) / $hours_availability_user ] 
			}
			set val_hours $user_day_task_arr($key)
		    }
                } else {
		    # todo: week 
		}
	    }
	    if {"" == [string trim $val]} { set val 0 }
	    if {"" == [string trim $val_hours]} { set val_hours 0 }

	    set left_clicks(top_scale_calc) [expr $left_clicks(top_scale_calc) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    set occupation_user 0
	    set occupation_user_total 0

	    set day_of_week [util_memoize [list db_string dow "select extract(dow from to_date($julian_date, 'J'))"]]
	    if {0 == $day_of_week} { set day_of_week 7 }

	    switch $otype {
            	person {

		    if { "planned_hours" == $calculation_mode } {

			# General settings 
                        set absence_key "$julian_date-$user_id"			

			# Start building cell 
			set cell_html "<div style='width:10px'>"

			# Accumulate "Planned Hours" over all tasks and create bar when planned hours > 0   
			set user_jdate_key "$user_id-$julian_date"

			# How many hours in total are planned for this user? 
			set acc_hours 0 	

			# Get planned Hours for this user 
			if { [info exists user_day_total_plannedhours_arr($user_jdate_key)] } {
				set acc_hours $user_day_total_plannedhours_arr($user_jdate_key)
			} else {
				set acc_hours 0
			}

                        # --------------------------------------------------------------------------------------------
                        # START: Calculate Totals
                        # --------------------------------------------------------------------------------------------

			# Set values to calculate totals for planned hours (Company Level) 
			if { [info exists totals_planned_hours_arr($column_ctr)] } {
			    set totals_planned_hours_arr($column_ctr) [expr $totals_planned_hours_arr($column_ctr) + $acc_hours]     
			} else {
			    set totals_planned_hours_arr($column_ctr) $acc_hours     			    
			}

			# Set values to calculate totals for planned hours department 
			if { [info exists totals_department_planned_hours_arr($column_ctr)] } {
			    set totals_department_planned_hours_arr($column_ctr) [expr $totals_department_planned_hours_arr($column_ctr) + $acc_hours]     
			} else {
			    set totals_department_planned_hours_arr($column_ctr) $acc_hours
			}

			# ns_log NOTICE "KHD: totals_department_planned_hours_arr for col: $column_ctr and user: $user_id -> [array get totals_department_planned_hours_arr]"
			
			# Accumulations planned hours user total  
			if { "0" != $acc_hours } {
			    set occupation_user_total [expr $occupation_user_total + $acc_hours]
			}
			
			# Accumulation absences 
			if {[info exists absences_hash($absence_key)]} {
			    set occupation_user [expr $occupation_user + $hours_per_absence]
			    set occupation_user_total [expr $occupation_user_total + $occupation_user]
			}

			# Only if this row shows an employee, we add the number of hours
			# to the total units for department & company  
			if { $row_shows_employee_p } {

			    if { ![info exists availability_user_perc] } { set availability_user_perc 100 }
			    if { "" == $availability_user_perc } { set availability_user_perc 100 }

			    set hours_availability_user [expr $hours_per_day * $availability_user_perc / 100 ]
			    set hours_availability_user [expr $hours_per_day_glob * $availability_user_perc / 100 ]

			    # Calculate company-total 
			    if { [info exists totals_availability_arr($column_ctr)] } {
				set totals_availability_arr($column_ctr) [expr $totals_availability_arr($column_ctr) + $hours_availability_user]
			    } else {
				set totals_availability_arr($column_ctr) $hours_availability_user
			    }		    

			    # Calculate Department-Total 
			    if { [info exists totals_department_availability_arr($column_ctr)] } {
				set totals_department_availability_arr($column_ctr) [expr $totals_department_availability_arr($column_ctr) + $hours_availability_user]
			    } else {
				set totals_department_availability_arr($column_ctr) $hours_availability_user
			    }		    
			}    
			# --------------------------------------------------------------------------------------------
			# END: Calculate Totals
			# --------------------------------------------------------------------------------------------


			# --------------------------------------------------------------------------------------------
			# START: Create Bars 
			# --------------------------------------------------------------------------------------------

			# Show bar for user rows (only weekdays) 
		        if { "6" != $day_of_week && "7" != $day_of_week  } {
 			        if { $row_shows_employee_p } {

				    # Bar is composed of multiple bars  

				    if { "0" != $acc_hours } { 
		   		        # if absence exist, add hours of absence  
					if {[info exists absences_hash($absence_key)]} { set acc_hours [expr $acc_hours + $hours_availability_user] }
					if { 0 == $hours_availability_user } {
					    set bar_value 0
					} else {
					    set bar_value [expr 100*$acc_hours/$hours_availability_user]
					}
					set bar_color [im_resource_mgmt_get_bar_color "gradient" $bar_value]
					append cell_html [im_resource_mgmt_resource_planning_cell "custom" $bar_value $bar_color $acc_hours "" 1]
					set cell_flag 1
				    }  
				    # Create bar in case an absence is found 
				    if {[info exists absences_hash($absence_key)]} {
					set bar_color [im_absence_mix_colors $absences_hash($absence_key)]
					set bar_value [lindex $absence_list $absences_hash($absence_key)]
					append cell_html [im_resource_mgmt_resource_planning_cell "custom" 100 $bar_color $bar_value "a" 1]
					set cell_flag 1
				    }

				    if { ![info exists absences_hash($absence_key)] && "0" == $acc_hours } {
					# Neither absences nor planned hours -> show full availability  
					set bar_color [im_resource_mgmt_get_bar_color "gradient" 0]
	                                append cell_html [im_resource_mgmt_resource_planning_cell "custom" 0 $bar_color 0 "" 1]
				    }
			        } else {
				    # Show Uni-color bar   

				    # Calculate hours for absences 
				    set hours_occupied_absence 0
	                            if { [info exists absences_hash($absence_key)] } {
					# There's an absence, calculate hours considering regular hours and employee availability 
					set hours_occupied_absence [expr $hours_per_day_glob * $availability_user_perc / 100 ]
				    } 
				    
				    # Total hours for absences and planned hours 
				    set hours_occupied_total [expr $hours_occupied_absence + $acc_hours]
	
				    if { 0 == $hours_occupied_total } {
				        set percent_hours_occupied 0				
				    } elseif { $hours_occupied_total > $hours_per_day_glob } { 
				         # Absences and planned hours are below the regular hours worked per day -> no availability 
				         set percent_hours_occupied 100				    
				    } else {
				         set percent_hours_occupied [expr 100 * $hours_occupied_total / $hours_per_day_glob]				    
				    }    
	
	                            set bar_color [im_resource_mgmt_get_bar_color "traffic_light" $percent_hours_occupied]

				    if { 0 == $hours_availability_user } {
                                        set perc_occupation_user_total 0
				    } else {
					set perc_occupation_user_total [expr 100 * $occupation_user_total / $hours_availability_user]
				    }
	                            append cell_html [im_resource_mgmt_resource_planning_cell "custom" $percent_hours_occupied $bar_color "$hours_occupied_total/$perc_occupation_user_total%" "" $limit_height]
				}
			}

			# --------------------------------------------------------------------------------------------
			# END: Writing bar 
			# --------------------------------------------------------------------------------------------

			# Set values to calculate totals for absences  
			if { [info exists totals_absences_arr($column_ctr)] } {
			    set totals_absences_arr($column_ctr) [expr $totals_absences_arr($column_ctr) + $occupation_user]     
			} else {
			    set totals_absences_arr($column_ctr) $occupation_user     			    
			}

			# Set values to calculate totals for absences department 
			if { [info exists totals_department_absences_arr($column_ctr)] } {
			    set totals_department_absences_arr($column_ctr) [expr $totals_department_absences_arr($column_ctr) + $occupation_user]     
			} else {
			    set totals_department_absences_arr($column_ctr) $occupation_user     			    
			}

			append cell_html "</div>"

		   } else {
			set cell_html "&nbsp;"    
		   }
		}   

	        default {
                    if { "percentage" == $calculation_mode } {
			set cell_html [util_memoize [list im_resource_mgmt_resource_planning_cell default $val "" "" "" $limit_height]]
		    } else {
			if { "6" != $day_of_week && "7" != $day_of_week  } {
			    # set cell_html [im_resource_mgmt_resource_planning_cell "custom" $val [im_resource_mgmt_get_bar_color $bar_type $val] "$val%" "" $limit_height]
			    if { $val_hours == 0  } {
				set cell_html ""
			    } else {
				set val_hours_output [format "%0.2f" $val_hours]
			        set cell_html ${val_hours_output}h
				set show_row_task_p 1
			    }
			} else {
			        set cell_html "&nbsp;"
			}
		    }
		}
	    }; # END SWITCH OTYPE

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

	    append department_row_html_tmp "<td $col_attrib>$cell_html</td>\n"

	    set left_clicks(top_scale_append) [expr $left_clicks(top_scale_append) + [clock clicks] - $last_click]
	    set last_click [clock clicks]

	    incr column_ctr

	} ; # end loop columns 
	
	# ns_log NOTICE "KHD: row_ctr: $row_ctr -> [array get totals_department_planned_hours_arr]"
    
	set left_clicks(top_scale) [expr $left_clicks(top_scale) + [clock clicks] - $last_click]
	set last_click [clock clicks]
        append department_row_html_tmp "</tr>\n"

	# ---------------------------------------------------------------
	# Decide if we need  to show this row 
	# ----------------------------------------------------------------
	
        switch $otype {
            person {
		append department_row_html $department_row_html_tmp
            }
            im_project {
		# Is user even member of this project?  
	        set user_is_project_member_p [db_string get_data "select count(*) from acs_rels where object_id_one = $oid and object_id_two =$user_id" -default 0]
		if { $user_is_project_member_p } {
		    # Does this project contain a task with planned hours for the given period where the user is a member of 
		    set show_this_row_sql "
				select count(*) from (
			                select
						distinct parent.project_id
			                from
                        			im_projects parent,
			                        im_projects child,
						im_timesheet_tasks t, 
						acs_rels rel
					where
						NOT EXISTS (select NULL from im_projects ip where ip.parent_id = child.project_id)
						and parent.project_status_id not in (77,78,79,81,82,83)
			                        -- and parent.parent_id is null
                        			and parent.end_date >= to_date(:start_date_request, 'YYYY-MM-DD')
			                        and parent.start_date <= to_date(:end_date_request, 'YYYY-MM-DD')
						and t.task_id = child.project_id
                        			and child.end_date >= to_date(:start_date_request, 'YYYY-MM-DD')
			                        and child.start_date <= to_date(:end_date_request, 'YYYY-MM-DD')
                        			and child.tree_sortkey
		                                between parent.tree_sortkey
                		                and tree_right(parent.tree_sortkey)
						and t.planned_units is not null 
						and t.task_id in (select object_id_one from acs_rels where object_id_two = :user_id)  
						and parent.project_id = $oid
					) isql
		    "
		    set found_task_p [db_string get_data $show_this_row_sql -default 0]
		    if { $found_task_p } {
			 append department_row_html $department_row_html_tmp	
		    }	 
		}
            }
            im_timesheet_task {
		if { $show_row_task_p } {
		    append department_row_html $department_row_html_tmp
		}
            }
            im_trans_task {
		append department_row_html $department_row_html_tmp
            }
            default {
		append department_row_html $department_row_html_tmp
            }
        }

	set department_row_html_tmp ""
	set show_row_task_p 0

	incr row_ctr

    }; # end loop user/project/task rows 

    # ad_return_complaint 1 "$totals_department_planned_hours_arr(0)<br>$totals_department_planned_hours_arr(1)<br>"

    append html [write_department_row \
	$department_row_html \
        $user_department_id_predecessor \
        [array get totals_department_absences_arr] \
        [array get totals_department_planned_hours_arr] \
        [array get totals_department_availability_arr] \
        $top_scale $top_vars $show_departments_only_p \
    ]

    # end loop rows 

    set clicks([clock clicks -milliseconds]) display_table_body

    # ----------------------------------------------------------------------------------------------------------------------------
    # Start header creation
    # ----------------------------------------------------------------------------------------------------------------------------

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
	
	# ------------------------------
	# Create Top Scale
	# ------------------------------

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

    # ------------------------------
    # Create row for COMPANY totals  
    # ------------------------------

    if { $calc_day_p && "planned_hours" == $calculation_mode} {
	append header "<tr class=rowtitle>\n"
	set col_l10n [lang::message::lookup "" "intranet-resource-management.Total" "Total"]
	append header "<td class=rowtitle colspan=$left_scale_size align=right>$col_l10n</td>\n"


	for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {
	    # Check if column is a weekend 
	    set julian_date [util_memoize [list im_date_components_to_julian $top_vars [lindex $top_scale $col]]]
	    set day_of_week [util_memoize [list db_string dow "select extract(dow from to_date($julian_date, 'J'))"]]
	    if {0 == $day_of_week} { set day_of_week 7 }    
    
	    if { "6" != $day_of_week && "7" != $day_of_week  } { 
		if { [info exists totals_planned_hours_arr($col)] } {
		    set total_planned_hours $totals_planned_hours_arr($col)
		} else {
		    set total_planned_hours 0
		}
		
		if { [info exists totals_absences_arr($col)] } {
		    set total_absences $totals_absences_arr($col)
		} else {
		    set total_absences 0
		}
		
	        if { [info exists totals_availability_arr($col)] } {
        	    set total_availability $totals_availability_arr($col)
	        } else {
        	    set total_availability 0
	        }

		# Calculate availability

		if { "0" != $total_availability } {
		    set val [expr 100 - [expr ($total_planned_hours+$total_absences) * 100 / $total_availability]] 
		} else {
		    set val 0
		}

		# set bar_chart [im_resource_mgmt_resource_planning_cell "custom" $val [im_resource_mgmt_get_bar_color $bar_type $val] "$val%" "" $limit_height ]

		# Create bar chart 
                set bar_color [im_resource_mgmt_get_bar_color "traffic_light" [expr $val - 100]]
                set bar_chart [im_resource_mgmt_resource_planning_cell "custom" 0 $bar_color [expr 100-$val] "" $limit_height]

	        append header "\t<td class='rowtitle' valign='bottom'>$bar_chart</td>\n"
        	# append header "\t<td class='rowtitle' valign='bottom'>$bar_chart<br>PH:$total_planned_hours<br>AB:$total_absences<br>AV:$total_availability</td>\n"
	    } else {
		append header "\t<td class='rowtitle' valign='bottom'>&nbsp;</td>\n"
	    }
	}
       append header "</tr>\n"
    }

    # -----------------------
    # End header creation  
    # ----------------------

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


    # ------------------------------------------------------------
    # Close the table
    #
    set html "<table cellspacing=3 cellpadding=3 valign=bottom>\n$header\n$html\n</table>\n"

    if {0 == $row_ctr} {
	set no_rows_msg [lang::message::lookup "" intranet-resource-management.No_rows_selected "
		No rows found.<br>
		Maybe there are no assignments of users to projects in the selected period?
	"]
	append html "<br><b>$no_rows_msg</b>\n"
    }

    set clicks([clock clicks -milliseconds]) close_table
    return "$html <br> $err_protocoll"
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


ad_proc -private write_department_row {
    	{ department_row_html }
        { department_id }
        { totals_department_absences_arr }
        { totals_department_planned_hours_arr }
        { totals_department_availability_arr }
        { top_scale }
        { top_vars }
        { show_departments_only_p }

} {
    - writes department row
} {
	set limit_height 1
	array set totals_department_absences_arr_loc $totals_department_absences_arr
        array set totals_department_planned_hours_arr_loc $totals_department_planned_hours_arr
        array set totals_department_availability_arr_loc $totals_department_availability_arr
	set row_html ""
        set department_name [db_string get_department_name "select cost_center_name from im_cost_centers where cost_center_id = $department_id" -default ""]
	append row_html "<tr><td><b>[lang::message::lookup "" intranet-reporting.SubTotalDepartment "Department"]: $department_name</b></td>"
	set ctr 0

	# Sanity check: Make sure we have a value vor each column
	foreach top_entry $top_scale {
	    if {![info exists totals_department_absences_arr_loc($ctr)]} { set totals_department_absences_arr_loc($ctr) 0 }
	    if {![info exists totals_department_planned_hours_arr_loc($ctr)]} { set totals_department_planned_hours_arr_loc($ctr) 0 }
	    if {![info exists totals_department_availability_arr_loc($ctr)]} { set totals_department_availability_arr_loc($ctr) 0 }

	    set julian_date [util_memoize [list im_date_components_to_julian $top_vars $top_entry]]
	    set day_of_week [util_memoize [list db_string dow "select extract(dow from to_date($julian_date, 'J'))"]]
	    if {0 == $day_of_week} { set day_of_week 7 }
	    if { "6" != $day_of_week && "7" != $day_of_week  } {
	            set total_department_occupancy [expr $totals_department_planned_hours_arr_loc($ctr) + $totals_department_absences_arr_loc($ctr)]
	            # Create bar showing availability
	            if { 0 == $total_department_occupancy } {
	                # no planned hours & no absences -> full availability
	                set bar_color [im_resource_mgmt_get_bar_color "traffic_light" 0]
			set par_hint "Abs.&Planned Hours:0 / Total Hours Dep. Avail.:$totals_department_availability_arr_loc($ctr) / Occ.:0%"
	                append row_html "<td>[im_resource_mgmt_resource_planning_cell "custom" 0 $bar_color "0/0%" "" $limit_height]</td>\n"
	            } else {
	                # We have absences and planned hours -> Calculate availability
	                set total_hours_department_occupancy [expr $totals_department_planned_hours_arr_loc($ctr) + $totals_department_absences_arr_loc($ctr)]
	                set percentage_occupancy [expr 100 * $total_hours_department_occupancy / $totals_department_availability_arr_loc($ctr)]
	                set bar_color [im_resource_mgmt_get_bar_color "traffic_light" $percentage_occupancy]
			set par_hint "Abs.&Planned Hours:$total_hours_department_occupancy / Total Hours Dep. Avail.:$totals_department_availability_arr_loc($ctr) / Occ.:$percentage_occupancy%"
	                append row_html "<td>[im_resource_mgmt_resource_planning_cell "custom" $percentage_occupancy $bar_color $par_hint "" $limit_height]</td>\n"
	            }
	    } else {
	            append row_html "<td></td>"
	    }
	    incr ctr	
	}
	 append row_html "</tr>"
	 # Write all rows for department (depeartment acc values & user)

	if { $show_departments_only_p } {
	    return $row_html
	} else {
	    return "$row_html$department_row_html"
	}
}

ad_proc -private hsv2hex {h s v} {
	# http://code.activestate.com/recipes/133527/ (
	# Arguments: h hue, s saturation, v value
	# Results: Returns an rgb triple from hsv
	if {$s <= 0.0} {
        	# achromatic
	        set v [expr {int($v)}]
        	return "$v $v $v"
    	} else {
        	set v [expr {double($v)}]
	        if {$h >= 1.0} { set h 0.0 }
        	set h [expr {6.0 * $h}]
	        set f [expr {double($h) - int($h)}]
        	set p [expr {int(256 * $v * (1.0 - $s))}]
	        set q [expr {int(256 * $v * (1.0 - ($s * $f)))}]
        	set t [expr {int(256 * $v * (1.0 - ($s * (1.0 - $f))))}]
	        set v [expr {int(256 * $v)}]
        	switch [expr {int($h)}] {
	            0 { set rgb "$v $t $p" }
        	    1 { set rgb "$q $v $p" }
	            2 { set rgb "$p $v $t" }
        	    3 { set rgb "$p $q $v" }
	            4 { set rgb "$t $p $v" }
        	    5 { set rgb" $v $p $q" }
        	}
    	}

	set rgb_list [split $rgb " "]
	return "\#[format %x [lindex $rgb_list 0]][format %x [lindex $rgb_list 1]][format %x [lindex $rgb_list 2]]"
}
