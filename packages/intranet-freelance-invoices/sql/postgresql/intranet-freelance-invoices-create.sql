-- /packages/intranet-freelance-invoices/sql/oracle/intranet-freelance-invoices-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

-- Translation Invoicing
--
-- Defines:
--	im_trans_prices			List of prices with defaults
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_invoices_new_menu	integer;
        v_new_trans_invoice_menu integer;
        v_new_trans_quote_menu  integer;

        -- Groups
        v_accounting            integer;
        v_senman                integer;
        v_admins                integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_invoices_new_menu
    from im_menus
    where label=''invoices_providers'';

    v_menu := im_menu__new (
        null,                           -- menu_id
        ''acs_object'',                 -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        ''intranet-freelance-invoices'',    -- package_name
        ''invoices_freelance_new_po'',     -- label
        ''New Purchase Order from Translation Tasks'',    -- name
        ''/intranet-freelance-invoices/index?target_cost_type_id=3706'',   -- url
        70,                                             -- sort_order
        v_invoices_new_menu,                            -- parent_menu_id
        null                                            -- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    v_menu := im_menu__new (
        null,                           -- menu_id
        ''acs_object'',                 -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        ''intranet-freelance-invoices'',    -- package_name
        ''invoices_freelance_new_prov_invoice'',   -- label
        ''New Provider Invoice from Translation Tasks'',    -- name
        ''/intranet-freelance-invoices/index?target_cost_type_id=3704'',   -- url
        80,                             -- sort_order
        v_invoices_new_menu,            -- parent_menu_id
        null                            -- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();
