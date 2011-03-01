<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.4</version>
  </rdbms>
  <fullquery name="select_headers">
    <querytext>
      SELECT 
      column_id,
      view_id,
      column_name as label,
      lower(column_name) as name,
      column_render_tcl,
      extra_select,
      extra_from,
      extra_where,
      visible_for
      FROM im_view_columns
      WHERE view_id = (
        SELECT view_id FROM im_views WHERE view_name = :view_name)
      AND group_id is null
      ORDER BY sort_order

    </querytext>
  </fullquery>

  <fullquery name="select_tasks">
    <querytext>
      SELECT 
      p.project_id as task_id,
      t.priority as task_prio,
      p.project_name as task_name,
      t.planned_units as units,
      p.parent_id,
      im_name_from_id(p.parent_id) as project_name,
      p.percent_completed
      $extra_select
      FROM 
      im_projects p, 
      im_timesheet_tasks t
      $extra_from
      WHERE 
      t.task_id = p.project_id
      $restriction_clauses
      $extra_where
      ORDER BY $order_by_clause
    </querytext>
  </fullquery>



</queryset>
