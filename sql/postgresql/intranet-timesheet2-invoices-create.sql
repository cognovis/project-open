-- /packages/intranet-timesheet2-invoices/sql/oracle/intranet-timesheet2-invoices-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

-- Timesheet Invoicing
--
-- Defines:
--	im_timesheet_prices		List of prices with defaults
--

---------------------------------------------------------
-- Create an "invoice_id" field in im_hours to keep track
-- of invoice/non-invoice hours


create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count                 integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_hours'' and lower(column_name) = ''invoice_id'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_hours add invoice_id integer
		constraint im_hours_invoice_fk references im_costs;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



---------------------------------------------------------
-- Timesheet Invoices
--
-- We have made a "Timesheet Invoice" a separate object
-- mainly because it requires a different treatment when
-- it gets deleted, because of its interaction with
-- im_timesheet2_tasks and im_projects, that may get affected
-- affected (set back to the status "delivered") when a 
-- timesheet2-invoice is deleted.

select acs_object_type__create_type (
	'im_timesheet_invoice',		-- object_type
	'Timesheet Invoice',		-- pretty_name
	'Timesheet Invoices',		-- pretty_plural
	'im_invoice',			-- supertype
	'im_timesheet_invoices',	-- table_name
	'invoice_id',			-- id_column
	'intranet-timesheet2-invoices',	-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_timesheet_invoice__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_timesheet_invoice', 'im_timesheet_invoices', 'invoice_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_timesheet_invoice', 'im_invoices', 'invoice_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_timesheet_invoice', 'im_costs', 'cost_id');


update acs_object_types set
        status_type_table = 'im_costs',
        status_column = 'cost_status_id',
        type_column = 'cost_type_id'
where object_type = 'im_timesheet_invoice';

-- Add links to edit im_timesheet_invoices objects...
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_invoice','view','/intranet-invoices/view?invoice_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_invoice','edit','/intranet-invoices/new?invoice_id=');





create table im_timesheet_invoices (
	invoice_id		integer
				constraint im_timesheet_invoices_pk
				primary key
				constraint im_timesheet_invoices_fk
				references im_invoices,
	-- Start and end date of invoicing period
	invoice_period_start	timestamptz,
	invoice_period_end	timestamptz
);


create or replace function im_timesheet_invoice__new (
	integer,	--  default null
	varchar,	-- default im_timesheet_invoice
	timestamptz,	-- default now()
	integer,
	varchar,	-- default null
	integer,	-- default null
	varchar, 
	integer,
	integer,
	integer,	-- default null
	timestamptz,	-- default now()
	char,		-- default EUR
	integer,	-- default null
	integer,	-- default 602
	integer,	-- default 700
	integer,	-- default null
	integer,	-- default 30
	numeric,
	numeric,	-- default 0
	numeric,	-- default 0
	varchar		-- default null
) returns integer as '
DECLARE
	p_invoice_id		alias for $1;	-- invoice_id 
	p_object_type		alias for $2;	-- object_type
	p_creation_date		alias for $3;	-- creation_date
	p_creation_user		alias for $4;	-- creation_user
	p_creation_ip		alias for $5;	-- creation_ip
	p_context_id		alias for $6;	-- context_id
	p_invoice_nr		alias for $7;	-- invoice_nr
	p_customer_id		alias for $8;	-- company_id
	p_provider_id		alias for $9;	-- provider_id
	p_company_contact_id    alias for $10;	-- company_contact_id
	p_invoice_date		alias for $11;	-- invoice_date 
	p_invoice_currency	alias for $12;	-- invoice_currency
	p_invoice_template_id   alias for $13;	-- invoice_template_id
	p_invoice_status_id     alias for $14;	-- invoice_status_id
	p_invoice_type_id	alias for $15;	-- invoice_type_id
	p_payment_method_id     alias for $16;	-- payment_method_id
	p_payment_days		alias for $17;	-- payment_days
	p_amount		alias for $18;	-- amount
	p_vat			alias for $19;	-- vat
	p_tax			alias for $20;	-- tax 
	p_note			alias for $21;	-- note

	v_invoice_id			integer;
BEGIN
	v_invoice_id := im_invoice__new (
		p_invoice_id,
		p_object_type,	
		p_creation_date,
		p_creation_user,
		p_creation_ip,	
		p_context_id,	
		p_invoice_nr,	
		p_customer_id,	
		p_provider_id,	
		p_company_contact_id,
		p_invoice_date,
		p_invoice_currency,
		p_invoice_template_id,
		p_invoice_status_id,	
		p_invoice_type_id,
		p_payment_method_id,
		p_payment_days,
		p_amount,	
		p_vat,
		p_tax,
		p_note
	);

	-- insert to create a referential integrity constraint
	-- to avoid that im_invoices is used to delete such an
	-- invoice without resetting the im_timesheet_tasks and
	-- im_projects dependencies.
	insert into im_timesheet_invoices (
		invoice_id
	) values (
		v_invoice_id
	);

	return v_invoice_id;
end;' language 'plpgsql';


-- Delete a single invoice (if we know its ID...)
create or replace function  im_timesheet_invoice__delete (integer)
returns integer as '
DECLARE
	p_invoice_id	alias for $1;
BEGIN
	-- Reset the invoiced-flag of all invoiced tasks
	update	im_timesheet_tasks
	set	invoice_id = null
	where	invoice_id = p_invoice_id;

	-- Reset the invoiced-flag of all included hours
	update	im_hours
	set	invoice_id = null
	where	invoice_id = p_invoice_id;

	-- Compatibility for old invoices where cost_id
	-- indicated that hours belong to invoice
	update	im_hours
	set	cost_id = null
	where	cost_id = p_invoice_id;

	-- Erase the invoice itself
	delete from	im_timesheet_invoices
	where		invoice_id = p_invoice_id;

	-- Erase the CostItem
	PERFORM im_invoice__delete(p_invoice_id);

	return 0;
end;' language 'plpgsql';


create or replace function im_timesheet_invoice__name (integer) 
returns varchar as '
DECLARE
	p_invoice_id alias for $1;
	v_name	varchar;
BEGIN
	select	invoice_nr
	into	v_name
	from	im_invoices
	where	invoice_id = p_invoice_id;

	return v_name;
end;' language 'plpgsql';




---------------------------------------------------------
-- Timesheet Prices
--
-- The price model is very specific to every consulting business,
-- so we need to allow maximum customization.
-- On the TCL API-Level we asume that we are able to determine
-- a price for every im_timesheet_task, given the im_company and the
-- im_project.
-- What is missing here are promotions and other types of 
-- exceptions. However, discounts are handled on the level
-- of invoice, together with VAT and other taxes.
--
-- The price model for the Timesheet Industry is based on
-- the variables:
--	- UOM: Unit of Measure: Hours, Days, Units (licences), ...
--	- Customer: There may be different rates for each customer
--	- Material
--	- Task Type

create sequence im_timesheet_prices_seq start 10000;
create table im_timesheet_prices (
	price_id		integer 
				constraint im_timesheet_prices_pk
				primary key,
	--
	-- "Input variables"
	uom_id			integer not null 
				constraint im_timesheet_prices_uom_id
				references im_categories,
	company_id		integer not null 
				constraint im_timesheet_prices_company_id
				references im_companies,
	task_type_id		integer
				constraint im_timesheet_prices_task_type_id
				references im_categories,
	material_id		integer
				constraint im_timesheet_prices_material_fk
				references im_materials,
	valid_from		timestamptz,
	valid_through		timestamptz,
				-- make sure the end date is after start date
				constraint im_timesheet_prices_date_const
				check(valid_through - valid_from >= 0),
	--
	-- "Output variables"
	currency		char(3) references currency_codes(ISO),
	price			numeric(12,4)
);

-- make sure the same price doesn't get defined twice 
create unique index im_timesheet_price_idx on im_timesheet_prices (
	uom_id, company_id, task_type_id, material_id, currency
);


------------------------------------------------------
--

-- Calculate a match value between a price list item and an invoice_item
-- The higher the match value the better the fit.

create or replace function im_timesheet_prices_calc_relevancy ( 
       integer, integer, integer, integer, integer, integer
) returns numeric as '
DECLARE
	v_price_company_id		alias for $1;	
	v_item_company_id		alias for $2;
	v_price_task_type_id		alias for $3;
	v_item_task_type_id		alias for $4;
	v_price_material_id		alias for $5;
	v_item_material_id		alias for $6;

	match_value			numeric;
	v_internal_company_id		integer;
BEGIN
	match_value := 0;

	select company_id
	into v_internal_company_id
	from im_companies
	where company_path=''internal'';

	-- Hard matches for task type
	if v_price_task_type_id = v_item_task_type_id then
		match_value := match_value + 4;
	end if;
	if not(v_price_task_type_id is null) 
		and v_price_task_type_id != v_item_task_type_id then
		match_value := match_value - 4;
	end if;

	if v_price_material_id = v_item_material_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_material_id is null) 
		and v_price_material_id != v_item_material_id then
		match_value := match_value - 10;
	end if;

	-- Company logic - "Internal" doesnt give a penalty 
	-- but doesnt count as high as an exact match
	--
	if v_price_company_id = v_item_company_id then
		match_value := (match_value + 6)*2;
	end if;
	if v_price_company_id = v_internal_company_id then
		match_value := match_value + 1;
	end if;
	if v_price_company_id != v_internal_company_id 
		and v_price_company_id != v_item_company_id then
		match_value := match_value -10;
	end if;

	return match_value;
end;' language 'plpgsql';


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Core
-- to render the forum components in the Home, Users, Projects
-- and Company pages.
--
-- The TCL code in the "component_tcl" field is executed
-- via "im_component_bay" in an "uplevel" statemente, exactly
-- as if it would be written inside the .adp <%= ... %> tag.
-- I know that's relatively dirty, but TCL doesn't provide
-- another way of "late binding of component" ...

-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...


-- Show the timesheet specific fields in the ProjectViewPage
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Company Timesheet Prices',	-- plugin_name
	'intranet-timesheet2-invoices',	-- package_name
	'left',				-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_timesheet_price_component $user_id $company_id $return_url'
);


-- Add a "Timesheet Invoice" into the Invoice Menu
--
create or replace function inline_01 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_invoices_menu		integer;
	v_project_menu		integer;

	-- Groups
	v_accounting		integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_invoices_menu
    from im_menus
    where label=''finance'';

    v_menu := im_menu__new (
	null,				-- menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-timesheet2-invoices'', -- package_name
	''new_timesheet_invoice'',	-- label
	''New Timesheet Invoice'',	-- name
	''/intranet-timesheet2-invoices/invoices/new'',  -- url
	70,				-- sort_order
	v_invoices_menu,		-- parent_menu_id
	null				-- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_01 ();
drop function inline_01 ();




create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu				integer;
	v_invoices_new_menu		integer;
	v_new_timesheet_invoice_menu	integer;
	v_new_timesheet_quote_menu	integer;

	-- Groups
	v_accounting			integer;
	v_senman			integer;
	v_admins			integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_invoices_new_menu
    from im_menus
    where label=''invoices_customers'';

    v_menu := im_menu__new (
	null,					-- menu_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''intranet-timesheet2-invoices'',	-- package_name
	''invoices_timesheet_new_quote'',	-- label
	''New Quote from Timesheet Tasks'',	-- name
	''/intranet-timesheet2-invoices/invoices/new?target_cost_type_id=3702'',   -- url
	130,					-- sort_order
	v_invoices_new_menu,			-- parent_menu_id
	''[im_cost_type_write_p $user_id 3702]'' -- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    v_menu := im_menu__new (
	null,					-- menu_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''intranet-timesheet2-invoices'',	-- package_name
	''invoices_timesheet_new_cust_invoice'',-- label
	''New Customer Invoice from Timesheet Tasks'',	-- name
	''/intranet-timesheet2-invoices/invoices/new?target_cost_type_id=3700'',     -- url
	330,					-- sort_order
	v_invoices_new_menu,			-- parent_menu_id
	''[im_cost_type_write_p $user_id 3700]'' -- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();

\i ../common/intranet-timesheet2-invoices-common.sql
