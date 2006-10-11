-- /packages/intranet-notes/sql/postgresql/intranet-notes-create.sql
--
-- Copyright (c) 2003-2006 ]project-open[
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
	'im_notes',			-- package_name
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
	note		varchar(2000),
	project_id	integer
	                constraint im_project_id_fk
			references im_projects
);


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
	varchar, integer
) returns integer as '
DECLARE
	p_note_id	alias for $1;		-- note_id  default null
	p_object_type   alias for $2;		-- object_type default ''im_note''
	p_creation_date alias for $3;		-- creation_date default now()
	p_creation_user alias for $4;		-- creation_user default null
	p_creation_ip   alias for $5;		-- creation_ip default null
	p_context_id	alias for $6;		-- context_id default null

	p_note		alias for $7;		-- note_name
	p_project_id	alias for $8;		-- project_id

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
		note_id, note, project_id
	) values (
		v_note_id, p_note, p_project_id
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
-- Component Plugin
--
-- Create a Notes plugin for the ProjectListPage.
-- 
-- 
-- SELECT im_component_plugin__new (
--         null,                           -- plugin_id
--         'acs_object',                   -- object_type
--         now(),                          -- creation_date
--         null,                           -- creation_user
--         null,                           -- creation_ip
--         null,                           -- context_id
--         'Project Notes Component',	   -- plugin_name
--         'intranet-notes',               -- package_name
--         'right',                        -- location
--         '/intranet/projects/index',     -- page_url
--         null,                           -- view_name
--         90,                             -- sort_order
--         'im_notes_project_component'    -- component_tcl
--     );



-----------------------------------------------------------
-- Menu for Notes
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
        v_main_menu             integer;

        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
        v_reg_users             integer;
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
    select menu_id
    into v_main_menu
    from im_menus
    where label=''main'';

    -- Create the menu.
    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-notes'',     -- package_name
        ''notes'',              -- label
        ''Notes'',              -- name
        ''/intranet-notes/'',   -- url
        75,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
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

-- Execute the function
select inline_0 ();
drop function inline_0 ();


