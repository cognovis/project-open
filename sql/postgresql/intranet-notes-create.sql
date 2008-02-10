-- /packages/intranet-notes/sql/postgresql/intranet-notes-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author all@devcon.project-open.com

-----------------------------------------------------------
-- Notes
--
-- A simple note for anything.


SELECT acs_object_type__create_type (
	'im_note',			-- object_type
	'Note',				-- pretty_name
	'Notes',			-- pretty_plural
	'acs_object',			-- supertype
	'im_notes',			-- table_name
	'note_id',			-- id_column
	'intranet-notes',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_note__name'			-- name_method
);


create table im_notes (
	note_id		integer
			constraint im_note_id_pk
			primary key
			constraint im_note_id_fk
			references acs_objects,
	note_status_id	integer 
			constraint im_note_status_nn
			not null
			constraint im_note_status_fk
			references im_categories,
	note_type_id	integer 
			constraint im_note_type_nn
			not null
			constraint im_note_type_fk
			references im_categories,
	note		text
			constraint im_note_note_nn
			not null,
	object_id	integer
			constraint im_note_oid_nn
			not null
			constraint im_object_id_fk
			references acs_objects
);

-- allow for quick searching of all notes per object.
create index im_notes_object_idx on im_notes(object_id);

-- avoid duplicate entries
create unique index im_notes_object_note_idx on im_notes(object_id, note);




-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_note__name(integer)
returns varchar as '
DECLARE
	p_note_id		alias for $1;
	v_name			varchar(2000);
BEGIN
	select	note
	into	v_name
	from	im_notes
	where	note_id = p_note_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_note__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer,
	integer, integer 
) returns integer as '
DECLARE
	p_note_id	alias for $1;		-- note_id  default null
	p_object_type   alias for $2;		-- object_type default ''im_note''
	p_creation_date alias for $3;		-- creation_date default now()
	p_creation_user alias for $4;		-- creation_user default null
	p_creation_ip   alias for $5;		-- creation_ip default null
	p_context_id	alias for $6;		-- context_id default null

	p_note		alias for $7;		-- note_name
	p_object_id	alias for $8;		-- object_id
	p_note_type_id	alias for $9;		
	p_note_status_id alias for $10;

	v_note_id	integer;
BEGIN
	v_note_id := acs_object__new (
		p_note_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_notes (
		note_id, note, object_id,
		note_type_id, note_status_id
	) values (
		v_note_id, p_note, p_object_id,
		p_note_type_id, p_note_status_id
	);

	return v_note_id;
END;' language 'plpgsql';


create or replace function im_note__delete(integer)
returns integer as '
DECLARE
	p_note_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete from im_notes
	where	note_id = p_note_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_note_id);

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
-- 11400-11499  Intranet Notes Status
-- 11500-11599  Intranet Notes Status


insert into im_categories(category_id, category, category_type) 
values (11400, 'Active', 'Intranet Notes Status');
insert into im_categories(category_id, category, category_type) 
values (11402, 'Deleted', 'Intranet Notes Status');


insert into im_categories(category_id, category, category_type) 
values (11500, 'Address', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11502, 'Email', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11504, 'Http', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11506, 'Ftp', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11508, 'Phone', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11510, 'Fax', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11512, 'Mobile', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) 
values (11514, 'Other', 'Intranet Notes Type');


-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_note_status as
select	category_id as note_status_id, category as note_status
from	im_categories
where	category_type = 'Intranet Notes Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_note_types as
select	category_id as note_type_id, category as note_type
from	im_categories
where	category_type = 'Intranet Notes Type'
	and (enabled_p is null or enabled_p = 't');



-----------------------------------------------------------
-- Component Plugin
--
-- Create a Notes plugin for the ProjectViewPage.


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Notes',		-- plugin_name
	'intranet-notes',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_notes_project_component -object_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-notes.Project_Notes "Project Notes"'
where plugin_name = 'Project Notes';


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Company Notes',		-- plugin_name
	'intranet-notes',		-- package_name
	'right',			-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_notes_project_component -object_id $company_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-notes.Company_Notes "Company Notes"'
where plugin_name = 'Company Notes';



SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'User Notes',			-- plugin_name
	'intranet-notes',		-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_notes_project_component -object_id $user_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-notes.User_Notes "User Notes"'
where plugin_name = 'User Notes';




-----------------------------------------------------------
-- Menu for Notes
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.


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
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_companies from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_main_menu
	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-notes'',	-- package_name
		''notes'',		-- label
		''Notes'',		-- name
		''/intranet-notes/'',   -- url
		75,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

	return 0;
end;' language 'plpgsql';

-- Execute and drop the function
select inline_0 ();
drop function inline_0 ();

