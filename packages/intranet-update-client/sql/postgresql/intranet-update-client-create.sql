-- /packages/intranet-update-client/sql/postgresql/intranet-update-client-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Client side of the Automatic Software Update Service

---------------------------------------------------------
-- Delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

select im_component_plugin__del_module('intranet-update-client');
select im_menu__del_module('intranet-update-client');



---------------------------------------------------------
-- Setup the "Update-Client" main menu entry
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_main_menu		integer;
	v_admin_menu		integer;

        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
BEGIN

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-update-client'', -- package_name
        ''software_updates'',   -- label
        ''Software Updates'',   -- name
        ''/intranet-update-client/'', -- url
        12,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();
