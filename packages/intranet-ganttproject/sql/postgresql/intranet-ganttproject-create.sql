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

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_gantt_project', 'im_gantt_projects', 'project_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_gantt_project', 'im_projects', 'project_id');


-- Add additional meta information to allow DynFields to extend the im_note object.
update acs_object_types set
        status_type_table = 'im_projects',	-- which table contains the status_id field?
        status_column = 'project_status_id',	-- which column contains the status_id field?
        type_column = 'project_type_id'		-- which column contains the type_id field?
where object_type = 'im_project';


-- Generic URLs to link to an object of type "im_gantt_project"
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_gantt_project','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_gantt_project','edit','/intranet/projects/new?project_id=');




----------------------------------------------------------------
-- Extension table for Gantt specific information about resources

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
-- Create a "project_calendar" in im_projects
----------------------------------------------------------------

create or replace function inline_0 ()
returns integer as $$
declare
	v_count			integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_projects' and lower(column_name) = 'project_calender';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_projects
	add column project_calender text;

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



----------------------------------------------------------------
-- Extension table for Assignments

create table im_gantt_assignments (
	rel_id			integer
				constraint im_gantt_assignments_pk primary key
				constraint im_gantt_assignments_rel_fk
				references im_biz_object_members,
	xml_elements		text
				constraint im_gantt_persons_xml_elements_nn
				not null
);


----------------------------------------------------------------
-- Timephased information of assignments


create sequence im_gantt_assignments_timephased_seq;

create table im_gantt_assignment_timephases (
       	     			-- Unique ID, but not an object!
	timephase_id     	integer
				default nextval('im_gantt_assignments_timephased_seq')
				constraint im_gantt_assignment_timephases_pk
				primary key,
				-- Reference to the im_gantt_assignments base entry
	rel_id			integer
				constraint im_gantt_assignments_rel_fk
				references im_gantt_assignments,
				-- Data from MS-Project XML Export without interpretation
	timephase_uid		integer,
	timephase_type		integer,
	timephase_start		timestamptz,
	timephase_end		timestamptz,
	timephase_unit		integer,
	timephase_value		text
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
-- Privilege to download the GanttProject file of a project
----------------------------------------------------------------

-- Should Freelancers/Customers see the project Gantt details?
select acs_privilege__create_privilege('view_gantt_proj_detail',
        'View Gantt Project Details', 'View Gantt Project Details');
select acs_privilege__add_child('admin','view_gantt_proj_detail');

select im_priv_create('view_gantt_proj_detail', 'Employees');




----------------------------------------------------------------
-- Create a table to store user preferences with respect to MS-Project Warnings
----------------------------------------------------------------


create table im_gantt_ms_project_warning (
		user_id		integer
				constraint im_gantt_ms_project_warning_user_fk
				references users,
		warning_key	text,
		project_id	integer
				constraint im_gantt_ms_project_warning_project_fk
				references im_projects
);



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
		''im_menu'',			-- object_type
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
		''im_menu'',		-- object_type
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



----------------------------------------------------------------
-- Show the ganttproject component in project page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
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
	'im_component_plugin',			-- object_type
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
	'im_component_plugin',			-- object_type
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
	'im_component_plugin',			-- object_type
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
	'im_component_plugin',			-- object_type
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



create or replace function inline_0 ()
returns integer as $body$
declare
	v_menu			integer;
	v_project_menu		integer;
	v_employees		integer;
BEGIN
	select group_id into v_employees from groups where group_name = 'Employees';

	select menu_id into v_project_menu
Intranet Timesheet Task Fixed Task Type	from im_menus where label = 'projects';

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




update im_categories
set category_type = 'Intranet Timesheet Task Fixed Task Type'
where category_type = 'Intranet Timesheet Task Effort Driven Type';

-- Add im_gantt_projects as an extension table to im_timesheet_task
--
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_timesheet_task', 'im_gantt_projects', 'project_id');

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


SELECT im_dynfield_attribute_new (
        'im_timesheet_task', 'xml_uid', 'MS-Project UID', 'integer', 'integer', 'f', 0, 'f', 'im_gantt_projects'
);


update im_categories set aux_int1 = 0 where category_id = 9720;
update im_categories set aux_int1 = 1 where category_id = 9721;
update im_categories set aux_int1 = 2 where category_id = 9722;





-- Widget to select the Scheduling Constraint
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'gantt_scheduling_constraint_type', 'Gantt Scheduling Constraint Type', 'Gantt Scheduling Constraint Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Timesheet Task Scheduling Type"}}'
);


SELECT im_dynfield_attribute_new (
        'im_timesheet_task', 'scheduling_constraint_id', 'Scheduling Constraint', 'gantt_scheduling_constraint_type', 'integer', 'f', 0, 'f', 'im_timesheet_tasks'
);


SELECT im_dynfield_attribute_new (
        'im_timesheet_task', 'scheduling_constraint_date', 'Scheduling Constraint Date', 'date', 'date', 'f', 0, 'f', 'im_timesheet_tasks'
);

