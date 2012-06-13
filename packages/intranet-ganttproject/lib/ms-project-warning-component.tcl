# Portlet Component
# Expects project_id variable passed from container
#
# project_id:	Variable defined by calling procedure

set main_project_id $project_id
set warnings_html ""
set return_url [im_url_with_query]


# ---------------------------------------------------------------
# Check for tasks that start before the main project's start
# ---------------------------------------------------------------

set sql "
	select	p.project_id as task_id,
		p.project_name as task_name,
		p.start_date::date as task_start_date,
		main_p.start_date::date as main_project_start_date
	from	im_projects main_p,
		im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
	where	main_p.project_id = :main_project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		p.start_date < main_p.start_date
"

set task_list {}
set new_main_start_date [db_string new_main_start_date "select min(task_start_date) from ($sql) t" -default ""]
db_foreach tasks_start_before_project $sql {
    lappend task_list "<a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name ($task_start_date)</a>"
}

if {[llength $task_list] > 0} {
    set task_html [join $task_list "</li>\n<li>"]
    set fix_url [export_vars -base "/intranet-ganttproject/fix-tasks-start-before-main-project" {project_id return_url}]
    append warnings_html "
	<li>
	<b><font color=red>
	[lang::message::lookup "" intranet-ganttproject.Tasks_start_before_main_project "Tasks starting before the main project"]</b></font>:<br>
	[lang::message::lookup "" intranet-ganttproject.Tasks_start_before_main_project_msg "The following tasks start before the main project (%main_project_start_date%):<br><ul><li>%task_html%</li></ul>"]<br>
        [lang::message::lookup "" intranet-ganttproject.Tasks_start_before_main_project_fix "Please <a href=%fix_url%>click here to fix there issue</a> by moving the start of the main project to %new_main_start_date%."]
    "
}




# ---------------------------------------------------------------
# Check for tasks without assignments
# ---------------------------------------------------------------

set sql "
select	t.*
from	(select	p.project_id as task_id,
		p.project_name as task_name,
		sum(coalesce(bom.percentage, 0.0)) as percentage,
		sum(coalesce(t.planned_units, 0.0)) as planned_units
	from	im_projects main_p,
		im_projects p,
		im_timesheet_tasks t,
		acs_rels r,
		im_biz_object_members bom,
		users u
	where	t.task_id = p.project_id and
		main_p.project_id = :main_project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		r.object_id_one = p.project_id and
		r.object_id_two = u.user_id and
		r.rel_id = bom.rel_id
	group by
		p.project_id, p.project_name
	) t
where	t.percentage = 0.0 and
	t.planned_units > 0.0
"


set task_list {}
db_foreach tasks_start_before_project $sql {
    lappend task_list "<a href=[export_vars -base "/intranet/projects/view" {{project_id $task_id}}]>$task_name</a>"
}

if {[llength $task_list] > 0} {
    set task_html [join $task_list "</li>\n<li>"]
    append warnings_html "
	<li>
	<b><font color=red>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_assignments "Tasks without assignment"]</b></font>:<br>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_assignments_msg "The following tasks don't have any resources assigned.
	<ul><li>%task_html%</li></ul>"]<br>	
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_assignments_please_assign. "Please assign at least one resources to these tasks with a percentage > 0."]
    "
}





# ---------------------------------------------------------------
# Check for tasks without start constraint
# ---------------------------------------------------------------

set sql "
	select	p.*, 
		t.*
	from	im_projects main_p,
		im_projects p,
		im_timesheet_tasks t
	where	main_p.project_id = :main_project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
		p.project_id = t.task_id and
		-- the task starts after the main project
		p.start_date::date > main_p.start_date::date and
		-- start as early as possible
		(t.scheduling_constraint_id = 9700 or t.scheduling_constraint_id is null)
"

set task_html ""
db_foreach task_without_start_constraint $sql {
    append task_html "<tr>\n"
    append task_html "<td><input type=checkbox name=task_id.$task_id id=task_id.$task_id></td>\n"
    append task_html "<td><a href=[export_vars -base "/intranet/projects/view" {{project_id $project_id}}]>$project_name</a></td>\n"
    append task_html "</tr>\n"
}

if {[string length $task_html] > 0} {
    set task_header "<tr class=rowtitle>\n"
    append task_header "<td class=rowtitle><input type=checkbox></td>\n"
    append task_header "<td class=rowtitle>[lang::message::lookup "" intranet-ganttproject.Task "Task"]</td>\n"
    append task_header "</tr>\n"

    set task_footer "
	<tr><td colspan=2>
	<select name=action><option name=start_on>[lang::message::lookup "" intranet-ganttproject.Force_start_on_start_date "Force start on start date"]</option></select>
	<input type=submit>
	</td></tr>"

    append warnings_html "
	<li>
	<b><font color=red>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_start_constraint "Tasks without start_constraint"]</b></font>:<br>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_start_constraint_msg "
	The following tasks don't have have a constraint to determine their start.
        MS-Project will schedule these tasks to start together with the main project."]<br>
	<form action=/intranet-ganttprojects/fix-tasks-withtou-start-constraint>
	<table border=0>
	$task_header
	$task_html
	$task_footer
	</table>
	</form>
	[lang::message::lookup "" intranet-ganttproject.Tasks_without_start_constraint_assign. "Please set a start constraint."]
	</li>
    "
}

