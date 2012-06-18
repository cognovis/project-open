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





----------------------------------------------------------------
-- Show MS-Project warnings in project page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'MS-Project Warning Component',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'top',					-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_ganttproject_ms_project_warning_component -project_id $project_id',
	'lang::message::lookup "" intranet-ganttproject.MS_Project_Warnings "MS-Project Warnings"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'MS-Project Warning Component'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

