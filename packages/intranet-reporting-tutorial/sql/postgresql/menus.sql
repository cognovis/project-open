------------------------------------------------------------
-- Menus
------------------------------------------------------------

-- Select a specific menu. Label is used as a fixed reference
-- See the Menu maintenance screens for the name of the parent 
-- menu.

select
	m.*
from
	im_menus 
where
	label='finance'
;


-- Select all menus below a parent Menu with read permissions for the
-- current user
select  m.*
from    im_menus m
where   parent_menu_id = :parent_menu_id
	and enabled_p = 't'
	and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
order by sort_order;


-- How to create new menus
-- This function creates a new menu in the "Admin" section
-- only visible for Administrators.
--
create or replace function inline_1 ()
returns integer as '
declare
      -- Menu IDs
      v_menu		integer;
      v_admin_menu	integer;

      -- Groups
      v_admins		integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''acs_object'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-core'',      -- package_name
	''admin_user_exits'',   -- label
	''User Exits'',		-- name
	''/intranet/admin/user_exits'', -- url
	110,			-- sort_order
	v_admin_menu,		-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


---------------------------------------------------------
-- Menus
--
-- Dynamic Menus are necessary to allow modules
-- to extend the core at some point in the future without
-- that core would need know about these extensions in
-- advance.
--
-- Menus entries are basically mappings from a Name into a URL.
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
	visible_tcl		text default null,
				-- Managmenent of different configurations
	enabled_p		char(1) default('t')
				constraint im_menus_enabled_ck
				check (enabled_p in ('t','f')),
				-- Make sure there are no two identical
				-- menus on the same _level_.
	constraint im_menus_label_un
	unique(label)
);
