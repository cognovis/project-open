# /packages/intranet-reporting/www/late-projects.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.




set current_user_id [im_require_login -no_redirect_p $no_redirect_p]
set page_title [lang::message::lookup "" intranet-preporting.Late_projects "Late Projects"]
set context_bar [im_context_bar $page_title]
set help "
	<b>Late Projects</b>:<br>
	The purpose of this project is to determine how many projects have been late.
	However, the definition of a 'late project' is difficult.
	<br>
	So this reports lists all 'main projects' in the system with start and end date, 
	plus several indicators of 'product activity', such as the last time that somebody 
	has logged hours on the project or when the last file was uploaded or downloaded
	from the project.
	<br>
	Any such activity after the 'End Date' could mean the project was late.
	<br>
	On the other hand, we show the date of the 'First Invoice'. This date should be
	after the 'Project End' date.
"


# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-late-projects"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set content ""
set cnt 0
set date_format "'YYYY-MM-DD'"


set sql "
	select
		substring(p.project_nr for 10) as project_nr,
		substring(p.project_name for 40) as project_name,
		to_char(p.start_date, $date_format) as start_date,
		(	select	to_char(max(day), $date_format) 
			from	im_hours h,
				im_projects s
			where	h.project_id = s.project_id
				and p.tree_sortkey = tree_root_key(s.tree_sortkey)
		) as last_hours,
		(	select	to_char(max(action_date), $date_format) 
			from	im_task_actions a,
				im_trans_tasks t,
				im_projects s
			where	a.task_id = t.task_id
				and t.project_id = s.project_id
				and p.tree_sortkey = tree_root_key(s.tree_sortkey)
		) as last_hours,
		to_char(p.end_date, $date_format) as end_date,
		(	select	to_char(min(effective_date), $date_format) 
			from	im_costs c,
				im_projects s
			where	c.cost_type_id = [im_cost_type_invoice]
				and c.project_id = s.project_id
				and p.tree_sortkey = tree_root_key(s.tree_sortkey)
		) as first_invoice,
		1
	from	
		im_projects p
	where
		p.parent_id is null
	order by project_id DESC	
"

set cols {
	"Nr"
	"Project"
	"Start<br> Date"
	"Last<br> Hours"
	"Last<br> Upload"
	"End<br> Date"
	"First<br> Invoice"
	1
}
set content [im_ad_hoc_query -format html -col_titles $cols $sql]
