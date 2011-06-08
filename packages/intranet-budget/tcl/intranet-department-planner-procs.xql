<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- @creation-date 2010-08-08 -->
<!-- @cvs-id $Id: intranet-department-planner-procs.xql,v 1.1 2010/08/05 18:24:03 po34demo Exp $ -->

<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>

  <fullquery name="im_department_planner_get_list_multirow.get_view">
    <querytext>
	select	view_id
	from	im_views
	where	view_name = :view_name
    </querytext>
  </fullquery>

  <fullquery name="im_department_planner_get_list_multirow.dynview_columns">
    <querytext>
	select	vc.*
	from	im_view_columns vc
	where	view_id = :view_id
	order by sort_order
    </querytext>
  </fullquery>
  
  <fullquery name="im_department_planner_get_list_multirow.tasks">
    <querytext>
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
		to_char(coalesce(child.start_date, main.start_date, now()), 'J') as task_start_date_julian,
		to_char(coalesce(child.end_date,main.end_date, now()), 'J') as task_end_date_julian,
		main.project_id as main_project_id,
		main.project_name as main_project_name,
		tree_level(child.tree_sortkey) - tree_level(main.tree_sortkey) as indent_level
	from
		im_projects main,
		im_projects child,
		im_timesheet_tasks task
	where	
		child.project_id = task.task_id and
		main.parent_id is null and
		child.tree_sortkey between main.tree_sortkey and tree_right(main.tree_sortkey)
        $criteria
	order by
		child.tree_sortkey
    </querytext>
  </fullquery>

  <fullquery name="im_department_planner_get_list_multirow.cost_centers">
    <querytext>
	select	cc.*,
		(select coalesce(sum(availability),0)
		from	cc_users u
			LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
		where	e.department_id = cc.cost_center_id and
			u.member_state = 'approved'
		) as employee_available_percent,
		(select coalesce(sum(hours),0)
		from	im_hours i,cc_users u
			LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
		where	e.department_id = cc.cost_center_id and
			u.member_state = 'approved'
			and i.user_id = u.user_id
                        and i.day between to_date(:report_start_date,'YYYY-MM-DD') and to_date(:report_end_date,'YYYY-MM-DD')
		) as employee_logged_hours,
		(
		select	count(*)
		from	im_projects main,
			im_projects child,
			im_timesheet_tasks task
		where	child.project_id = task.task_id and
			main.parent_id is null and
			child.tree_sortkey between main.tree_sortkey and tree_right(main.tree_sortkey) and
			cc.cost_center_id = task.cost_center_id
		) as task_count
	from	im_cost_centers cc
	where   cc.cost_center_status_id = 3101
	order by
		lower(cost_center_code)
    </querytext>
  </fullquery>
  
  <fullquery name="im_department_planner_get_list_multirow.left_dimension_projects">
    <querytext>
	select	main.*,
                coalesce(project_priority,0) as prio_sort,
		main.project_id as main_project_id,
	        im_category_from_id(project_status_id) as project_status,
		(select aux_int1 from im_categories where category_id = project_priority_op_id) as project_priority_op,
		(select aux_int1 from im_categories where category_id = project_priority_st_id) as project_priority_st	
	from	im_projects main
	where	parent_id is null and
		main.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
                (main.start_date between to_date(:report_start_date,'YYYY-MM-DD') and to_date(:report_end_date,'YYYY-MM-DD') or
                 main.end_date between to_date(:report_start_date,'YYYY-MM-DD') and to_date(:report_end_date,'YYYY-MM-DD')) and
                project_status_id in ([template::util::tcl_to_sql_list [im_sub_categories [list 76 71]]])
                $criteria
	order by
		prio_sort desc,
		lower(main.project_name)
    </querytext>
  </fullquery>
  


</queryset>
