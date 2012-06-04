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
-- Translation Invoices
--
-- We have made a "Translation Invoice" a separate object
-- mainly because it requires a different treatment when
-- it gets deleted, because of its interaction with
-- im_trans_tasks and im_projects, that are affected
-- (set back to the status "delivered") when a trans-invoice
-- is deleted.


create table im_trans_invoices (
	invoice_id		integer
				constraint im_trans_invoices_pk
				primary key
				constraint im_trans_invoices_fk
				references im_invoices
);


begin
    acs_object_type.create_type (
	supertype =>		'im_invoice',
	object_type =>		'im_trans_invoice',
	pretty_name =>		'Trans Invoice',
	pretty_plural =>	'Trans Invoices',
	table_name =>		'im_trans_invoices',
	id_column =>		'invoice_id',
	package_name =>		'im_trans_invoice',
	type_extension_table => null,
	name_method =>		'im_trans_invoice.name'
    );
end;
/
show errors


create or replace package im_trans_invoice
is
    function new (
	invoice_id		in integer default null,
	object_type		in varchar default 'im_trans_invoice',
	creation_date		in date default sysdate,
	creation_user		in integer,
	creation_ip		in varchar default null,
	context_id		in integer default null,
	invoice_nr		in varchar,
	customer_id		in integer,
	provider_id		in integer,
	company_contact_id	in integer default null,
	invoice_date		in date default sysdate,
	invoice_currency	in char default 'EUR',
	invoice_template_id	in integer default null,
	invoice_status_id	in integer default 602,
	invoice_type_id		in integer default 700,
	payment_method_id	in integer default null,
	payment_days		in integer default 30,
	amount			in number default 0,
	vat			in number default 0,
	tax			in number default 0,
	note			in varchar default null
    ) return im_trans_invoices.invoice_id%TYPE;

    procedure delete (invoice_id in integer);
    function name (invoice_id in integer) return varchar;
end im_trans_invoice;
/
show errors

create or replace package body im_trans_invoice
is
    function new (
	invoice_id		in integer default null,
	object_type		in varchar default 'im_trans_invoice',
	creation_date		in date default sysdate,
	creation_user		in integer,
	creation_ip		in varchar default null,
	context_id		in integer default null,
	invoice_nr		in varchar,
	customer_id		in integer,
	provider_id		in integer,
	company_contact_id	in integer default null,
	invoice_date		in date default sysdate,
	invoice_currency	in char default 'EUR',
	invoice_template_id	in integer default null,
	invoice_status_id	in integer default 602,
	invoice_type_id		in integer default 700,
	payment_method_id	in integer default null,
	payment_days		in integer default 30,
	amount			in number default 0,
	vat			in number default 0,
	tax			in number default 0,
	note			in varchar default null
    ) return im_trans_invoices.invoice_id%TYPE
    is
	v_invoice_id	im_trans_invoices.invoice_id%TYPE;
    begin

	v_invoice_id := im_invoice.new(
		invoice_id		=> invoice_id,
		object_type		=> object_type,
		creation_date		=> creation_date,
		creation_user		=> creation_user,
		creation_ip		=> creation_ip,
		context_id		=> context_id,
		invoice_nr		=> invoice_nr,
		customer_id		=> customer_id,
		provider_id		=> provider_id,
		company_contact_id	=> company_contact_id,
		invoice_date		=> invoice_date,
		invoice_currency	=> invoice_currency,
		invoice_template_id     => invoice_template_id,
		invoice_status_id	=> invoice_status_id,
		invoice_type_id		=> invoice_type_id,
		payment_method_id	=> payment_method_id,
		payment_days		=> payment_days,
		amount			=> amount,
		vat			=> vat,
		tax			=> tax,
		note			=> note
	);

	-- insert to create a referential integrity constraint
	-- to avoid that im_invoices is used to delete such an
	-- invoice without resetting the im_trans_tasks and
	-- im_projects dependencies.
	insert into im_trans_invoices (
		invoice_id
	) values (
		v_invoice_id
	);

	return v_invoice_id;
    end new;

    -- Delete a single invoice (if we know its ID...)
    procedure delete (invoice_id in integer)
    is
    begin
	-- Reset the status of all invoiced tasks to delivered.
	update	im_trans_tasks t
	set	invoice_id = null
	where	t.invoice_id = delete.invoice_id;

	-- Erase the invoice itself
	delete from 	im_trans_invoices
	where		invoice_id = delete.invoice_id;

	-- Erase the CostItem
	im_invoice.delete(delete.invoice_id);
    end delete;


    function name (invoice_id in integer) return varchar
    is
	v_name	varchar;
    begin
	select	invoice_nr
	into	v_name
	from	im_invoices
	where	invoice_id = name.invoice_id;

	return v_name;
    end name;

end im_trans_invoice;
/
show errors


---------------------------------------------------------
-- Translation Prices
--
-- The price model is very specific to every translation business,
-- so we need to allow maximum customization.
-- On the TCL API-Level we asume that we are able to determine
-- a price for every im_task, given the im_company and the
-- im_project.
-- What is missing here are promotions and other types of 
-- exceptions. However, discounts are handled on the level
-- of invoice, together with VAT and other taxes.
--
-- The price model for the Translation Industry is based on
-- the variables:
--	- UOM: Unit of Measure: Hours, source words, lines,...
--	- Company: There may be different rates for each company
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
	company_id		integer not null 
				constraint im_trans_prices_company_id
				references im_companies,
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
	price			number(12,4)
);

-- make sure the same price doesn't get defined twice 
create unique index im_price_idx on im_trans_prices (
	uom_id, company_id, task_type_id, target_language_id, 
	source_language_id, subject_area_id, currency
);


------------------------------------------------------
-- Parametric Matching - find the right price for
-- a translation task
--

-- Calculate a match value between a price list item and an invoice_item
-- The higher the match value the better the fit.
prompt *** Creating im_trans_prices_calc_relevancy
create or replace function im_trans_prices_calc_relevancy ( 
	v_price_company_id IN integer,		v_item_company_id IN integer,
	v_price_task_type_id IN integer,	v_item_task_type_id IN integer,
	v_price_subject_area_id IN integer,	v_item_subject_area_id IN integer,
	v_price_target_language_id IN integer,	v_item_target_language_id IN integer,
	v_price_source_language_id IN integer,	v_item_source_language_id IN integer
)
RETURN number IS
	match_value			number;
	v_internal_company_id		integer;
	v_price_target_language		varchar;
	v_item_target_language		varchar;
	v_price_source_language		varchar;
	v_item_source_language		varchar;
BEGIN
	match_value := 0;

	select company_id
	into v_internal_company_id
	from im_companies
	where company_path='internal';

	-- Hard matches for task type
	if v_price_task_type_id = v_item_task_type_id then
		match_value := match_value + 4;
	end if;
	if not(v_price_task_type_id is null) and v_price_task_type_id != v_item_task_type_id then
		match_value := match_value - 4;
	end if;

	-- Default matching for source language:
	-- "de" <-> "de_DE" = + 1
	-- "de_DE" <-> "de_DE" = +3
	-- "es" <-> "de_DE" = -10
	if (v_price_source_language_id is not null) and  (v_item_source_language_id is not null) then
		-- only add or subtract match_values if both are defined...
		select	category
		into	v_price_source_language
		from	im_categories
		where	category_id = v_price_source_language_id;
	
		select	category
		into	v_item_source_language
		from	im_categories
		where	category_id = v_item_source_language_id;

		if substr(v_price_source_language,1,2) = substr(v_item_source_language,1,2) then
			-- the main part of the language have matched
			match_value := match_value + 2;
			if v_price_source_language_id = v_item_source_language_id then
				-- the main part have matched and the country variants are the same
				match_value := match_value + 1;
			end if;
		else
			match_value := match_value - 10;
		end if;
	end if;


	-- Default matching for target language:
	if (v_price_target_language_id is not null) and  (v_item_target_language_id is not null) then
		-- only add or subtract match_values if both are defined...
		select	category
		into	v_price_target_language
		from	im_categories
		where	category_id = v_price_target_language_id;
	
		select	category
		into	v_item_target_language
		from	im_categories
		where	category_id = v_item_target_language_id;

		if substr(v_price_target_language,1,2) = substr(v_item_target_language,1,2) then
			-- the main part of the language have matched
			match_value := match_value + 1;		
			if v_price_target_language_id = v_item_target_language_id then
				-- the main part have matched and the country variants are the same
				match_value := match_value + 1;
			end if;
		else
			match_value := match_value - 10;
		end if;
	end if;


	if v_price_subject_area_id = v_item_subject_area_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_subject_area_id is null) and v_price_subject_area_id != v_item_subject_area_id then
		match_value := match_value - 10;
	end if;

	-- Company logic - "Internal" doesn't give a penalty 
	-- but doesn't count as high as an exact match
	--
	if v_price_company_id = v_item_company_id then
		match_value := (match_value + 6)*2;
	end if;
	if v_price_company_id = v_internal_company_id then
		match_value := match_value + 1;
	end if;
	if v_price_company_id != v_internal_company_id and v_price_company_id != v_item_company_id then
		match_value := match_value -10;
	end if;

	return match_value;
END;
/
show errors;

---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Project/Open Core
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

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-trans-invoices');
    im_menu.del_module(module_name => 'intranet-trans-invoices');
END;
/
commit;



-- Show the translation specific fields in the ProjectViewPage
--
declare
    v_plugin	 integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>  'Company Translation Prices',
	package_name => 'intranet-trans-invoices',
	page_url =>     '/intranet/companies/view',
	location =>     'left',
	sort_order =>   100,
	component_tcl =>
	'im_trans_price_component \
		$user_id \
		$company_id \
		$return_url'
    );
end;
/




-- Add a "Translation Invoice" into the Invoice Menu
--
declare
	-- Menu IDs
	v_menu			integer;
	v_invoices_menu		integer;
	v_project_menu		integer;

	-- Groups
	v_accounting		 integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_companies from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_invoices_menu
    from im_menus
    where label='finance';

    v_menu := im_menu.new (
	package_name =>	'intranet-trans-invoices',
	label =>	'new_trans_invoice',
	name =>		'New Trans Invoice',
	url =>		'/intranet-trans-invoices/invoices/new',
	sort_order =>	70,
	parent_menu_id => v_invoices_menu
    );

    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');

    select menu_id
    into v_project_menu
    from im_menus
    where label='project';

end;
/
commit;
	


@../common/intranet-trans-invoices-common.sql
@../common/intranet-trans-invoices-backup.sql
