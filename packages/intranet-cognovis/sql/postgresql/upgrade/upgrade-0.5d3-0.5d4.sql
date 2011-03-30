-- upgrade-0.5d3-0.5d4.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d3-0.5d4.sql','');

delete from im_biz_object_urls
where object_type = 'im_timesheet_task';

insert into im_biz_object_urls (object_type, url_type, url) values ('im_timesheet_task','view','/intranet-cognovis/tasks/view?task_id=');
insert into im_biz_object_urls (object_type, url_type, url) values ('im_timesheet_task','edit','/intranet-cognovis/tasks/view?form_mode=edit&task_id=');

update im_view_columns set column_render_tcl = '"<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a>"' where column_id = 91101;

update im_view_columns set column_render_tcl = '"<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a>"' where column_id = 91002;


