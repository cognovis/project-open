-- upgrade-4.0.1.0.0-4.0.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql','');


-- Does the user have the right to edit task estimates?
select acs_privilege__create_privilege(
	'edit_timesheet_task_estimates',
	'Edit Timesheet Task',
	'Edit Timesheet Task'
);
select acs_privilege__add_child('admin', 'edit_timesheet_task_estimates');
select im_priv_create('edit_timesheet_task_estimates', 'Employees');

