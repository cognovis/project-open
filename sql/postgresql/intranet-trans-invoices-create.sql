-- /packages/intranet-trans-invoices/sql/postgresql/intranet-trans-invoices-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

-- Translation Invoicing for ]project-open[
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


select acs_object_type__create_type (
	'im_trans_invoice',		-- object_type
	'Trans Invoice',		-- pretty_name
	'Trans Invoices',		-- pretty_plural
	'im_invoice',			-- supertype
	'im_trans_invoices',		-- table_name
	'invoice_id',			-- id_column
	'im_trans_invoice',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_trans_invoice__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_trans_invoice', 'im_trans_invoices', 'invoice_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_trans_invoice', 'im_invoices', 'invoice_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_trans_invoice', 'im_costs', 'cost_id');


update acs_object_types set
	status_type_table = 'im_costs',
	status_column = 'cost_status_id',
	type_column = 'cost_type_id'
where object_type = 'im_trans_invoice';

create table im_trans_invoices (
	invoice_id		integer
				constraint im_trans_invoices_pk
				primary key
				constraint im_trans_invoices_fk
				references im_invoices
);


create or replace function im_trans_invoice__new (
	integer,	-- default null
	varchar,	-- default im_trans_invoice
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
	p_company_contact_id	alias for $10;	-- company_contact_id
	p_invoice_date		alias for $11;	-- invoice_date 
	p_invoice_currency	alias for $12;	-- invoice_currency
	p_invoice_template_id	alias for $13;	-- invoice_template_id
	p_invoice_status_id	alias for $14;	-- invoice_status_id
	p_invoice_type_id	alias for $15;	-- invoice_type_id
	p_payment_method_id	alias for $16;	-- payment_method_id
	p_payment_days		alias for $17;	-- payment_days
	p_amount		alias for $18;	-- amount
	p_vat			alias for $19;	-- vat
	p_tax			alias for $20;	-- tax 
	p_note			alias for $21;	-- note

	v_invoice_id		integer;
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
	-- invoice without resetting the im_trans_tasks and
	-- im_projects dependencies.
	insert into im_trans_invoices (
		invoice_id
	) values (
		v_invoice_id
	);

	return v_invoice_id;
end;' language 'plpgsql';


-- Delete a single invoice (if we know its ID...)
-- DONT reset projects to status delivered anymore.
-- This should be done via a wizard or similar.
create or replace function im_trans_invoice__delete (integer)
returns integer as '
DECLARE
	p_invoice_id	alias for $1;
BEGIN
	-- Reset the status of all invoiced tasks to delivered.
	update	im_trans_tasks
	set	invoice_id = null
	where	invoice_id = p_invoice_id;

	-- Erase the invoice itself
	delete from im_trans_invoices
	where invoice_id = p_invoice_id;

	-- Erase the CostItem
	PERFORM im_invoice__delete(p_invoice_id);

	return 0;
end;' language 'plpgsql';


create or replace function im_trans_invoice__name (integer) 
returns varchar as '
DECLARE
	p_invoice_id		alias for $1;
	v_name			varchar;
BEGIN
	select	invoice_nr
	into	v_name
	from	im_invoices
	where	invoice_id = p_invoice_id;

	return v_name;
end;' language 'plpgsql';




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

create sequence im_trans_prices_seq start 10000;
create table im_trans_prices (
	price_id		integer 
				constraint im_trans_prices_pk
				primary key,
	--
	-- "Input variables"
	uom_id			integer not null 
				constraint im_trans_prices_uom_fk
				references im_categories,
	company_id		integer not null 
				constraint im_trans_prices_company_fk
				references im_companies,
	task_type_id		integer
				constraint im_trans_prices_task_type_fk
				references im_categories,
	target_language_id	integer
				constraint im_trans_prices_target_fk
				references im_categories,
	source_language_id	integer
				constraint im_trans_prices_source_flg
				references im_categories,
	subject_area_id		integer
				constraint im_trans_prices_subject_fk
				references im_categories,
	file_type_id		integer
				constraint im_trans_prices_file_type_fk
				references im_categories,
	valid_from		timestamptz,
	valid_through		timestamptz,
				-- make sure the end date is after start date
				constraint im_trans_prices_date_const
				check(valid_through - valid_from >= 0),
	--
	-- "Output variables"
	currency		char(3) references currency_codes(ISO)
				constraint im_trans_prices_currency_nn
				not null,
	price			numeric(12,4)
				constraint im_trans_prices_price_nn
				not null,
	min_price		numeric(12,4),
	note			text
);

-- make sure the same price doesn't get defined twice 
create unique index im_trans_price_idx on im_trans_prices (
	uom_id, company_id, task_type_id, target_language_id, 
	source_language_id, subject_area_id, file_type_id, currency
);


------------------------------------------------------
-- Views to Business Objects
--

-- Calculate a match value between a price list item and a task
-- The higher the match value the better the fit.


-- Compatibility with previous version
create or replace function im_trans_prices_calc_relevancy ( 
	integer, integer, integer, integer, integer, integer, integer, integer, integer, integer
) returns numeric as '
DECLARE
	v_price_company_id		alias for $1;		
	v_item_company_id		alias for $2;
	v_price_task_type_id		alias for $3;	
	v_item_task_type_id		alias for $4;
	v_price_subject_area_id		alias for $5;	
	v_item_subject_area_id		alias for $6;
	v_price_target_language_id	alias for $7;	
	v_item_target_language_id	alias for $8;
	v_price_source_language_id	alias for $9;	
	v_item_source_language_id	alias for $10;
BEGIN
	return im_trans_prices_calc_relevancy(
		v_price_company_id,
		v_item_company_id,
		v_price_task_type_id,
		v_item_task_type_id,
		v_price_subject_area_id,
		v_item_subject_area_id,
		v_price_target_language_id,
		v_item_target_language_id,
		v_price_source_language_id,
		v_item_source_language_id,
		0, 0
	);
end;' language 'plpgsql';





-- Determine the filetype from a translation task
create or replace function im_file_type_from_trans_task (integer)
returns integer as '
DECLARE
	p_task_id	alias for $1;

	v_task_name	varchar;
	v_extension	varchar;
	v_result	integer;
BEGIN
	select	task_filename
	into	v_task_name
	from	im_trans_tasks
	where	task_id = p_task_id;

	v_extension := lower(substring(v_task_name from length(v_task_name)-2));
	-- RAISE NOTICE ''%'', v_extension;

	select	min(category_id)
	into	v_result
	from	im_categories
	where	category_type = ''Intranet Translation File Type''
		and aux_string1 = v_extension;

	return v_result;
end;' language 'plpgsql';





-- New procedure with added filetype
create or replace function im_trans_prices_calc_relevancy ( 
	integer, integer, integer, integer, integer, integer, 
	integer, integer, integer, integer, integer, integer
) returns numeric as '
DECLARE
	v_price_company_id		alias for $1;		
	v_item_company_id		alias for $2;
	v_price_task_type_id		alias for $3;	
	v_item_task_type_id		alias for $4;
	v_price_subject_area_id		alias for $5;	
	v_item_subject_area_id		alias for $6;
	v_price_target_language_id	alias for $7;	
	v_item_target_language_id	alias for $8;
	v_price_source_language_id	alias for $9;	
	v_item_source_language_id	alias for $10;
	v_price_file_type_id		alias for $11;
	v_item_file_type_id		alias for $12;

	match_value			numeric;
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
	where company_path=''internal'';

	-- Hard matches for task type
	if v_price_task_type_id = v_item_task_type_id then
		match_value := match_value + 8;
	end if;
	if not(v_price_task_type_id is null) and v_price_task_type_id != v_item_task_type_id then
		match_value := match_value - 8;
	end if;

	-- Default matching for source language:
	-- "de" <-> "de_DE" = + 1
	-- "de_DE" <-> "de_DE" = +3
	-- "es" <-> "de_DE" = -10
	if (v_price_source_language_id is not null) and	(v_item_source_language_id is not null) then
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
	if (v_price_target_language_id is not null) and	(v_item_target_language_id is not null) then
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

	-- Subject Area
	if v_price_subject_area_id = v_item_subject_area_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_subject_area_id is null) and v_price_subject_area_id != v_item_subject_area_id then
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
	if v_price_company_id != v_internal_company_id and v_price_company_id != v_item_company_id then
		match_value := match_value -100;
	end if;


	-- File Type
	if v_price_file_type_id = v_item_file_type_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_file_type_id is null) and v_price_file_type_id != v_item_file_type_id then
		match_value := match_value - 10;
	end if;


	return match_value;
end;' language 'plpgsql';


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of ]project-open[ Core
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


-- Show the translation specific fields in the ProjectViewPage
--
select im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Company Translation Prices',	-- plugin_name
	'intranet-trans-invoices',	-- package_name
	'left',				-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_trans_price_component $user_id $company_id $return_url'
);


-- Add a "Translation Invoice" into the Invoice Menu
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
		null,			-- menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-trans-invoices'',	-- package_name
		''new_trans_invoice'',	-- label
		''New Trans Invoice'',	-- name
		''/intranet-trans-invoices/invoices/new'',	-- url
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
	v_menu			integer;
	v_invoices_new_menu	integer;
	v_new_trans_invoice_menu integer;
	v_new_trans_quote_menu	integer;

	v_accounting		integer;
	v_senman		integer;
	v_admins		integer;
begin

	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';

	select menu_id into v_invoices_new_menu from im_menus
	where label=''invoices_customers'';

	v_menu := im_menu__new (
		null,					-- menu_id
		''im_menu'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-trans-invoices'',		-- package_name
		''invoices_trans_new_quote'',		-- label
		''New Quote from Translation Tasks'',	-- name
		''/intranet-trans-invoices/invoices/new?target_cost_type_id=3702'',	-- url
		140,					-- sort_order
		v_invoices_new_menu,			-- parent_menu_id
		''[im_cost_type_write_p $user_id 3702]'' -- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	v_menu := im_menu__new (
		null,					-- menu_id
		''im_menu'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-trans-invoices'',		-- package_name
		''invoices_trans_new_cust_invoice'',	-- label
		''New Customer Invoice from Translation Tasks'',	-- name
		''/intranet-trans-invoices/invoices/new?target_cost_type_id=3700'',	-- url
		340,					-- sort_order
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

\i ../common/intranet-trans-invoices-common.sql
\i ../common/intranet-trans-invoices-backup.sql



insert into im_categories (category_id, category, category_type) values
(600, 'MS-Word', 'Intranet Translation File Type');
insert into im_categories (category_id, category, category_type) values
(602, 'MS-Excel', 'Intranet Translation File Type');
insert into im_categories (category_id, category, category_type) values
(604, 'MS-PowerPoint', 'Intranet Translation File Type');

