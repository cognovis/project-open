-- upgrade-4.0.3.0.5-4.0.3.0.6.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.5-4.0.3.0.6.sql','');


----------------------------------------------------------------
-- Create a table to store user preferences with respect to MS-Project Warnings
----------------------------------------------------------------




create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_gantt_ms_project_warning';
	IF v_count > 0 THEN return 1; END IF;


	create table im_gantt_ms_project_warning (
			user_id		integer
					constraint im_gantt_ms_project_warning_user_fk
					references users,
			warning_key	text,
			project_id	integer
					constraint im_gantt_ms_project_warning_project_fk
					references im_projects
	);

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

