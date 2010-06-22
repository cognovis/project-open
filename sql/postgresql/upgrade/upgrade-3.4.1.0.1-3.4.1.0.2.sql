-- upgrade-3.4.1.0.1-3.4.1.0.2.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.4.1.0.1-3.4.1.0.2.sql','');

-- -----------------------------------------------------
-- Additional Menus for the ProjectListPage
-- -----------------------------------------------------

create or replace function inline_0 ()
returns integer as $body$
declare
	v_menu			integer;
	v_project_menu		integer;
	v_employees		integer;
BEGIN
	select group_id into v_employees from groups where group_name = 'Employees';

	select menu_id into v_project_menu
	from im_menus where label = 'projects';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		'im_menu',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		'intranet-ganttproject',		-- package_name
		'projects_gantt_resources',		-- label
		'Resource Planning',			-- name
		'/intranet-ganttproject/gantt-resources-cube?config=resource_planning_report', -- url
		-20,					-- sort_order
		v_project_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- Disable the old menu
update im_menus set enabled_p = 'f'
where label = 'projects_admin_gantt_resources';
