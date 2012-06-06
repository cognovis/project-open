-- upgrade-4.0.3.0.1-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');


update im_categories
set category_type = 'Intranet Timesheet Task Fixed Task Type'
where category_type = 'Intranet Timesheet Task Effort Driven Type';

-- Add im_gantt_projects as an extension table to im_timesheet_task
--


create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from acs_object_type_tables
	where	object_type = 'im_timesheet_task' and table_name = 'im_gantt_projects' and id_column = 'project_id';
	if v_count = 0 then 
	   	insert into acs_object_type_tables (object_type,table_name,id_column)
		values ('im_timesheet_task', 'im_gantt_projects', 'project_id');
	end if;
	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




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


-- Fraber 120309: This does not work!
-- SELECT im_dynfield_attribute_new (
--         'im_timesheet_task', 'xml_uid', 'MS-Project UID', 'integer', 'integer', 'f', 0, 'f', 'im_gantt_projects'
-- );


update im_categories set aux_int1 = 0 where category_id = 9720;
update im_categories set aux_int1 = 1 where category_id = 9721;
update im_categories set aux_int1 = 2 where category_id = 9722;

