-- upgrade-0.5d4-0.5d5.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d4-0.5d5.sql','');


-- Introduce variable_name field
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count from im_view_columns
	where	view_id = 950;
        IF v_count > 0 THEN return 0; END IF;

-- Create im_view for timesheet_tasks
insert into im_views (view_id, view_name, visible_for) values (950, 'im_timesheet_task_home_list', 'view_projects');


-- Task_id
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92100,950,NULL, 'TaskID','<center>@tasks.task_id;noquote@</center>','','',0,'');

-- Task Name
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92101,950,NULL,'Name','<nobr>@tasks.gif_html;noquote@<a href=@tasks.object_url;noquote@>@tasks.task_name;noquote@</a></nobr>','','',1,'');

-- Planned Units
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92102,950,NULL,'PLN','<center><a href=@tasks.object_url;noquote@>@tasks.planned_units;noquote@</a></center>','','',2,'');

-- Start Date
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92103,950,NULL,'Start', '<center>@tasks.start_date;noquote@</center>','','',3,'');

-- End Date
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92104,950,NULL,'End', '<center>@tasks.end_date;noquote@</center>','','',4,'');

-- Log Hours
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92105,950,NULL,'Log','<center><a href=@tasks.timesheet_report_url;noquote@">@tasks.logged_hours;noquote@</a></center>','','',5,'');

-- Task Prio
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92106,950,NULL, 'Prio','<center>@tasks.task_prio;noquote@</center>','','',6,'');

-- Checkbox
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (92107,950,NULL,'<input type=checkbox name=_dummy onclick=acs_ListCheckAll(\"tasks\",this.checked)>','<input type=checkbox name=task_id.@tasks.task_id@ id=tasks,@tasks.task_id@>', '', '', 7, '');

        return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();

