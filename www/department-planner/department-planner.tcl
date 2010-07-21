# /packages/intranet-project-portfolio-mgmt/www/department-planner/department-planner.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows a portfolio of projects ordered by priority.
    The assigned work days to the project's tasks are deduced from the
    resources available per cost_center.

    Note: There is only a single portfolio here, as the cost center's 
    resources are not separated per portfolio.

    @author frank.bergmann@project-open.com
} {
    { start_date "" }
    { end_date "" }
    { view_name "portfolio_department_planner_list" }
    { order_by "" }
}


# ---------------------------------------------------------------
# Title
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-portfolio-mgmt.Department_Planner "Department Planner"]
set context_bar [im_context_bar $page_title]
set help "
	<b>Department Planner</b>:<br>
	This planner identifies bottlenecks in the execution of projects.<br>
	The report list lists projects according to their priority.
	It shows in the first line the available work days per department for
	the time period and subtracts line by line the required work days per
	project.
"

# ---------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set current_user_id [im_require_login]
set menu_label "reporting-department-planner"
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']
set read_p "t"
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

set project_base_url "/intranet/projects/view"
set this_base_url "/intranet-portfolio-management/department-planner/department-planner"
set date_format "'YYYY-MM-DD'"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set content ""
set hours_per_day 8.0


# Get the DynView view to show
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
    ad_return_complaint 1 "<b>Unknown View Name</b>:<br>The view '$view_name' is not defined."
    ad_script_abort
}


# ---------------------------------------------------------------
# Start and End Date
# ---------------------------------------------------------------

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

db_1row todays_date "
select
        to_char(sysdate::date, 'YYYY') as todays_year,
        to_char(sysdate::date, 'MM') as todays_month,
        to_char(sysdate::date, 'DD') as todays_day
from dual
"

if {"" == $start_date} { set start_date "$todays_year-01-01" }
if {"" == $end_date} { set end_date "[expr $todays_year+1]-01-01" }

# Convert dates into julian format
db_1row julian_start_end "
	select	to_char(:start_date::date, 'J') as start_date_julian,
		to_char(:end_date::date, 'J') as end_date_julian
"

if {$start_date_julian >= $end_date_julian} {
    ad_return_complaint 1 "<b>Invalid start and end date</b>:<br>End date needs to be after start date."
    ad_script_abort
}

# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

set filter_html "
	<form method=GET name=filter action='$this_base_url'>
	[export_form_vars ]
	<table border=0 cellpadding=0 cellspacing=1>
"

append filter_html "
	<tr>
	<td class=form-label>[_ intranet-core.Start_Date]</td>
        <td class=form-widget><input type=textfield name=start_date value=$start_date></td>
	</tr>
	<tr>
	<td class=form-label>[lang::message::lookup "" intranet-core.End_Date "End Date"]</td>
        <td class=form-widget><input type=textfield name=end_date value=$end_date></td>
	</tr>
"

append filter_html "
  <tr>
    <td class=form-label></td>
    <td class=form-widget>
	  <input type=submit value='[lang::message::lookup "" intranet-core.Action_Go "Go"]' name=submit>
    </td>
  </tr>
"

append filter_html "</table>\n</form>\n"

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
		[lang::message::lookup "" intranet-core.Filter "Filter"]
        	</div>
            	$filter_html
      	</div>
      <hr/>
"


# ---------------------------------------------------------------
# Prepare DynView Dynamic Columns
# ---------------------------------------------------------------

set column_headers [list]
set column_vars [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]
set view_order_by_clause ""

set column_sql "
	select	vc.*
	from	im_view_columns vc
	where	view_id = :view_id
	order by  sort_order
"
db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
        lappend column_headers "$column_name"
        lappend column_vars "$column_render_tcl"
        if {"" != $extra_select} { lappend extra_selects $extra_select }
        if {"" != $extra_from} { lappend extra_froms $extra_from }
        if {"" != $extra_where} { lappend extra_wheres $extra_where }
        if {"" != $order_by_clause &&
            $order_by==$column_name} {
            set view_order_by_clause $order_by_clause
        }
    }
}


# ---------------------------------------------------------------
# Pull out everything about tasks and store in hash arrays
# so that the information can be used easily when formatting
# the HTML table.
# ---------------------------------------------------------------

set error_html ""
set tasks_sql "
	select	
		child.project_id,
		child.project_name,
		child.project_nr,
		child.start_date,
		child.end_date,
		coalesce(child.percent_completed, 0.0::float) as percent_completed,
		task.task_id,
		task.uom_id,
		task.cost_center_id,
		coalesce(task.planned_units, 0.0::float) as planned_units,
		to_char(coalesce(child.start_date, parent.start_date, now()), 'J') as task_start_date_julian,
		to_char(coalesce(child.end_date,parent.end_date, now()), 'J') as task_end_date_julian,
		parent.project_id as parent_project_id,
		tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as indent_level
	from
		im_projects parent,
		im_projects child,
		im_timesheet_tasks task
	where	
		child.project_id = task.task_id and
		parent.parent_id is null and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
	order by
		child.tree_sortkey
"

db_foreach tasks $tasks_sql {

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
    set task_planned_days [expr $task_planned_days * (100.0 - $percent_completed)]

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
    if {$start_date_julian > $task_start_date_julian} { set startj $start_date_julian }
    set endj $task_end_date_julian
    if {$end_date_julian > $task_end_date_julian} { set endj $end_date_julian }
    set task_len_calendar_days_within_period [expr $endj - $startj]

    # Adjust the planned days by the percentage in which they fall into the reporting period
    set $task_planned_days [expr 1.0 * $task_planned_days * $task_len_calendar_days_within_period / $task_len_calendar_days]

    # Store the list of tasks with the main project
    set task_list {}
    if {[info exists task_list_hash($parent_project_id)]} { set task_list $task_list_hash($parent_project_id) }
    lappend task_list task_id
    set task_list_hash($parent_project_id) $task_list

    # Sum up the adjusted task_planned_days per cost_center_id on the parent project
    # Every parent project entry consists of an array mapping cost centers to planned hours per cost center
    set planned_days_pairs {}
    if {[info exists planned_days_pairs_hash($parent_project_id)]} { set planned_days_pairs $planned_days_pairs_hash($parent_project_id) }
    array unset planned_days_hash
    array set planned_days_hash $planned_days_pairs
    set planned_days 0.0
    if {[info exists planned_days_hash($cost_center_id)]} { set planned_days $planned_days_hash($cost_center_id) }
    set planned_days_hash($cost_center_id) [expr $planned_days + $task_planned_days]
    set planned_days_pairs_hash($parent_project_id) [array get planned_days_hash]


    # Store task information
    set task_level_hash($task_id) $indent_level
    set task_name_hash($task_id) $project_name
    
}


# ---------------------------------------------------------------
# Top Dimension
#
# Get the list of departments, together with the number of available 
# employees. Store the list of department_ids in a list and the 
# rest into hash arrays with the department_id as the key.
# ---------------------------------------------------------------

set cost_center_sql "
	select	cc.*,
		(select sum(coalesce(availability,0))
		from	cc_users u
			LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
		where	e.department_id = cc.cost_center_id
		) as employee_available_percent
	from	im_cost_centers cc
	order by
		lower(cost_center_code)
"

set cost_center_list {}
db_foreach cost_centers $cost_center_sql {

    # Skip if there are no resources to assign...
    if {"" == $employee_available_percent || 0 == $employee_available_percent} { continue }

    lappend cost_center_ids $cost_center_id
    set cost_center_name_hash($cost_center_id) $cost_center_name
    set cost_center_code_hash($cost_center_id) $cost_center_code
    set cost_center_available_percent_hash($cost_center_id) $employee_available_percent
}


# ---------------------------------------------------------------
# Header
#
# Show the header of DynView and add the list of cost_centers
# with their available days per year
# ---------------------------------------------------------------

set ctr 0
set header_html "<tr class=rowtitle>\n"
set first_html "<tr class=rowtitle>\n"

foreach col $column_headers {
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-portfolio-management.$col_txt $col]
    if { [string compare $order_by $col] == 0 } {
        append header_html "<td class=rowtitle>$col_txt</td>\n"
    } else {
        append header_html "<td class=rowtitle><a href=\"${this_base_url}order_by=[ns_urlencode $col]\">$col_txt</a></td>\n"
    }

    # Add empty spaces for the first row that contains the available resources per cost center
    append first_html "<td class=rowtitle>&nbsp;</td>\n"
}

foreach cc_id $cost_center_ids {
    append header_html "<td class=rowtitle>$cost_center_name_hash($cc_id)</td>\n"
    append first_html "<td class=rowtitle>$cost_center_available_percent_hash($cc_id)</td>\n"
}
append header_html "</tr>\n"
append first_html "</tr>\n"

# increment the row counter
incr ctr


# ---------------------------------------------------------------
# Left Dimension
#
# Pull out the list of main projects and appy DynViews
# ---------------------------------------------------------------

set project_sql "
	select	parent.*
	from	im_projects parent
	where	parent_id is null and
		parent.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
		parent.project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
	order by
		lower(parent.project_name)
"

set body_html ""
db_foreach left_dimension $project_sql {

    # Start a new table row.
    set row_html "<tr$bgcolor([expr $ctr % 2])>\n"

    set indent_html ""
    set gif_html ""

    # Append DynView for project
    foreach column_var $column_vars {
        append row_html "\t<td valign=top>"
        set cmd "append row_html $column_var"
        eval "$cmd"
        append row_html "</td>\n"
    }

    # Append Columns per cost_center
    foreach dept_id $cost_center_ids {
	append row_html "<td>$dept_id</td>\n"
    }

    append row_html "</tr>\n"
    append body_html $row_html   
    incr ctr
}



