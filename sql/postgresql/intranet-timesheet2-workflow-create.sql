-- /packages/intranet-timesheet2-workflow/sql/postgresql/intranet-timesheet2-workflow-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Workflow Confirmation Object
--
-- Allows to use a workflow to confirm hours between start_date
-- and end_date.


SELECT acs_object_type__create_type (
	'im_timesheet_conf_object',	-- object_type
	'Timesheet Confirmation Object', -- pretty_name
	'Timesheet Confirmation Objects', -- pretty_plural
	'acs_object',			-- supertype
	'im_timesheet_conf_objects',	-- table_name
	'conf_id',			-- id_column
	'intranet-timesheet-workflow',	-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_timesheet_conf_object__name' -- name_method
);


create table im_timesheet_conf_objects (
	conf_id		integer
			constraint im_timesheet_conf_id_pk
			primary key
			constraint im_timesheet_conf_id_fk
			references acs_objects,

	conf_project_id	integer
			constraint im_timesheet_conf_project_nn
			not null
			constraint im_timesheet_conf_project_fk
			references im_projects,
	conf_user_id	integer
			constraint im_timesheet_conf_user_nn
			not null
			constraint im_timesheet_conf_user_fk
			references users,
	start_date	date 
			constraint im_timesheet_conf_start_date_nn
			not null,
	end_date	date 
			constraint im_timesheet_conf_end_date_nn
			not null,

	conf_status_id	integer 
			constraint im_timesheet_conf_status_nn
			not null
			constraint im_timesheet_conf_status_fk
			references im_categories,
	conf_type_id	integer 
			constraint im_timesheet_conf_type_nn
			not null
			constraint im_timesheet_conf_type_fk
			references im_categories
);


-- avoid duplicate entries
create unique index im_timesheet_conf_un_idxx on im_timesheet_conf_objects(conf_project_id, conf_user_id, start_date);




-- Add an conf_object_id field to im_hours to mark confirmed hours
alter table im_hours add column conf_object_id integer 
constraint im_hours_conf_obj_fk references im_timesheet_conf_objects;

-- And add an index, as access to conf_obj is quite frequent.
create index im_hours_conf_obj_idx on im_hours(conf_object_id);



-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_timesheet_conf_object__name(integer)
returns varchar as '
DECLARE
	p_conf_id		alias for $1;
	v_name			varchar(2000);
BEGIN
	select	''Timesheet '' || 
		im_name_from_user_id(conf_user_id) || '' '' || 
		to_char(start_date, ''YYYY-MM-DD'') || '' - '' ||
		to_char(end_date, ''YYYY-MM-DD'') || '' ''
	into	v_name
	from	im_timesheet_conf_objects
	where	conf_id = p_conf_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_timesheet_conf_object__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, integer, date, date, integer, integer
) returns integer as '
DECLARE
	p_conf_id	alias for $1;
	p_object_type   alias for $2;
	p_creation_date alias for $3;
	p_creation_user alias for $4;
	p_creation_ip   alias for $5;
	p_context_id	alias for $6;

	p_conf_project_id alias for $7;
	p_conf_user_id	alias for $8;
	p_start_date	alias for $9;
	p_end_date	alias for $10;

	p_conf_type_id	alias for $11;		
	p_conf_status_id alias for $12;

	v_conf_id	integer;
BEGIN
	v_conf_id := acs_object__new (
		p_conf_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_timesheet_conf_objects (
		conf_id,
		conf_project_id, conf_user_id,
		start_date, end_date,
		conf_type_id, conf_status_id
	) values (
		v_conf_id,
		p_conf_project_id, p_conf_user_id,
		p_start_date, p_end_date,
		p_conf_type_id,	p_conf_status_id
	);

	return v_conf_id;
END;' language 'plpgsql';


create or replace function im_timesheet_conf_object__delete(integer)
returns integer as '
DECLARE
	p_conf_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_timesheet_conf_objects
	where	conf_id = p_conf_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_conf_id);

	return 0;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Type and Status
--
-- Create categories for Notes type and status.
-- Status acutally is not use, so we just define "active"

-- Here are the ranges for the constants as defined in
-- /intranet-core/sql/common/intranet-categories.sql
--
-- Please contact support@project-open.com if you need to
-- reserve a range of constants for a new module.
--
-- 17000-17099  Intranet Timesheet Workflow Status (100)
-- 17100-17199  Intranet Timesheet Workflow Type (100)
-- 17200-17999  Reserved (8000)


insert into im_categories(category_id, category, category_type) 
values (17000, 'Created', 'Intranet Timesheet Conf Status');
insert into im_categories(category_id, category, category_type) 
values (17010, 'Unconfirmed', 'Intranet Timesheet Conf Status');
insert into im_categories(category_id, category, category_type) 
values (17080, 'Confirmed', 'Intranet Timesheet Conf Status');
insert into im_categories(category_id, category, category_type) 
values (17090, 'Deleted', 'Intranet Timesheet Conf Status');


insert into im_categories(category_id, category, category_type) 
values (17100, 'Default', 'Intranet Timesheet Conf Type');


-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_timesheet_conf_object_status as
select	category_id as conf_status_id, category as conf_status
from	im_categories
where	category_type = 'Intranet Timesheet Conf Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_timesheet_conf_object_types as
select	category_id as conf_type_id, category as conf_type
from	im_categories
where	category_type = 'Intranet Timesheet Conf Type'
	and (enabled_p is null or enabled_p = 't');



-----------------------------------------------------------
-- Component Plugin
--
-- Create a Timesheet Conf plugin for the ProjectViewPage.


-- SELECT im_component_plugin__new (
-- 	null,				-- plugin_id
-- 	'acs_object',			-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip
-- 	null,				-- context_id
-- 	'Project Timesheet Conf',		-- plugin_name
-- 	'intranet-timesheet2-workflow',		-- package_name
-- 	'right',			-- location
-- 	'/intranet/projects/view',	-- page_url
-- 	null,				-- view_name
-- 	90,				-- sort_order
-- 	'im_timesheet_conf_objects_project_component -object_id $project_id'	-- component_tcl
-- );

-- update im_component_plugins 
-- set title_tcl = 'lang::message::lookup "" intranet-timesheet2-workflow.Project_Timesheet Conf "Project Timesheet Conf"'
-- where plugin_name = 'Project Timesheet Conf';


-- SELECT im_component_plugin__new (
-- 	null,				-- plugin_id
-- 	'acs_object',			-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip
-- 	null,				-- context_id
-- 	'Company Timesheet Conf',		-- plugin_name
-- 	'intranet-timesheet2-workflow',		-- package_name
-- 	'right',			-- location
-- 	'/intranet/companies/view',	-- page_url
-- 	null,				-- view_name
-- 	90,				-- sort_order
-- 	'im_timesheet_conf_objects_project_component -object_id $company_id'	-- component_tcl
-- );

--  update im_component_plugins 
-- set title_tcl = 'lang::message::lookup "" intranet-timesheet2-workflow.Company_Timesheet Conf "Company Timesheet Conf"'
-- where plugin_name = 'Company Timesheet Conf';


-----------------------------------------------------------
-- Add "Start Timesheet Workflow" link to TimesheetNewPage
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_proman		integer;
	v_admins		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';

	-- Determine the main menu. "Label" is used to identify menus.
	select menu_id into v_main_menu
	from im_menus where label = ''timesheet_hours_new_admin'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-timesheet2-workflow'',	-- package_name
		''timesheet_hours_new_start_workflow'',	-- label
		''Start Confirmation Workflow'',		-- name
		''/intranet-timesheet2-workflow/new-workflow?'',	-- url
		15,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
