
-- Add a "CostCenter" column to the main Inovice list
delete from im_view_columns where column_id=3002;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3002,30,NULL,'CC',
'$cost_center_code','','',2,'');


-- Dont show status_select for an invoice if the user cant read it.
delete from im_view_columns where column_id = 3017;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3017,30,NULL,'Status',
'$status_select','','',17,'');


-- Setup new Menu links for PO and Delivery Note from scratch
-- and DelNote from Quote
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_invoices_providers	integer;
	v_invoices_customers	integer;

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
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_invoices_customers
    from im_menus
    where label=''invoices_customers'';

    select menu_id
    into v_invoices_providers
    from im_menus
    where label=''invoices_providers'';

    v_menu := im_menu__new (
	null,                           -- menu_id
        ''acs_object'',                 -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
	''intranet-invoices'',		-- package_name
	''invoices_providers_new_po'',	-- label
	''New Purchase Order from scratch'',	-- name
	''/intranet-invoices/new?cost_type_id=3706'',	-- url
	40,						-- sort_order
	v_invoices_providers,				-- parent_menu_id
	null						-- visible_tcl
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
	''intranet-invoices'',		-- package_name
	''invoices_providers_new_delnote'',	-- label
	''New Delivery Note from scratch'',	-- name
	''/intranet-invoices/new?cost_type_id=3724'',	-- url
	30,						-- sort_order
	v_invoices_customers,				-- parent_menu_id
	null						-- visible_tcl
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
	''intranet-invoices'',		-- package_name
	''invoices_customers_new_delnote_from_quote'',	-- label
	''New Delivery Note from Quote'',		-- name
					-- url
	''/intranet-invoices/new-copy?target_cost_type_id=3724\&source_cost_type_id=3702'',
					-- sort_order
	20,				
					-- parent_menu_id
	v_invoices_customers,		
					-- visible_tcl
	null				
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

