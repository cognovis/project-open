# Portlet Component
# Expects project_id variable passed from container
#
# project_id:	Variable defined by calling procedure

set org_project_id $project_id
set warnings_html ""
set return_url [im_url_with_query]

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
    
    set task_list_len [llength $task_list]
    if {$task_list_len > 3} {
	set task_list [lrange $task_list 0 2]
	lappend task_list "... ([expr $task_list_len - 3] more tasks)"
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
if {![info exists ignore_hash($warning_key)]} {
    set sql "
	select	t.*
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
			(select	sum(coalesce(bom.percentage, 0.0))
			from	acs_rels r,
				im_biz_object_members bom,
				users u
			where	r.object_id_one = p.project_id and
				r.object_id_two = u.user_id and
				r.rel_id = bom.rel_id
			) as percentage
		from	im_projects main_p,
			im_projects p,
			im_timesheet_tasks t
		where	t.task_id = p.project_id and
			main_p.project_id = :org_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
		) t
	where	planned_units > 0.0 and
		percentage > 0.0
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

	set seconds_in_interval [im_ms_calendar::seconds_in_interval -start_date $start_date -end_date $end_date -calendar [im_ms_calendar::default]]
	set seconds_work [expr $seconds_in_interval * $percentage / 100.0]

	switch $uom_id {
	    320 { set seconds_uom [expr $planned_units * 3600] }
	    321 { set seconds_uom [expr $planned_units * 3600 * 8.0] }
	    default { set seconds_uom 0.0 }
	}
	set overallocation_factor "undefined"
	catch { set overallocation_factor [expr $seconds_work / $seconds_uom] }

	if {"undefined" != $overallocation_factor} {
	    if {[expr abs($overallocation_factor - 1.0)] > 0.001} {
	    
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
