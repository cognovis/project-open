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


update im_categories
set category_type = 'Intranet Timesheet Task Fixed Task Type'
where category_type = 'Intranet Timesheet Task Effort Driven Type';

-- Widget to select the Fixed Task Type
SELECT im_dynfield_widget__new (
        null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
        'gantt_fixed_task_type', 'Gantt Fixed Task Type', 'Gantt Fixed Task Type',
        10007, 'integer', 'im_category_tree', 'integer',
        '{custom {category_type "Intranet Timesheet Task Fixed Task Type"}}'
);

SELECT im_dynfield_attribute_new (
        'im_timesheet_task', 'effort_driven_type_id', 'Fixed Task Type', 'gantt_fixed_task_type', 'integer', 'f', 0, 'f', 'im_timesheet_tasks'
);

update im_categories set aux_int1 = 0 where category_id = 9720;
update im_categories set aux_int1 = 1 where category_id = 9721;
update im_categories set aux_int1 = 2 where category_id = 9722;
