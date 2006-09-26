-- Select a specific menu. Label is used as a fixed reference
-- See the Menu maintenance screens for the name of the parent 
-- menu.

select menu_id 
from im_menus 
where label='finance'
;


-- Select all menus below a Parent with read permissions of the
-- current user

        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
                and enabled_p = 't'
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order
;

-- How to create new menus
-- This function creates a new menu in the "Admin" section
-- only visible for Administrators.
--
create or replace function inline_1 ()
returns integer as '
declare
      -- Menu IDs
      v_menu                  integer;
      v_admin_menu	      integer;

      -- Groups
      v_admins                integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_user_exits'',   -- label
        ''User Exits'',            -- name
        ''/intranet/admin/user_exits'', -- url
        110,                     -- sort_order
        v_admin_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();








---------------------------------------------------------
-- Menus
--
-- Dynamic Menus are necessary to allow Project/Open modules
-- to extend the core at some point in the future without
-- that core would need know about these extensions in
-- advance.
--
-- Menus entries are basicly mappings from a Name into a URL.
--
-- In addition, menu entries contain a parent_menu_id,
-- allowing for a tree view of all menus (to build a left-
-- hand-side navigation bar).
--
-- The same parent_menu_id field allows a particular page 
-- to find out about its submenus items to display by checking 
-- the super-menu that points to the page and by selecting
-- all of its sub-menu-items. However, the develpers needs to
-- avoid multiple menu pointers to the same page because
-- this leads to an ambiguity about the supermenu.
-- These ambiguities are resolved by taking the menu from
-- the highest possible hierarchy level and then using the
-- lowest sort_key.


SELECT acs_object_type__create_type (
        'im_menu',		    -- object_type
        'Menu',			    -- pretty_name
        'Menus',		    -- pretty_plural
        'acs_object',               -- supertype
        'im_menus',		    -- table_name
        'menu_id',		    -- id_column
        'im_menu',		    -- package_name
        'f',                        -- abstract_p
        null,                       -- type_extension_table
        'im_menu.name'  -- name_method
    );


-- The idea is to use OpenACS permissions in the future to
-- control who should see what menu.

CREATE TABLE im_menus (
	menu_id 		integer
				constraint im_menu_id_pk
				primary key
				constraint im_menu_id_fk
				references acs_objects,
				-- used to remove all menus from one package
				-- when uninstalling a package
	package_name		varchar(200) not null,
				-- symbolic name of the menu that cannot be
				-- changed using the menu editor.
				-- It cat be used as a constant by TCL pages to
				-- locate their menus.
	label			varchar(200) not null,
				-- the name that should appear on the tab
	name			varchar(200) not null,
				-- On which pages should the menu appear?
	url			varchar(200) not null,
				-- sort order WITHIN the same level
	sort_order		integer,
				-- parent_id allows for tree view for navbars
	parent_menu_id		integer
				constraint im_parent_menu_id_fk
				references im_menus,	
				-- hierarchical codification of menu levels
	tree_sortkey		varchar(100),
				-- TCL expression that needs to be either null
				-- or evaluate (expr *) to 1 in order to display 
				-- the menu.
	visible_tcl		varchar(1000) default null,
				-- Managmenent of different configurations
	enabled_p		char(1) default('t')
                                constraint im_menus_enabled_ck
                                check (enabled_p in ('t','f')),
				-- Make sure there are no two identical
				-- menus on the same _level_.
	constraint im_menus_label_un
	unique(label)
);

create or replace function im_menu__new (integer, varchar, timestamptz, integer, varchar, integer,
varchar, varchar, varchar, varchar, integer, integer, varchar) returns integer as '
declare
	p_menu_id	  alias for $1;   -- default null
        p_object_type	  alias for $2;   -- default ''acs_object''
        p_creation_date	  alias for $3;   -- default now()
        p_creation_user	  alias for $4;   -- default null
        p_creation_ip	  alias for $5;   -- default null
        p_context_id	  alias for $6;   -- default null
	p_package_name	  alias for $7;
	p_label		  alias for $8;
	p_name		  alias for $9;
	p_url		  alias for $10;
	p_sort_order	  alias for $11;
	p_parent_menu_id  alias for $12;
	p_visible_tcl	  alias for $13;  -- default null
begin
end;' language 'plpgsql';



-- Delete a single menu (if we know its ID...)
create or replace function im_menu__delete (integer) returns integer as '
DECLARE
	p_menu_id	alias for $1;
BEGIN
end;' language 'plpgsql';


-- Delete all menus of a module.
create or replace function im_menu__del_module (varchar) returns integer as '
DECLARE
	p_module_name   alias for $1;
BEGIN
end;' language 'plpgsql';


-- Returns the name of the menu
create or replace function im_menu__name (integer) returns varchar as '
DECLARE
        p_menu_id   alias for $1;
BEGIN
end;' language 'plpgsql';


