-- /packages/intranet-ganttproject/sql/postgresql/intranet-ganttproject-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


---------------------------------------------------------
-- Add "xml_elements" to project + person
--

create table im_gantt_projects (
	project_id		integer
				constraint im_gantt_projects_project_pk
				primary key
				constraint im_gantt_projects_project_id_fk
				references im_projects,
	xml_elements		text
				constraint im_gantt_projects_xml_elements_nn
				not null
);

select acs_object_type__create_type (
	'im_gantt_project',	-- object_type
	'GanttProject',		-- pretty_name
	'GanttProjects',	-- pretty_plural
	'im_project',		-- supertype
	'im_gantt_projects',	-- table_name
	'project_id',		-- id_column
	'im_gantt_project',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_project__name'	-- name_method
);

create table im_gantt_persons (
	person_id		integer
				constraint im_gantt_persons_person_pk
				primary key
				constraint im_gantt_persons_person_id_fk
				references persons,
	xml_elements		text
				constraint im_gantt_persons_xml_elements_nn
				not null
);

select acs_object_type__create_type (
	'im_gantt_person',	-- object_type
	'GanttPerson',		-- pretty_name
	'GanttPersons',		-- pretty_plural
	'person', 		-- supertype
	'im_gantt_persons',	-- table_name
	'person_id',		-- id_column
	'im_gantt_person',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_person__name'	-- name_method
);






----------------------------------------------------------------
-- percentage column for im_biz_object_members


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_biz_object_members'' and lower(column_name) = ''percentage'';
	IF 0 != v_count THEN return 0; END IF;

	ALTER TABLE im_biz_object_members ADD column percentage numeric(8,2);
	ALTER TABLE im_biz_object_members ALTER column percentage set default 100;

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



----------------------------------------------------------------
-- Add new tab to project's menu

create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu		integer;
	v_project_menu	integer;

	-- Groups
	v_accounting		integer;
	v_senman		integer;
	v_sales		integer;
	v_proman		integer;

begin
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_sales from groups where group_name = ''Sales'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';

	select menu_id into v_project_menu
	from im_menus where label=''project'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-ganttproject'',	-- package_name
		''project_gantt'',		-- label
		''Gantt'',			-- name
		''/intranet-ganttproject/gantt-view-cube?view=default'',  -- url
		120,				-- sort_order
		v_project_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu		integer;
	v_project_menu	integer;

	-- Groups
	v_accounting		integer;
	v_senman		integer;
	v_sales		integer;
	v_proman		integer;

begin
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_sales from groups where group_name = ''Sales'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';

	select menu_id into v_project_menu
	from im_menus where label=''project'';

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-ganttproject'', -- package_name
		''project_resources'',  -- label
		''Resources'',		-- name
		''/intranet-ganttproject/gantt-resources-cube?view=default'',  -- url
		130,			-- sort_order
		v_project_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






---------------------------------------------------------
-- Setup a "Resource Report" Menu link
--

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

	select menu_id into v_admin_menu
	from im_menus where label=''projects_admin'';

	-- Create a "Export Projects CSV" link under "Projects"
	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
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







----------------------------------------------------------------
-- Show the ganttproject component in project page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project GanttProject Component',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_ganttproject_component -project_id $project_id -current_page_url $current_url -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Scheduling "Scheduling"'
);



----------------------------------------------------------------
-- Summary components in ProjectViewPage
----------------------------------------------------------------

-- Resource Component with LoD 2 at the right-hand side
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Gantt Resource Summary',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	-13,				-- sort_order
	'im_ganttproject_resource_component -project_id $project_id -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_Resource_Assignations "Project Gantt Resource Assignations"'
);



-- Gantt Component with LoD 2 at the right-hand side
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Gantt Scheduling Summary', -- plugin_name
	'intranet-ganttproject',	-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	12,				-- sort_order
	'im_ganttproject_gantt_component -project_id $project_id -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_View "Project Gantt View"'
);




----------------------------------------------------------------
-- Detailed components in Gantt tab
----------------------------------------------------------------

-- Gantt Component with LoD 3 in extra tab
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Gantt View Details',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'gantt',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_ganttproject_gantt_component -project_id $project_id -level_of_detail 3 -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_View "Project Gantt View"'
);


-- Resource Component with LoD 3 in extra tab
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Gantt Resource Details',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'gantt',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	200,				-- sort_order
	'im_ganttproject_resource_component -project_id $project_id -level_of_detail 3 -return_url $return_url -export_var_list [list project_id]',
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

	select menu_id into v_admin_menu
	from im_menus where label=''projects_admin'';

	-- Create a "Export Projects CSV" link under "Projects"
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-ganttproject'',	-- package_name
		''projects_admin_gantt_resources'',	-- label
		''Resource Planning Report'',	-- name
		''/intranet-ganttproject/gantt-resources-cube?config=resource_planning_report'', -- url
		60,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
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

