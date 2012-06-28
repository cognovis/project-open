-- upgrade-4.0.3.0.7-4.0.3.0.8.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.7-4.0.3.0.8.sql','');


----------------------------------------------------------------
-- 
----------------------------------------------------------------

create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_projects' and lower(column_name) = 'project_calender';
	IF v_count > 0 THEN
		alter table im_projects
		drop column project_calender;
	END IF;
	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_projects' and lower(column_name) = 'project_calendar';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_projects
	add column project_calendar text;

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





