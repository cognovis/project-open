-- /packages/intranet-sysconfig/sql/postgres/intranet-sysconfig-create.sql
--
-- ]project-open[ System Configuration Wizard
-- 061111 frank.bergmann@project-open.com
--
-- Copyright (c) 2006]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>



-------------------------------------------------------------
-- Menu Entry in "Admin"
--

select im_menu__del_module('intranet-sysconfig');

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,                   	-- menu_id
        ''acs_object'',         	-- object_type
        now(),                  	-- creation_date
        null,                   	-- creation_user
        null,                   	-- creation_ip
        null,                   	-- context_id
	''intranet-sysconfig'',		-- package_name
	''admin_sysconfig'',		-- label
	''SysConfig'',			-- name
	''/intranet-sysconfig/'',	-- url
	15,				-- sort_order
	v_admin_menu,			-- parent_menu_id
	null				-- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-------------------------------------------------------------
-- Component in Homepage
--

-- Show the forum component in project page
--
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'System Configuration Wizard',  -- plugin_name
        'intranet-sysconfig',           -- package_name
        'left',                        -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        10,                             -- sort_order
        'im_sysconfig_component',
        'lang::message::lookup "" intranet-sysconfig.System_Config_Wizard "System Configuration Wizard"'
);
