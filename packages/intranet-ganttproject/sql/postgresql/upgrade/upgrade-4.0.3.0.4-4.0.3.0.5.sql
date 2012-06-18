-- upgrade-4.0.3.0.4-4.0.3.0.5.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql','');







-- Widget to select the Scheduling Constraint
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'gantt_scheduling_constraint_type', 'Gantt Scheduling Constraint Type', 'Gantt Scheduling Constraint Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Timesheet Task Scheduling Type"}}'
);


SELECT im_dynfield_attribute_new (
        'im_timesheet_task', 'scheduling_constraint_id', 'Scheduling Constraint', 'gantt_scheduling_constraint_type', 'integer', 'f', 0, 'f', 'im_timesheet_tasks'
);


SELECT im_dynfield_attribute_new (
        'im_timesheet_task', 'scheduling_constraint_date', 'Scheduling Constraint Date', 'date', 'date', 'f', 0, 'f', 'im_timesheet_tasks'
);

