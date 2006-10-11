--  upgrade-3.2.3.0.0-3.2.4.0.0.sql

-- Set unit precesision to 3 digits
alter table im_invoice_items alter item_units type numeric(12,3);





-- Setup the "Invoices New" admin menu for Company Documents
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu		  integer;
	v_invoices_new_menu	 integer;
	v_finance_menu	  integer;

	-- Groups
	v_employees		 integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		 integer;
	v_freelancers	   integer;
	v_proman		integer;
	v_admins		integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_invoices_new_menu
    from im_menus
    where label=''invoices_providers'';

    v_finance_menu := im_menu__new (
	null,			   -- menu_id
	''acs_object'',		 -- object_type
	now(),			  -- creation_date
	null,			   -- creation_user
	null,			   -- creation_ip
	null,			   -- context_id
	''intranet-invoices'',	  -- package_name
	''invoices_providers_new_po'',  -- label
	''New Purchase Order from scratch'',	-- name
	''/intranet-invoices/new?cost_type_id=3706'', -- url
	30,					   -- sort_order
	v_invoices_new_menu,			  -- parent_menu_id
	null					  -- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_finance_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_finance_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_finance_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_finance_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_finance_menu, v_freelancers, ''read'');
    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();






-- -------------------------------------------------------------
-- Add field default_quote_template_id to im_companies
--
-- Add new attributes to im_companies for default templates


create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_acs_attrib_id		integer;
	v_attrib_id		integer;
begin
	v_attrib_name := ''default_bill_template_id'';
	v_attrib_pretty := ''Default Provider Bill Template'';

	v_acs_attrib_id := acs_attribute__create_attribute (
		''im_company'',
		v_attrib_name,
		''integer'',
		v_attrib_pretty,
		v_attrib_pretty,
		''im_companies'',
		NULL, NULL,
		''0'', ''1'',
		NULL, NULL,
		NULL
	);

        alter table im_companies add default_bill_template_id integer;

	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null,
		null, 
		null
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''category_invoice_template'', ''f''
	);

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_acs_attrib_id		integer;
	v_attrib_id		integer;
begin
	v_attrib_name := ''default_po_template_id'';
	v_attrib_pretty := ''Default PO Template'';

	v_acs_attrib_id := acs_attribute__create_attribute (
		''im_company'',
		v_attrib_name,
		''integer'',
		v_attrib_pretty,
		v_attrib_pretty,
		''im_companies'',
		NULL, NULL,
		''0'', ''1'',
		NULL, NULL,
		NULL
	);

        alter table im_companies add default_po_template_id integer;

	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null,
		null, 
		null
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''category_invoice_template'', ''f''
	);

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();










create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_acs_attrib_id		integer;
	v_attrib_id		integer;
begin
	v_attrib_name := ''default_delnote_template_id'';
	v_attrib_pretty := ''Default Delivery Note Template'';

	v_acs_attrib_id := acs_attribute__create_attribute (
		''im_company'',
		v_attrib_name,
		''integer'',
		v_attrib_pretty,
		v_attrib_pretty,
		''im_companies'',
		NULL, NULL,
		''0'', ''1'',
		NULL, NULL,
		NULL
	);

        alter table im_companies add default_delnote_template_id integer;

	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null,
		null, 
		null
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''category_invoice_template'', ''f''
	);

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


