

create or replace function im_project_nr_from_id (integer)
returns varchar as '
DECLARE
        p_project_id	alias for $1;
        v_name		varchar(100);
BEGIN
        select project_nr
        into v_name
        from im_projects
        where project_id = p_project_id;

        return v_name;
end;' language 'plpgsql';



-- -------------------------------------------------------
-- Setup an invisible Companies Admin menu 
-- This can be extended later by other modules
-- with more Admin Links
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
    select menu_id
    into v_main_menu
    from im_menus
    where label = ''companies'';

    -- Main admin menu - just an invisible top-menu
    -- for all admin entries links under Companies
    v_admin_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''companies_admin'',    -- label
        ''Companies Admin'',    -- name
        ''/intranet-core/'',    -- url
        90,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        ''0''                   -- p_visible_tcl
    );

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();




-- -------------------------------------------------------
-- Setup an invisible Projects Admin menu 
-- This can be extended later by other modules
-- with more Admin Links
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
    select menu_id
    into v_main_menu
    from im_menus
    where label = ''projects'';

    -- Main admin menu - just an invisible top-menu
    -- for all admin entries links under Projects
    v_admin_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_admin'',    -- label
        ''Projects Admin'',    -- name
        ''/intranet-core/'',    -- url
        90,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        ''0''                   -- p_visible_tcl
    );

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();

