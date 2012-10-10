# /packages/intranet-ganttproject/lib/ms-project-warning-component.tcl
#
# Copyright (C) 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

#
# Portlet Component
# Expects project_id variable passed from container
#
# project_id:	Variable defined by calling procedure

set org_project_id $project_id
set warnings_html ""
set return_url [im_url_with_query]

set skill_profile_group_id [im_profile::profile_id_from_name -profile "Skill Profile"]

# ---------------------------------------------------------------
# Get the main project
# ---------------------------------------------------------------

set main_project_id [db_string main_proj "
	select	min(main_p.project_id)
	from	im_projects main_p,
		im_projects p
	where	p.project_id = :org_project_id and
		main_p.tree_sortkey = tree_root_key(p.tree_sortkey)
" -default ""]

if {"" == $main_project_id} {
    ad_return_complaint 1 "ms-project-warning: Could not determine main-project for project #$org_project_id"
}


# ---------------------------------------------------------------
# Check which checks to ignore
# ---------------------------------------------------------------

set ignore_sql "
	select	gmpw.warning_key,
		coalesce(gmpw.project_id, 0) as ignore_project_id
	from	im_gantt_ms_project_warning gmpw
	where	user_id = [ad_get_user_id] and
		(gmpw.project_id is null or gmpw.project_id = :main_project_id)
"
db_foreach ignore_warnings $ignore_sql {
    set ignore_hash($warning_key) $ignore_project_id
}


# ---------------------------------------------------------------
# Check for tasks that start before the main project's start
# ---------------------------------------------------------------

set warning_key "fix-tasks-start-before-main-project"
if {![info exists ignore_hash($warning_key)]} {
    set sql "
	select	p.project_id as task_id,
		p.project_name as task_name,
		p.start_date as task_start_date,
		main_p.start_date as main_project_start_date
	from	im_projects main_p,
		im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
	where	main_p.project_id = :main_project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		p.start_date < main_p.start_date
	order by
		p.tree_sortkey
    "

    set task_list {}
    set new_main_start_date [db_string new_main_start_date "select min(task_start_date) from ($sql) t" -default ""]
    db_foreach tasks_start_before_project $sql {
	lappend task_list "<a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name ($task_start_date)</a>"
    }
    
    set task_list_len [llength $task_list]
    if {$task_list_len > 3} {
	set task_list [lrange $task_list 0 2]
	lappend task_list "... ([expr $task_list_len - 3] [lang::message::lookup "" intranet-ganttproject.more_tasks "more tasks"])"
    }
    
    set project_id $main_project_id
    if {[llength $task_list] > 0} {
	set task_html [join $task_list "</li>\n<li>"]
	append warnings_html "
	<div class=ms_project_warning_title>
	[lang::message::lookup "" intranet-ganttproject.Tasks_start_before_main_project "Tasks Starting Before the Main Project"]
	</div>
	<div class=ms_project_warning_body>
	[lang::message::lookup "" intranet-ganttproject.Tasks_start_before_main_project_msg "The following tasks start before the main project (%main_project_start_date%)."]
	[lang::message::lookup "" intranet-ganttproject.Tasks_start_before_main_project_msg1 "MS-Project will show a warning message when tasks start before the start of the project."]

	<ul>
	<li>$task_html</li>
	</ul>

	<form action=/intranet-ganttproject/fix-tasks-start-before-main-project method=GET>
	[export_form_vars project_id return_url]
	<select name=action>
	<option value=fix>[lang::message::lookup "" intranet-ganttproject.Set_the_start_of_main_project "Set the start of the main project to %new_main_start_date%"]</option>
	<option value=ignore_this>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue_for_this_project "Ignore the issue for this project"]</option>
	<option value=ignore_all>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue "Ignore the issue for all projects"]</option>
	</select>
	<input type=submit>
	</form>
	</div>
        "
    }
}




# ---------------------------------------------------------------
# Check for tasks with empty start- or end date
# ---------------------------------------------------------------

set warning_key "fix-tasks-with-empty-start-end-date"
if {![info exists ignore_hash($warning_key)]} {
    set sql "
	select	p.*, 
		t.*
	from	im_projects main_p,
		im_projects p,
		im_timesheet_tasks t
	where	main_p.project_id = :org_project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		p.project_id = t.task_id and
		-- empty start- and end date
		(p.start_date is null OR p.end_date is null) and
		-- Exclude projects that have children (only report leaf tasks)
		0 = (
			select	count(*)
			from	im_projects pp
			where	pp.parent_id = p.project_id
		)
	order by
		p.tree_sortkey
    "

    set task_html ""
    set task_ctr 0
    set task_skipped_ctr 0
    db_foreach task_without_start_constraint $sql {
	if {$task_ctr >= 3} {
	    incr task_skipped_ctr
	    continue 
	}
	append task_html "<tr>\n"
	append task_html "<td><input type=checkbox name=task_id.$task_id id=task_with_empty_start_end_date.$task_id checked></td>\n"
	append task_html "<td><a href=[export_vars -base "/intranet/projects/view" {{project_id $project_id}}]>$project_name</a></td>\n"
	append task_html "</tr>\n"
	incr task_ctr
    }
    
    if {$task_skipped_ctr > 0} {
	append task_html "<tr>\n"
	append task_html "<td><input type=checkbox name=task_id.0 id=task_with_empty_start_end_date.0 checked></td>\n"
	append task_html "<td>... ($task_skipped_ctr [lang::message::lookup "" intranet-ganttproject.more_tasks "more tasks"])</td>\n"
	append task_html "</tr>\n"   
    }
    
    if {[string length $task_html] > 0} {
	set task_header "<tr class=rowtitle>\n"
	append task_header "<td class=rowtitle><input type=checkbox name=_dummy onclick=acs_ListCheckAll('task_with_empty_start_end_date',this.checked) checked></td>\n"
	append task_header "<td class=rowtitle>[lang::message::lookup "" intranet-ganttproject.Task "Task"]</td>\n"
	append task_header "</tr>\n"
	
	set task_footer "
	<tr><td colspan=2>
	<select name=action>
	<option value=fix>[lang::message::lookup "" intranet-ganttproject.Force_start_on_start_date "Set missing start- and end dates to main project start- and end"]</option>
	<option value=ignore_this>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue_for_this_project "Ignore the issue for this project"]</option>
	<option value=ignore_all>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue "Ignore the issue for all projects"]</option>
	</select>
	<input type=submit>
	</td></tr>
        "

	set project_id $main_project_id
	append warnings_html "
	<div class=ms_project_warning_title>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_empty_start_end_date "Tasks With Empty Start- or End Date"]
	</div>
	<div class=ms_project_warning_body>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_empty_start_end_date_msg "
	The following tasks don't have have a start- or end date defined."]<br>
	<form action=/intranet-ganttproject/fix-tasks-with-empty-start-end-date>
	[export_form_vars project_id return_url]
	<table border=0>
	$task_header
	$task_html
	$task_footer
	</table>
	</form>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_empty_start_end_date_assign. "Please set the start- and end date of the tasks."]
	</div>
        "
    }
}



# ---------------------------------------------------------------
# Check for tasks without assignments
# ---------------------------------------------------------------


set warning_key "fix-tasks-without-assignments"
if {![info exists ignore_hash($warning_key)]} {
    set sql "
	select	t.*
	from	(select	p.project_id as task_id,
			p.project_name as task_name,
			p.tree_sortkey,
			sum(coalesce(bom.percentage, 0.0)) as percentage,
			sum(coalesce(t.planned_units, 0.0)) as planned_units
		from	im_projects main_p,
			im_projects p,
			im_timesheet_tasks t,
			acs_rels r,
			im_biz_object_members bom,
			users u
		where	t.task_id = p.project_id and
			main_p.project_id = :org_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
			r.object_id_one = p.project_id and
			r.object_id_two = u.user_id and
			r.rel_id = bom.rel_id and
			-- Exclude parent projects with sub-tasks
			0 = (select count(*) from im_projects pp where pp.parent_id = p.project_id)
		group by
			p.project_id, p.project_name, p.tree_sortkey
		) t
	where
		-- with no assigned resources
		t.percentage = 0.0 and
		-- with actual work to do
		t.planned_units > 0.0
	order by
		t.tree_sortkey
    "

    set task_list {}
    db_foreach tasks_start_before_project $sql {
	lappend task_list "<a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name</a>"
    }
    
    if {[llength $task_list] > 0} {
	set task_html [join $task_list "</li>\n<li>"]
	append warnings_html "
	<div class=ms_project_warning_title>
	[lang::message::lookup "" intranet-ganttproject.Tasks_Without_Assignments "Tasks Without Assignment"]
	</div>
	<div class=ms_project_warning_body>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_assignments_msg "The following tasks don't have any resources assigned.
	<ul><li>%task_html%</li></ul>"]<br>	
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_assignments_please_assign. "Please assign at least one resources to these tasks with a percentage > 0."]
	</div>
        "
    }
}


# ---------------------------------------------------------------
# Check for tasks with leading or trailing whitespaces
# ---------------------------------------------------------------


set warning_key "fix-tasks-with-white-spaces"
if {![info exists ignore_hash($warning_key)]} {
    set sql "
		select	p.project_id as task_id,
			p.project_name as task_name
		from	im_projects main_p,
			im_projects p
		where	main_p.project_id = :org_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
			p.project_name != trim(p.project_name)
    "

    set task_list {}
    db_foreach tasks_start_before_project $sql {
	lappend task_list "<a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name</a>"
    }
    
    if {[llength $task_list] > 0} {
	set task_html [join $task_list "</li>\n<li>"]
	append warnings_html "
	<div class=ms_project_warning_title>
	[lang::message::lookup "" intranet-ganttproject.Tasks_With_White_Spaces "Tasks With White Spaces"]
	</div>
	<div class=ms_project_warning_body>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_whitepaces_msg "The following tasks contain white spaces in front or after the project name.
	<ul><li>%task_html%</li></ul>"]<br>	
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_whitepaces_fix "Please remove the white spaces before and after the project name."]
	</div>
        "
    }
}



# ---------------------------------------------------------------
# Check for tasks without start constraint
# ---------------------------------------------------------------

set warning_key "fix-tasks-without-start-constraint"
if {![info exists ignore_hash($warning_key)]} {
    set sql "
	select	p.*, 
		t.*
	from	im_projects main_p,
		im_projects p,
		im_timesheet_tasks t
	where	main_p.project_id = :org_project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		p.project_id = t.task_id and
		-- the task starts after the main project
		p.start_date::date > (select start_date from im_projects where project_id = :main_project_id) and
		-- start as early as possible
		(t.scheduling_constraint_id = 9700 or t.scheduling_constraint_id is null) and
		0 = (
			select	count(*)
			from	im_timesheet_task_dependencies ttd
			where	ttd.task_id_one = p.project_id
		) and
		-- Exclude parent projects (only report leaf tasks)
		0 = (
			select	count(*)
			from	im_projects pp
			where	pp.parent_id = p.project_id
		) and
		-- Should have no parent with predecessors
		0 = (
			select	count(*)
			from	im_projects parent,
				im_timesheet_task_dependencies ttd
			where	parent.project_id = p.parent_id and
				ttd.task_id_one = parent.project_id
		)
	order by
		p.tree_sortkey
    "

    set task_html ""
    set task_ctr 0
    set task_skipped_ctr 0
    db_foreach task_without_start_constraint $sql {
	if {$task_ctr >= 3} {
	    incr task_skipped_ctr
	    continue 
	}
	append task_html "<tr>\n"
	append task_html "<td><input type=checkbox name=task_id.$task_id id=task_without_start_constraint.$task_id checked></td>\n"
	append task_html "<td><a href=[export_vars -base "/intranet/projects/view" {{project_id $project_id}}]>$project_name</a></td>\n"
	append task_html "</tr>\n"
	incr task_ctr
    }
    
    if {$task_skipped_ctr > 0} {
	append task_html "<tr>\n"
	append task_html "<td><input type=checkbox name=task_id.0 id=task_without_start_constraint.0 checked></td>\n"
	append task_html "<td>... ($task_skipped_ctr [lang::message::lookup "" intranet-ganttproject.more_tasks "more tasks"])</td>\n"
	append task_html "</tr>\n"   
    }
    
    set task_list_len [llength $task_list]
    if {$task_list_len > 3} {
	set task_list [lrange $task_list 0 2]
	lappend task_list "... ([expr $task_list_len - 3] more tasks)"
    }
    
    
    if {[string length $task_html] > 0} {
	set task_header "<tr class=rowtitle>\n"
	append task_header "<td class=rowtitle><input type=checkbox name=_dummy onclick=acs_ListCheckAll('task_without_start_constraint',this.checked) checked></td>\n"
	append task_header "<td class=rowtitle>[lang::message::lookup "" intranet-ganttproject.Task "Task"]</td>\n"
	append task_header "</tr>\n"
	
	set task_footer "
	<tr><td colspan=2>
	<select name=action>
	<option value=fix>[lang::message::lookup "" intranet-ganttproject.Force_start_on_start_date "Set a start constraint for the specified tasks"]</option>
	<option value=ignore_this>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue_for_this_project "Ignore the issue for this project"]</option>
	<option value=ignore_all>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue "Ignore the issue for all projects"]</option>
	</select>
	<input type=submit>
	</td></tr>
        "

	set project_id $main_project_id
	append warnings_html "
	<div class=ms_project_warning_title>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_start_constraint "Tasks Without Start-Constraint"]
	</div>
	<div class=ms_project_warning_body>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_start_constraint_msg "
	The following tasks don't have have a constraint to determine their start date.
        MS-Project will schedule these tasks to start together with the main project, unless you explicitely set a start constraint."]<br>
	<form action=/intranet-ganttproject/fix-tasks-without-start-constraint>
	[export_form_vars project_id return_url]
	<table border=0>
	$task_header
	$task_html
	$task_footer
	</table>
	</form>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_start_constraint_assign. "Please set a start constraint."]
	</div>
        "
    }
}


# ---------------------------------------------------------------
# Check for overallocation
# ---------------------------------------------------------------

set warning_key "fix-tasks-with-overallocation"
if {0 && ![info exists ignore_hash($warning_key)]} {
    set sql "
	select	t.*,
		greatest(percentage_skill_profiles, percentage_non_skill_profiles) as percentage
	from	(
		select	p.project_id as task_id,
			p.project_name as task_name,
			p.tree_sortkey,
			p.start_date,
			p.end_date,
			to_char(p.start_date, 'YYYY-MM-DD HH24:MI') as start_date_pretty,
			to_char(p.end_date, 'YYYY-MM-DD HH24:MI') as end_date_pretty,
			coalesce(t.planned_units, 0.0) as planned_units,
			t.uom_id,
			main_p.project_calendar,
			coalesce((
				select	sum(coalesce(bom.percentage, 0.0))
				from	acs_rels r,
					im_biz_object_members bom,
					users u
				where	r.object_id_one = p.project_id and
					r.object_id_two = u.user_id and
					r.rel_id = bom.rel_id and
					u.user_id in (
						select member_id from group_distinct_member_map 
						where group_id = :skill_profile_group_id
					)
			), 0.0) as percentage_skill_profiles,
			coalesce((
				select	sum(coalesce(bom.percentage, 0.0))
				from	acs_rels r,
					im_biz_object_members bom,
					users u
				where	r.object_id_one = p.project_id and
					r.object_id_two = u.user_id and
					r.rel_id = bom.rel_id and
					u.user_id not in (
						select member_id from group_distinct_member_map 
						where group_id = :skill_profile_group_id
					)
			), 0.0) as percentage_non_skill_profiles
		from	im_projects main_p,
			im_projects p,
			im_timesheet_tasks t
		where	t.task_id = p.project_id and
			main_p.project_id = :org_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		) t
	where	planned_units > 0.0 and
		percentage_non_skill_profiles + percentage_skill_profiles > 0.0
	order by
		tree_sortkey
    "

    set task_html ""
    set task_ctr 0
    set task_skipped_ctr 0
    db_foreach task_with_overallocation $sql {
	if {$task_ctr >= 30} {
	    incr task_skipped_ctr
	    continue 
	}

	# Empty start- and end dates are handled in other check
	if {"" == $start_date || "" == $end_date} { continue }

	if {"" == $project_calendar} { set project_calendar [im_ms_calendar::default] }
	set seconds_in_interval [im_ms_calendar::seconds_in_interval -start_date $start_date -end_date $end_date -calendar $project_calendar]
	set seconds_work [expr $seconds_in_interval * $percentage / 100.0]
	switch $uom_id {
	    320 { set seconds_uom [expr $planned_units * 3600] }
	    321 { set seconds_uom [expr $planned_units * 3600 * 8.0] }
	    default { set seconds_uom 0.0 }
	}

	# Check if there are timephased data available for this project
	# and use if available
	set seconds_in_timephased [im_ms_project_seconds_in_timephased -task_id $task_id]
	if {"" != $seconds_in_timephased} { set seconds_work $seconds_in_timephased }

	set overallocation_factor "undefined"
	catch { set overallocation_factor [expr $seconds_work / $seconds_uom] }

	if {"undefined" != $overallocation_factor} {
	    # Accept max. 10% overassignment, because of small rounding
	    # errors between %assigned and actual time spent by the resource
	    if {[expr abs($overallocation_factor - 1.0)] > 0.10} {


	ns_log Notice "ms-project-warning-component: fix-tasks-with-overallocation: seconds_work=$seconds_work, seconds_uom=$seconds_uom, seconds_in_timephased=$seconds_in_timephased, task_name=$task_name"

	    
		append task_html "<tr>\n"
		append task_html "<td><input type=checkbox name=task_id.$task_id id=task_with_overallocation.$task_id checked></td>\n"
		append task_html "<td align=left><a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name</a></td>\n"
		append task_html "<td>$start_date_pretty</td>\n"
		append task_html "<td>$end_date_pretty</td>\n"
		append task_html "<td align=right>[expr round(10.0 * $seconds_uom / 3600.0) / 10.0]</td>\n"
		append task_html "<td align=right>[expr round(10.0 * $seconds_work / 3600.0) / 10.0]</td>\n"
		append task_html "<td align=right>[expr round(10.0 * $percentage) / 10.0]</a></td>\n"
		append task_html "<td align=right>[expr round(1000.0 * $overallocation_factor) / 1000.0]</td>\n"
		append task_html "</tr>\n"
		incr task_ctr
	    }
	}
    }
    
    if {$task_skipped_ctr > 0} {
	append task_html "<tr>\n"
	append task_html "<td><input type=checkbox name=task_id.0 id=task_with_overallocation.0 checked></td>\n"
	append task_html "<td>... ($task_skipped_ctr [lang::message::lookup "" intranet-ganttproject.more_tasks "more tasks"])</td>\n"
	append task_html "</tr>\n"   
    }
    
    set task_list_len [llength $task_list]
    if {$task_list_len > 3} {
	set task_list [lrange $task_list 0 2]
	lappend task_list "... ([expr $task_list_len - 3] more tasks)"
    }
    
    
    if {[string length $task_html] > 0} {
	set task_header "<tr class=rowtitle>\n"
	append task_header "<td class=rowtitle align=center><input type=checkbox name=_dummy onclick=acs_ListCheckAll('task_with_overallocation',this.checked) checked></td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Task "Task"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Start "Start Date/Time"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.End "End Date/Time"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Sec_calc "Specified<br>Work (h)"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Sec_in_Int "Calculated<br>Work (h)"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Percentage "Assigned<br>Resources %"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Percentage "Overallocation<br>Factor"]</td>\n"
	append task_header "</tr>\n"
	
	set task_footer "
	<tr><td colspan=99>
	<select name=action>
	<option value=fix>[lang::message::lookup "" intranet-ganttproject.Reduce_resource_assignment "Reduce resource assignment % in order to balance the estimated work with duration"]</option>
	<option value=ignore_this>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue_for_this_project "Ignore the issue for this project"]</option>
	<option value=ignore_all>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue "Ignore the issue for all projects"]</option>
	</select>
	<input type=submit>
	</td></tr>
        "

	set project_id $main_project_id
	append warnings_html "
	<div class=ms_project_warning_title>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_overallocation "Tasks With Overallocation"]
	</div>
	<div class=ms_project_warning_body>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_overallocation_msg "
	The following tasks have more resources assigned then needed for the given work and duration (start- to end-date).
        MS-Project will shift the end-date of the tasks, unless you reduce the resource assignment here."]<br>
	<form action=/intranet-ganttproject/fix-tasks-with-overallocation>
	[export_form_vars project_id return_url]
	<table border=0 cellspacing=1 cellpadding=1>
	$task_header
	$task_html
	$task_footer
	</table>
	</form>
	[lang::message::lookup "" intranet-ganttproject.Tasks_with_overallocation_assign. "Please adjust the resources allocated."]
	</div>
        "
    }
}



# ---------------------------------------------------------------
# Check for Skill Profiles with not enough assignments
# ---------------------------------------------------------------

set warning_key "fix-tasks-with-unassigned-skill-profiles"
if {![info exists ignore_hash($warning_key)]} {

    set url_vars_set [ns_conn form]
    set filter_skill_profile_id [ns_set get $url_vars_set "filter_skill_profile_id"]
    set filter_skill_profile_sql ""
    if {"" != $filter_skill_profile_id} {
	set filter_skill_profile_sql "and p.project_id in (
		select	r.object_id_one
		from	acs_rels r
		where	r.object_id_two = :filter_skill_profile_id
	)"
    }

    set sql "
	select	t.*
	from	(
		select	p.project_id as task_id,
			p.project_name as task_name,
			p.tree_sortkey,
			to_char(p.start_date, 'YYYY-MM-DD HH24:MI') as start_date_pretty,
			to_char(p.end_date, 'YYYY-MM-DD HH24:MI') as end_date_pretty,
			t.*,
			im_biz_object_member__list(p.project_id) as assigned_users,
		
			coalesce((
			select	sum(coalesce(bom.percentage, 0.0))
			from	acs_rels r,
				im_biz_object_members bom,
				users u
			where	r.object_id_one = p.project_id and
				r.object_id_two = u.user_id and
				r.rel_id = bom.rel_id and
				u.user_id in (
					select member_id from group_distinct_member_map 
					where group_id = :skill_profile_group_id
				)
			), 0.0) as percentage_skill_profiles,

			coalesce((
			select	sum(coalesce(bom.percentage, 0.0) * coalesce(e.availability, 100) / 100)
			from	acs_rels r,
				im_biz_object_members bom,
				users u
				LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
			where	r.object_id_one = p.project_id and
				r.object_id_two = u.user_id and
				r.rel_id = bom.rel_id and
				u.user_id not in (
					select member_id from group_distinct_member_map 
					where group_id = :skill_profile_group_id
				)
			), 0.0) as percentage_non_skill_profiles

		from	im_projects main_p,
			im_projects p,
			im_timesheet_tasks t
		where	t.task_id = p.project_id and
			main_p.project_id = :org_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
			$filter_skill_profile_sql
		) t
	where	percentage_skill_profiles > 0.0 and
		percentage_non_skill_profiles < percentage_skill_profiles
	order by
		tree_sortkey
    "

    set task_html ""
    set task_ctr 0
    set task_skipped_ctr 0
    db_foreach task_with_unassiged_skill_profiles $sql {
	if {$task_ctr >= 30} {
	    incr task_skipped_ctr
	    continue 
	}

	# Separate the assigned resources into 1) skill profiles and 2) persons
	set assigned_skill_profiles {}
	set assigned_persons {}
	foreach tuple $assigned_users {
	    set user_id [lindex $tuple 0]
	    set role_id [lindex $tuple 1]
	    set perc [lindex $tuple 2]
	    if {"" == $perc} { continue }
	    if {[im_profile::member_p -profile "Skill Profile" -user_id $user_id]} {
		lappend assigned_skill_profiles $tuple
	    } else {
		lappend assigned_persons $tuple
	    }
	}

	# Create a list of assigned skill profiles
        set skill_profiles_list {}
	foreach tuple $assigned_skill_profiles {
	    set skill_profile_id [lindex $tuple 0]
	    set percent [lindex $tuple 2]
	    if {"" != $percent} { set percent [expr $percent+0.0] }
	    set string [im_name_from_user_id $skill_profile_id]
	    if {"" != $percent} { append string ":$percent%" }
	    lappend skill_profiles_list $string
	}

	# Create a list of assigned persons
        set persons_list {}
	foreach tuple $assigned_persons {
	    set skill_profile_id [lindex $tuple 0]
	    set percent [lindex $tuple 2]
	    set percent [expr $percent+0.0]
	    set string [im_name_from_user_id $skill_profile_id]
	    if {"" != $percent} { append string ":$percent%" }
	    lappend persons_list $string
	}

	foreach tuple $assigned_skill_profiles {
	    set skill_profile_id [lindex $tuple 0]
	    set skill_percent [lindex $tuple 2]
	    set rel_id [lindex $tuple 3]

	    # Required percent assignment in order to eqal out person vs. skill profiles
	    set percent [expr $percentage_skill_profiles - $percentage_non_skill_profiles]

	    append task_html "<tr>\n"
	    append task_html "<td><input type=checkbox name=checked.$rel_id id=task_with_overallocation.$rel_id checked></td>\n"
	    append task_html "<td align=left><a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name</a></td>\n"
	    append task_html "<td align=left>$start_date_pretty</td>\n"
	    append task_html "<td align=left>$end_date_pretty</td>\n"
	    append task_html "<td align=left>$planned_units [im_category_from_id $uom_id]</td>\n"
	    append task_html "<td>[acs_object_name $skill_profile_id]:$skill_percent%</td>\n"
	    append task_html "<td>[join $persons_list ", "]</td>\n"
	    append task_html "<td>[im_ganttproject_skill_profile_assignment_select -skill_profile_id $skill_profile_id user_id.$rel_id 0]</td>\n"
	    append task_html "<td><input type=input name=percent.$rel_id value=\"$percent\" size=6> <input type=hidden name=task_id.$rel_id value=\"$task_id\">  <input type=hidden name=rel_id.$rel_id value=\"$rel_id\"></td>\n"
	    append task_html "</tr>\n"
	    incr task_ctr
	    
	}
    }
    
    if {$task_skipped_ctr > 0} {
	append task_html "<tr>\n"
	append task_html "<td><input type=checkbox name=task_id.0 id=task_with_overallocation.0 checked></td>\n"
	append task_html "<td>... ($task_skipped_ctr [lang::message::lookup "" intranet-ganttproject.more_tasks "more tasks"])</td>\n"
	append task_html "</tr>\n"   
    }
    
    set task_list_len [llength $task_list]
    if {$task_list_len > 3} {
	set task_list [lrange $task_list 0 2]
	lappend task_list "... ([expr $task_list_len - 3] more tasks)"
    }
    
    
    if {[string length $task_html] > 0} {
	set task_header "<tr class=rowtitle>\n"
	append task_header "<td class=rowtitle align=center><input type=checkbox name=_dummy onclick=acs_ListCheckAll('task_with_overallocation',this.checked) checked></td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Task "Task Name"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Start "Start"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.End "End"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Hours "Hours"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Profile_Assigned_Percentage "Assigned<br>% Profiles"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Non_Profile_Assigned_Percentage "Assigned<br>% Users"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Select_User_Percent "Assign New User"]</td>\n"
	append task_header "<td class=rowtitle align=center>[lang::message::lookup "" intranet-ganttproject.Percent "%"]</td>\n"
	append task_header "</tr>\n"
	
	set task_footer "
	<tr><td colspan=99>
	<select name=action>
	<option value=fix>[lang::message::lookup "" intranet-ganttproject.Assign_persons_to_tasks "Assign persons to the tasks above"]</option>
	<option value=ignore_this>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue_for_this_project "Ignore the issue for this project"]</option>
	<option value=ignore_all>[lang::message::lookup "" intranet-ganttproject.Ignore_the_issue "Ignore the issue for all projects"]</option>
	</select>
	<input type=submit>
	</td></tr>
        "

	# Determina all Skill Profiles used in this project
	set skill_profile_sql "
		select distinct
			im_name_from_user_id(u.user_id) as user_name,
			u.user_id
		from	im_projects main_p,
			im_projects p,
			acs_rels r,
			users u
		where	main_p.project_id = :org_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
			r.object_id_one = p.project_id and
			r.object_id_two = u.user_id and
			u.user_id in (
				select member_id from group_distinct_member_map 
				where group_id = (select group_id from groups where group_name = 'Skill Profile')
			)
		order by
			user_name, user_id
	"

	set skill_profile_tuples [db_list_of_lists skill_profile_filter $skill_profile_sql]
	set skill_profile_tuples [linsert $skill_profile_tuples 0 [list "" ""]]
	set skill_profile_select [im_select -ad_form_option_list_style_p 1 -translate_p 0 filter_skill_profile_id $skill_profile_tuples $filter_skill_profile_id]


	set project_id $main_project_id
	append warnings_html "
	<table>
	<tr><td>
		<div class=ms_project_warning_title>
		[lang::message::lookup "" intranet-ganttproject.Tasks_with_open_assignments "Tasks With Open Assignments"]
		</div>
		<div class=ms_project_warning_body>
		[lang::message::lookup "" intranet-ganttproject.Tasks_with_missing_assignments_msg "
		The following tasks have been assigned to a Skill Profile, but you haven't yet specfied
		which persons should perform the work."]<br>
		</div>
	</td><td>
		<form action=/intranet/projects/view method=GET>
		[export_form_vars project_id]
		<table>
		<tr>
		<td>[lang::message::lookup "" intranet-ganttproject.Filter "Filter"]</td>
		<td>$skill_profile_select</td>
		<td><input type=submit></td>
		</tr>
		</table>
		</form>
	</td></tr>
	</table>

	<div class=ms_project_warning_body>
	<form action=/intranet-ganttproject/$warning_key method=POST>
	[export_form_vars project_id return_url]
	<table border=0 cellspacing=1 cellpadding=1>
	$task_header
	$task_html
	$task_footer
	</table>
	</form>
	</div>
        "
    }
}



# ---------------------------------------------------------------
# Explain why this warning portlet is necessary
# ---------------------------------------------------------------

if {"" != $warnings_html} {
    set warnings_html "
	[lang::message::lookup "" intranet-ganttproject.Warnings_portlet_msg "
	Microsoft (MS-) Project 2003-2010 may behave in unexpected ways when you try to export your
	project schedule. 
	This portlet will issue warnings and offer fixes if tasks are likely to be affected by the
	MS-Project 'scheduling engine'.
	"]
	$warnings_html
    "
}
