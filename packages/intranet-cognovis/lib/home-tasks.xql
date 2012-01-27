<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.3</version>
  </rdbms>

  <fullquery name="select_tasks">
    <querytext>
        SELECT
        p.project_id as task_id,
        coalesce(t.priority,0) as priority,
        p.project_name as task_name,
        (p.end_date < now() and coalesce(p.percent_completed,0) < 100) as red_p,
        (parent.end_date < now()) as parent_red_p,
        p.start_date,
        p.end_date,
        p.project_type_id,
        t.planned_units,
        p.parent_id as project_id,
        im_name_from_id(p.parent_id) as project_name,
        p.percent_completed,
        p.reported_hours_cache as logged_hours
        FROM
        im_projects p,
        im_projects parent,
        im_timesheet_tasks t
        WHERE t.task_id = p.project_id
        AND p.parent_id = parent.project_id
        AND p.project_id in (select object_id_one from acs_rels where object_id_two = [ad_conn user_id])
        AND p.project_status_id in ([join [im_sub_categories $restrict_to_status_id] ","])
        AND [template::list::page_where_clause -name "tasks"]
	[template::list::orderby_clause -orderby -name "tasks"]
    </querytext>
  </fullquery>


  <fullquery name="tasks_pagination">
    <querytext>
        SELECT
        p.project_id as task_id,
        coalesce(t.priority,0) as priority,
        p.project_name as task_name,
        (p.end_date < now() and coalesce(p.percent_completed,0) < 100) as red_p,
        (parent.end_date < now()) as parent_red_p,
        p.start_date,
        p.end_date,
        p.project_type_id,
        t.planned_units,
        p.parent_id as project_id,
        im_name_from_id(p.parent_id) as project_name,
	coalesce(p.percent_completed,0) as percent_completed,
        p.reported_hours_cache as logged_hours
        FROM
        im_projects p,
        im_projects parent,
        im_timesheet_tasks t
        WHERE t.task_id = p.project_id
        AND p.parent_id = parent.project_id
        AND p.project_id in (select object_id_one from acs_rels where object_id_two = [ad_conn user_id])
        AND p.project_status_id in ([join [im_sub_categories $restrict_to_status_id] ","])
	[template::list::orderby_clause -orderby -name "tasks"]
    </querytext>
  </fullquery>


</queryset>
