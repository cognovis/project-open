# /packages/intranet-portfolio-management/tcl/intranet-portfolio-management-procs.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_portfolio_project_priority_1 {} { return 70000 }
ad_proc -public im_portfolio_project_priority_2 {} { return 70002 }
ad_proc -public im_portfolio_project_priority_3 {} { return 70004 }
ad_proc -public im_portfolio_project_priority_4 {} { return 70006 }
ad_proc -public im_portfolio_project_priority_5 {} { return 70008 }
ad_proc -public im_portfolio_project_priority_6 {} { return 70010 }
ad_proc -public im_portfolio_project_priority_7 {} { return 70012 }
ad_proc -public im_portfolio_project_priority_8 {} { return 70014 }
ad_proc -public im_portfolio_project_priority_9 {} { return 70016 }

ad_proc -public im_portfolio_department_planner_action_save {} { return 70100 }


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_department_planner_get_list_multirow {
    { -start_date "" }
    { -end_date "" }
    { -view_name "" }
} {
    Returns:
    - A multirow with the available days per cost center
    - A multirow with the required days per project and CC
    - A multirow representing the calculated report (i.e. 
      subtracting the project's required days from the CC
      available days)
    - A ListBuilder list configured to show the calculated
      report multirow.
} {
    # ---------------------------------------------------------------
    # Constants
    
    if {"" == $view_name} { set view_name "portfolio_department_planner_list" }
    
    set project_base_url "/intranet/projects/view"
    set this_base_url "/intranet-portfolio-management/department-planner/index"
    set date_format "'YYYY-MM-DD'"
    set content ""
    set hours_per_day [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter TimesheetHoursPerDay -default "8.0"]
    set work_days_per_year [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter TimesheetWorkDaysPerYear -default "210.0"]

    set report_start_date $start_date
    set report_end_date $end_date

    # Convert dates into julian format
    regexp {(....)-(..)-(..)} $report_start_date match year month day
    set report_start_date_julian [dt_ansi_to_julian $year $month $day]
    regexp {(....)-(..)-(..)} $report_end_date match year month day
    set report_end_date_julian [dt_ansi_to_julian $year $month $day]

    if {$report_start_date_julian >= $report_end_date_julian} {
	ad_return_complaint 1 "<b>Invalid start and end date</b>:<br>End date needs to be after start date."
	ad_script_abort
    }
    
    set report_duration_days [expr $report_end_date_julian - $report_start_date_julian]

    # Get the DynView view to show
    set view_id [db_string get_view {} -default 0]
    if {!$view_id } {
	ad_return_complaint 1 "<b>Unknown View Name</b>:<br>The view '$view_name' is not defined."
	ad_script_abort
    }

    # ---------------------------------------------------------------
    # Prepare DynView Dynamic Columns
    # ---------------------------------------------------------------
    
    set column_headers [list]
    set column_vars [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]
    set col_vars [list]
    set view_order_by_clause ""
    
    set col_ctr 0
    db_foreach dynview_columns {} {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	    lappend col_vars "col_$col_ctr"
	    if {"" != $extra_select} { lappend extra_selects $extra_select }
	    if {"" != $extra_from} { lappend extra_froms $extra_from }
	    if {"" != $extra_where} { lappend extra_wheres $extra_where }
	    if {"" != $order_by_clause &&
		$order_by==$column_name} {
		set view_order_by_clause $order_by_clause
	    }
	}
	incr col_ctr
    }
    

    # ---------------------------------------------------------------
    # Pull out everything about tasks and store in hash arrays
    # so that the information can be used easily when formatting
    # the HTML table.
    
    set error_html ""
    db_foreach tasks {} {
	
	ns_log Notice "department-planner: main=$main_project_name, child=$project_name"
	set task_url [export_vars -base "/intranet-timesheet2-tasks/new" {task_id}]
	
	# Calculate task_planned_days, depending on the tasks's UoM
	switch $uom_id {
	    320 {
		# Hour
		set task_planned_days [expr $planned_units / $hours_per_day]
	    }
	    321 {
		# Day
		set task_planned_days $planned_units
	    }
	    default {
		append error_html "<li><b>[lang::message::lookup "" intranet-portfolio-management.Invalid_UoM "Invalid Unit of Measure"]</b><br>
		We have found a task with the UoM '[im_category_from_id $uom_id]' which is neither a 'hour' nor a 'day'.
	    "
		continue
	    }
	}
	
	# Adjust planned days by the the already completed part.
	ns_log Notice "department-planner: task_planned_days=$task_planned_days"
	set task_planned_days [expr 1.0 * $task_planned_days * (100.0 - $percent_completed) / 100.0]
	ns_log Notice "department-planner: task_planned_days_uncompleted=$task_planned_days"
	
	# Calculate total calendar task length
	set task_len_calendar_days [expr $task_end_date_julian - $task_start_date_julian]
	if {$task_len_calendar_days <= 0} {
	    append error_html "<li><b>Invalid start and end date for task <a href=$task_url>$project_name</a></b>:<br>
		End date should be later then start date.<br>
		Start date: $start_date<br>
		End date: $end_date
	    "
	    continue
	}
       
	# Calculate start and end within the reporting period
	set startj $task_start_date_julian
	if {$report_start_date_julian > $task_start_date_julian} { set startj $report_start_date_julian }
	set endj $task_end_date_julian
	if {$report_end_date_julian > $task_end_date_julian} { set endj $report_end_date_julian }
	set task_len_calendar_days_within_period [expr $endj - $startj]
	ns_log Notice "department-planner: task_len_calendar_days_within_period=$task_len_calendar_days_within_period"
	
	# Adjust the planned days by the percentage in which they fall into the reporting period
	set $task_planned_days [expr 1.0 * $task_planned_days * $task_len_calendar_days_within_period / $task_len_calendar_days]
	ns_log Notice "department-planner: task_planned_days_uncompleted_in_interval=$task_planned_days"
	
	# Store the list of tasks with the main project
	set task_list {}
	if {[info exists task_list_hash($main_project_id)]} { set task_list $task_list_hash($main_project_id) }
	lappend task_list task_id
	set task_list_hash($main_project_id) $task_list
	
	# Sum up the adjusted task_planned_days per cost_center_id on the main project
	# Every main project entry consists of an array mapping cost centers to planned hours per cost center
	set planned_days_pairs {}
	if {[info exists planned_days_pairs_hash($main_project_id)]} { set planned_days_pairs $planned_days_pairs_hash($main_project_id) }
	array unset planned_days_hash
	array set planned_days_hash $planned_days_pairs
	set planned_days 0.0
	if {[info exists planned_days_hash($cost_center_id)]} { set planned_days $planned_days_hash($cost_center_id) }
	set planned_days_hash($cost_center_id) [expr $planned_days + $task_planned_days]
	set planned_days_pairs_hash($main_project_id) [array get planned_days_hash]
       
       
	# Store task information
	set task_level_hash($task_id) $indent_level
	set task_name_hash($task_id) $project_name
       
    }


    # ---------------------------------------------------------------
    # Top Dimension Cost Centers
    # Get the list of departments, together with the number of available 
    # employees. Store the list of department_ids in a list and the 
    # rest into hash arrays with the department_id as the key.

    template::multirow create cost_centers cost_center_id cost_center_name cost_center_label cost_center_code department_planner_days_per_year
    set cost_center_list {}
    db_foreach cost_centers {} {

	set available_days ""
	if {[info exists department_planner_days_per_year] && "" != $department_planner_days_per_year} {
	    set available_days $department_planner_days_per_year
	}

	# If there are no department_planner_days the check if employee_available_percent is set:
	if {"" == $available_days && "" != $employee_available_percent && 0 != $employee_available_percent} {
	    set available_days [expr round(10 * $employee_available_percent / 100.0 * $work_days_per_year * $report_duration_days / 365.0) / 10.0]
	}

	# Skip if there are no resources assigned nor capacity specified
	if { ("" == $available_days || 0 == $available_days) && $task_count == 0 } { 
	    continue 
	}
	
	lappend cost_center_ids $cost_center_id
	set cost_center_name_hash($cost_center_id) $cost_center_name
	set cost_center_code_hash($cost_center_id) $cost_center_code
	set cost_center_available_percent_hash($cost_center_id) $available_days

	# Append to Cost Centers multirow
	template::multirow append cost_centers $cost_center_id $cost_center_name $cost_center_label $cost_center_code $available_days
    }
    
   
    # ---------------------------------------------------------------
    # Top Dimension DynView Columns
    # Show the header of DynView and add the list of cost_centers
    # with their available days per year
    
    template::multirow create dynview_columns column_id column_ctr column_title
    set col_ctr 0
    foreach col $column_headers {
	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-portfolio-management.$col_txt $col]
	
	# Append to DynView Columns multirow
	template::multirow append dynview_columns $column_id $col_ctr $col_txt

	incr col_ctr
    }
   
    # ---------------------------------------------------------------
    # Left Dimension and List
    # Pull out the list of main projects and appy DynViews
    
    set extension_vars $col_vars
    foreach ccid $cost_center_ids {
	lappend extension_vars "cc_$ccid"
    }

    db_multirow -extend $extension_vars department_planner left_dimension_projects {} {
	
	set indent_html ""
	set gif_html ""
	
	# Append DynView for project
	set row_ctr 0
	foreach column_var $column_vars {
	    set cmd "set col_$row_ctr $column_var"
	    ns_log Notice "department-planner: cmd='$cmd'"
	    eval "$cmd"
	    incr row_ctr
	}
	
	# Append Columns per cost_center
	array unset planned_days_hash
	set planned_days_pairs {}
	if {[info exists planned_days_pairs_hash($project_id)]} { set planned_days_pairs $planned_days_pairs_hash($project_id) }
	array set planned_days_hash $planned_days_pairs
	
	foreach dept_id $cost_center_ids {
	    set planned_days 0.0
	    if {[info exists planned_days_hash($dept_id)]} { set planned_days $planned_days_hash($dept_id) }
	    set dept_task_url [export_vars -base "/intranet-timesheet2-tasks/index" {{project_id $main_project_id} {cost_center_id $dept_id}}]
	    set "cc_$dept_id" [expr round(10.0 * $planned_days) / 10.0]
	}
    }
    
    return $error_html
}

