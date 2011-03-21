-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-simple-survey/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');



-- Setup the Simple Survey Report in Menus
--
create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_project_menu 		integer;
	v_employees		integer;
begin
	select group_id into v_employees from groups where group_name = ''Employees'';
	select menu_id into v_project_menu from im_menus where label=''projects'';

	v_menu := im_menu__new (
		null,							-- menu_id
		''im_menu'',						-- object_type
		now(),							-- creation_date
		null,							-- creation_user
		null,							-- creation_ip
		null,							-- context_id
		''intranet-simple-survey'',				-- package_name
		''project_reports'',					-- label
		''Project Reports'',					-- name
		''/intranet-simple-survey/reporting/project-reports'',	-- url
		-5,							-- sort_order
		v_project_menu,						-- parent_menu_id
		null							-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


