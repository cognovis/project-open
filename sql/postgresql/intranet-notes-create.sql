-- /packages/intranet-notes/sql/postgresql/intranet-notes-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author various@project-open.com

-----------------------------------------------------------
-- Notes
--
-- A simple note for adding data to objects such as project, users etc.


-- Create a new object type.
-- This statement only creates an entry in acs_object_types with some
-- meta-information (table name, ... as specified below) about the new 
-- object. 
-- Please note that this is quite different from creating a new object
-- class in Java or other languages.

SELECT acs_object_type__create_type (
	'im_note',			-- object_type - only lower case letters and "_"
	'Note',				-- pretty_name - Human readable name
	'Notes',			-- pretty_plural - Human readable plural
	'acs_object',			-- supertype - "acs_object" is topmost object type.
	'im_notes',			-- table_name - where to store data for this object?
	'note_id',			-- id_column - where to store object_id in the table?
	'intranet-notes',		-- package_name - name of this package
	'f',				-- abstract_p - abstract class or not
	null,				-- type_extension_table
	'im_note__name'			-- name_method - a PL/SQL procedure that
					-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_note object.
update acs_object_types set
        status_type_table = 'im_notes',		-- which table contains the status_id field?
        status_column = 'note_status_id',	-- which column contains the status_id field?
        type_column = 'note_type_id'		-- which column contains the type_id field?
where object_type = 'im_note';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_note object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_note', 'im_notes', 'note_id');



-- Generic URLs to link to an object of type "im_note".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_note','view','/intranet-notes/new?display_mode=display&note_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_note','edit','/intranet-notes/new?display_mode=edit&note_id=');



-- This table stores one object per row. Links to super-type "acs_object" 
-- using the "note_id" field, which contains the same object_id as 
-- acs_objects.object_id.
create table im_notes (
			-- The object_id: references acs_objects.object_id.
			-- So we can lookup object metadata such as creation_date,
			-- object_type etc in acs_objects.
	note_id		integer
			constraint im_note_id_pk
			primary key
			constraint im_note_id_fk
			references acs_objects,
			-- Every ]po[ object should have a "status_id" to control
			-- its lifecycle. Status_id reference im_categories, where 
			-- you can define the list of stati for this object type.
	note_status_id	integer 
			constraint im_note_status_nn
			not null
			constraint im_note_status_fk
			references im_categories,
			-- Every ]po[ object should have a "type_id" to allow creating
			-- sub-types of the object. Type_id references im_categories
			-- where you can define the list of subtypes per object type.
	note_type_id	integer 
			constraint im_note_type_nn
			not null
			constraint im_note_type_fk
			references im_categories,
			-- This is the main content of a "note". Just a piece of text.
	note		text
			constraint im_note_note_nn
			not null,
			-- Field to allow attaching the note to a project, user or
			-- company. So object_id references acs_objects.object_id,
			-- the supertype of all object types.
	object_id	integer
			constraint im_note_oid_nn
			not null
			constraint im_object_id_fk
			references acs_objects
);

-- Speed up (frequent) queries to find all notes for a specific object.
create index im_notes_object_idx on im_notes(object_id);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint in order
-- to avoid creating duplicate entries during data import or if the user
-- performs a "double-click" on the "Create New Note" button...
-- (This makes a lot of sense in practice. Otherwise there would be loads
-- of duplicated projects in the system and worse...)
create unique index im_notes_object_note_idx on im_notes(object_id, note);



-----------------------------------------------------------
-- PL/SQL functions to Create and Delete notes and to get
-- the name of a specific note.
--
-- These functions represent constructor/destructor
-- functions for the OpenACS object system.
-- The double underscore ("__") represents the dot ("."),
-- which is not allowed in PostgreSQL.


-- Get the name for a specific note.
-- This function allows displaying object in generic contexts
-- such as the Full-Text Search engine or the Workflow.
--
-- Input is the note_id, output is a string with the name.
-- The function just pulls out the "note" text of the note
-- as the name. Not pretty, but we don't have any other data,
-- and every object needs this "__name" function.
create or replace function im_note__name(integer)
returns varchar as $body$
DECLARE
	p_note_id		alias for $1;
	v_name			varchar;
BEGIN
	select	substring(note for 30)
	into	v_name
	from	im_notes
	where	note_id = p_note_id;

	return v_name;
end; $body$ language 'plpgsql';


-- Create a new note.
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a note with
-- the required fields of the im_notes table.
create or replace function im_note__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer,
	integer, integer 
) returns integer as $body$
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_note_id	alias for $1;		-- note_id  default null
	p_object_type   alias for $2;		-- object_type default im_note
	p_creation_date alias for $3;		-- creation_date default now()
	p_creation_user alias for $4;		-- creation_user default null
	p_creation_ip   alias for $5;		-- creation_ip default null
	p_context_id	alias for $6;		-- context_id default null

	-- Specific parameters with data to go into the im_notes table
	p_note		alias for $7;		-- im_notes.note - contents
	p_object_id	alias for $8;		-- associated object (project, user, ...)
	p_note_type_id	alias for $9;		-- type (email, http, text comment, ...)
	p_note_status_id alias for $10;		-- status ("active" or "deleted").

	-- This is a variable for the PL/SQL function
	v_note_id	integer;
BEGIN
	-- Create an acs_object as the super-type of the note.
	-- (Do you remember, im_note is a subtype of acs_object?)
	-- acs_object__new returns the object_id of the new object.
	v_note_id := acs_object__new (
		p_note_id,		-- object_id - NULL to create a new id
		p_object_type,		-- object_type - "im_note"
		p_creation_date,	-- creation_date - now()
		p_creation_user,	-- creation_user - Current user or "0" for guest
		p_creation_ip,		-- creation_ip - IP from ns_conn, or "0.0.0.0"
		p_context_id,		-- context_id - NULL, not used in ]po[
		't'			-- security_inherit_p - not used in ]po[
	);
	
	-- Create an entry in the im_notes table with the same
	-- v_note_id from acs_objects.object_id
	insert into im_notes (
		note_id, note, object_id,
		note_type_id, note_status_id
	) values (
		v_note_id, p_note, p_object_id,
		p_note_type_id, p_note_status_id
	);

	return v_note_id;
END;$body$ language 'plpgsql';


-- Delete a note from the system.
-- Delete entries from both im_notes and acs_objects.
-- Deleting only from im_notes would lead to an invalid
-- entry in acs_objects, which is probably harmless, but innecessary.
create or replace function im_note__delete(integer)
returns integer as $body$
DECLARE
	p_note_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_notes
	where	note_id = p_note_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_note_id);

	return 0;
end;$body$ language 'plpgsql';




-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for Notes type and status.
-- Status acutally is not used by the application, 
-- so we just define "active" and "deleted".
-- Type contains information on how to format the data
-- in the im_notes.note field. For example, a "HTTP"
-- note is shown as a link.
--
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own packages.
--
-- 11400-11499  Intranet Notes Status
-- 11500-11599  Intranet Notes Status

-- Status
SELECT im_category_new (11400, 'Active', 'Intranet Notes Status');
SELECT im_category_new (11402, 'Deleted', 'Intranet Notes Status');

-- Type
SELECT im_category_new (11500, 'Address', 'Intranet Notes Type');
SELECT im_category_new (11502, 'Email', 'Intranet Notes Type');
SELECT im_category_new (11504, 'Http', 'Intranet Notes Type');
SELECT im_category_new (11506, 'Ftp', 'Intranet Notes Type');
SELECT im_category_new (11508, 'Phone', 'Intranet Notes Type');
SELECT im_category_new (11510, 'Fax', 'Intranet Notes Type');
SELECT im_category_new (11512, 'Mobile', 'Intranet Notes Type');
SELECT im_category_new (11514, 'Other', 'Intranet Notes Type');


-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_note_status as
select	category_id as note_status_id, category as note_status
from	im_categories
where	category_type = 'Intranet Notes Status'
	and enabled_p = 't';

create or replace view im_note_types as
select	category_id as note_type_id, category as note_type
from	im_categories
where	category_type = 'Intranet Notes Type'
	and enabled_p = 't';




-------------------------------------------------------------
-- Permissions and Privileges
--

-- A "privilege" is a kind of parameter that can be set per group
-- in the Admin -> Profiles page. This way you can define which
-- users can see notes.
-- In the default configuration below, only Employees have the
-- "privilege" to "view" notes.
-- The "acs_privilege__add_child" line below means that "view_notes"
-- is a sub-privilege of "admin". This way the SysAdmins always
-- have the right to view notes.

select acs_privilege__create_privilege('view_notes','View Notes','View Notes');
select acs_privilege__add_child('admin', 'view_notes');

-- Allow all employees to view notes. You can add new groups in 
-- the Admin -> Profiles page.
select im_priv_create('view_notes','Employees');


-----------------------------------------------------------
-- Plugin Components
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system. The plugin shows the list of notes that are
-- associated with the specific object.
-- This way we can add notes to projects, users companies etc.
-- with only a single TCL/ADP page.
--
-- You can add/modify these plugin definitions in the Admin ->
-- Plugin Components page



-- Create a Notes plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
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
	'im_notes_component -object_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-notes.Project_Notes "Project Notes"'
where plugin_name = 'Project Notes';


-- Create a notes plugin for the CompanyViewPage
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
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
	'im_notes_component -object_id $company_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-notes.Company_Notes "Company Notes"'
where plugin_name = 'Company Notes';



-- Create a notes plugin for the UserViewPage
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
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
	'im_notes_component -object_id $user_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-notes.User_Notes "User Notes"'
where plugin_name = 'User Notes';




-----------------------------------------------------------
-- Menu for Notes
--
-- Create a menu item in the main menu bar and set some default 
-- permissions for various groups who should be able to see the menu.


create or replace function inline_0 ()
returns integer as $body$
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_senman from groups where group_name = 'Senior Managers';
	select group_id into v_employees from groups where group_name = 'Employees';
	select group_id into v_customers from groups where group_name = 'Customers';
	select group_id into v_freelancers from groups where group_name = 'Freelancers';
	select group_id into v_reg_users from groups where group_name = 'Registered Users';

	-- Determine the main menu. "Label" is used to identify menus.
	select menu_id into v_main_menu
	from im_menus where label='main';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		'im_component_plugin',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'intranet-notes',	-- package_name
		'notes',		-- label
		'Notes',		-- name
		'/intranet-notes/',	-- url
		75,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	-- Grant some groups the read permission for the main "Notes" tab.
	-- These permissions are independent from the user`s permission to
	-- read the actual notes.
	PERFORM acs_permission__grant_permission(v_menu, v_senman, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_reg_users, 'read');

	return 0;
end; $body$ language 'plpgsql';
-- Execute and then drop the function
select inline_0 ();
drop function inline_0 ();

