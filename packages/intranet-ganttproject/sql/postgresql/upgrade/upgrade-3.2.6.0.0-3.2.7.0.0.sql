-- upgrade-3.2.6.0.0-3.2.7.0.0.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.2.6.0.0-3.2.7.0.0.sql','');


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Gantt Resource Assignations',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_ganttproject_resource_component -project_id $project_id -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_Resource_Assignations "Project Gantt Resource Assignations"'
);



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;

	-- Groups
	v_senman		integer;
	v_admins		integer;
	v_proman		integer;
	v_sales			integer;
	v_accounting		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_sales from groups where group_name = ''Sales'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';

	select menu_id into v_admin_menu from im_menus where label=''projects_admin'';

	-- Create a "Export Projects CSV" link under "Projects"
	v_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-ganttproject'',	-- package_name
		''projects_admin_gantt_resources'',	-- label
		''Resource Planning Report'',	-- name
		''/intranet-ganttproject/gantt-resources-cube?config=resource_planning_report'', -- url
		60,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


