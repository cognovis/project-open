-- upgrade-4.0.3.0.2-4.0.3.0.3.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.3.sql','');

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
