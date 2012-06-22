-- upgrade-4.0.1.0.5-4.0.1.0.6.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.1.0.5-4.0.1.0.6.sql','');


create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_gantt_projects' and lower(column_name) = 'xml_id';
	if v_count = 0 then 
		RAISE NOTICE 'intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.1.0.5-4.0.1.0.6.sql: Creating im_gantt_projects.xml_id';
		alter table im_gantt_projects
		add column xml_id text;
	end if;

	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_gantt_projects' and lower(column_name) = 'xml_uid';
	if v_count = 0 then 
		RAISE NOTICE 'intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.1.0.5-4.0.1.0.6.sql: Creating im_gantt_projects.xml_uid';
		alter table im_gantt_projects
		add column xml_uid text;
	end if;

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

