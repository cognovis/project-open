-- upgrade-4.0.3.0.3-4.0.3.0.4.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');

-- translate task types

update im_timesheet_tasks set task_type_id = 9500 where task_type_id = 100 or task_type_id is null;

update im_dynfield_widgets set widget = 'im_category_tree' where widget_name = 'task_status' or widget_name = 'task_type';