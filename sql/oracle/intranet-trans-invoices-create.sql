-- /packages/intranet-trans-invoices/sql/oracle/intranet-trans-invoices-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Translation Invoicing for Project/Open
--
-- Defines:
--	im_trans_prices			List of prices with defaults
--

---------------------------------------------------------
-- Translation Prices
--
-- The price model is very specific to every translation business,
-- so we need to allow maximum customization.
-- On the TCL API-Level we asume that we are able to determine
-- a price for every im_task, given the im_customer and the
-- im_project.
-- What is missing here are promotions and other types of 
-- exceptions. However, discounts are handled on the level
-- of invoice, together with VAT and other taxes.
--
-- The price model for the Translation Industry is based on
-- the variables:
--	- UOM: Unit of Measure: Hours, source words, lines,...
--	- Customer: There may be different rates for each customer
--	- Task Type
--	- Target language
--	- Source language
--	- Subject Area

create sequence im_trans_prices_seq start with 10000;
create table im_trans_prices (
	price_id		integer 
				constraint im_trans_prices_pk
				primary key,
	--
	-- "Input variables"
	uom_id			integer not null 
				constraint im_trans_prices_uom_id
				references im_categories,
	customer_id		integer not null 
				constraint im_trans_prices_customer_id
				references im_customers,
	task_type_id		integer
				constraint im_trans_prices_task_type_id
				references im_categories,
	target_language_id	integer
				constraint im_trans_prices_target_lang
				references im_categories,
	source_language_id	integer
				constraint im_trans_prices_source_lang
				references im_categories,
	subject_area_id		integer
				constraint im_trans_prices_subject_are
				references im_categories,
	valid_from		date,
	valid_through		date,
				-- make sure the end date is after start date
				constraint im_trans_prices_date_const
				check(valid_through - valid_from >= 0),
	--
	-- "Output variables"
	currency		char(3) references currency_codes(ISO),
	price			number(12,2)
);

-- make sure the same price doesn't get defined twice 
create unique index im_price_idx on im_trans_prices (
	uom_id, customer_id, task_type_id, target_language_id, 
	source_language_id, subject_area_id, currency
);


------------------------------------------------------
-- Views to Business Objects
--

-- Calculate a match value between a price list item and an invoice_item
-- The higher the match value the better the fit.
create or replace function im_trans_prices_calc_relevancy ( 
	v_price_customer_id IN integer,		v_item_customer_id IN integer,
	v_price_task_type_id IN integer,	v_item_task_type_id IN integer,
	v_price_subject_area_id IN integer,	v_item_subject_area_id IN integer,
	v_price_target_language_id IN integer,	v_item_target_language_id IN integer,
	v_price_source_language_id IN integer,	v_item_source_language_id IN integer
)
RETURN number IS
	match_value		number;
BEGIN
	match_value := 0;

	if v_price_task_type_id = v_item_task_type_id then
	match_value := match_value + 4;
	end if;
	if not(v_price_task_type_id is null) and v_price_task_type_id != v_item_task_type_id then
	match_value := match_value - 4;
	end if;
	if v_price_source_language_id = v_item_source_language_id then
	match_value := match_value + 3;
	end if;
	if not(v_price_source_language_id is null) and v_price_source_language_id != v_item_source_language_id then
	match_value := match_value - 10;
	end if;
	if v_price_target_language_id = v_item_target_language_id then
	match_value := match_value + 2;
	end if;
	if not(v_price_target_language_id is null) and v_price_target_language_id != v_item_target_language_id then
	match_value := match_value - 10;
	end if;
	if v_price_subject_area_id = v_item_subject_area_id then
	match_value := match_value + 1;
	end if;
	if not(v_price_subject_area_id is null) and v_price_subject_area_id != v_item_subject_area_id then
	match_value := match_value - 10;
	end if;
	if v_price_customer_id = v_item_customer_id then
	match_value := (match_value + 6)*2;
	end if;
	if v_price_customer_id = 17 then
	match_value := match_value + 1;
	end if;
	if v_price_customer_id != 17 and v_price_customer_id != v_item_customer_id then
	match_value := match_value -10;
	end if;
	return match_value;
END;
/
show errors;

-- Calculate the price for a task_type/customer
create or replace function im_trans_prices_calc_price ( 
	v_customer_id IN integer,
	v_project_id IN integer,
	v_task_type_id IN integer,
	v_task_uom_id IN integer
)
RETURN number IS
BEGIN
	if v_task_uom_id = 320 then
	return 30.00;
	end if;
	if v_task_uom_id = 324 then
	return 0.085;
	end if;
	return 1.000;
END;
/
show errors;

-- What currency to use?
create or replace function im_trans_prices_calc_currency (v_customer_id IN integer)
RETURN varchar IS
BEGIN
	return 'EUR';
END;
/
show errors;


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Project/Open Core
-- to render the forum components in the Home, Users, Projects
-- and Customer pages.
--
-- The TCL code in the "component_tcl" field is executed
-- via "im_component_bay" in an "uplevel" statemente, exactly
-- as if it would be written inside the .adp <%= ... %> tag.
-- I know that's relatively dirty, but TCL doesn't provide
-- another way of "late binding of component" ...

-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-trans-invoices');
    im_menu.del_module(module_name => 'intranet-trans-invoices');
END;
/
commit;

-- Add a "Translation Invoice" into the Invoice Menu
--
declare
        -- Menu IDs
        v_menu                  integer;
	v_invoices_menu		integer;

        -- Groups
        v_accounting            integer;
        v_senman                integer;
        v_customers             integer;
        v_freelancers           integer;
        v_admins                integer;
begin

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_customers from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_invoices_menu
    from im_menus
    where package_name='intranet-invoices' and label='invoices';

    v_menu := im_menu.new (
	package_name =>	'intranet-trans-invoices',
	label =>	'new_trans_invoice',
	name =>		'New Trans Invoice',
	url =>		'/intranet-trans-invoices/new',
	sort_order =>	70,
	parent_menu_id => v_invoices_menu
    );

    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_customers, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');
end;
/
commit;
	

