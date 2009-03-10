-- /packages/intranet-cost/sql/postgresql/intranet-cost-create.sql
--
-- ]project-open[ "Costs" Financial Base Module
-- Copyright (C) 2004 - 2009 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>
--
-- 040207 frank.bergmann@project-open.com
-- 040917 avila@digiteix.com 


-------------------------------------------------------------
-- "Cost Centers"
--
-- Cost Centers (actually: cost-, revenue- and investment centers) 
-- are used to model the organizational hierarchy of a company. 
-- Departments are just a special kind of cost centers.
-- Please note that this hierarchy is completely independet of the
-- is-manager-of hierarchy between employees.
--
-- Centers (cost centers) are a "vertical" structure following
-- the organigram of a company, as oposed to "horizontal" structures
-- such as projects.
--
-- Center_id references groups. This group is the "admin group"
-- of this center and refers to the users who are allowed to
-- use or administer the center. Admin members are allowed to
-- change the center data. ToDo: It is not clear what it means to 
-- be a regular menber of the admin group.
--
-- The manager_id is the person ultimately responsible for
-- the center. He or she becomes automatically "admin" member
-- of the "admin group".
--
-- Access to centers are controled using the OpenACS permission
-- system. Privileges include:
--	- administrate
--	- input_costs
--	- confirm_costs
--	- propose_budget
--	- confirm_budget

\i ../common/intranet-cost-common.sql



SELECT acs_object_type__create_type (
		'im_cost_center',	-- object_type
		'Cost Center',		-- pretty_name
		'Cost Centers',		-- pretty_plural	
		'acs_object',		-- supertype
		'im_cost_centers',	-- table_name
		'cost_center_id',	-- id_column
		'im_cost_center',	-- package_name
		'f',			-- abstract_p
		null,			-- type_extension_table
		'im_cost_center__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_cost_center', 'im_cost_centers', 'cost_center_id');


-- Creating URLs for viewing/editing cost centers
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost_center','view','/intranet-cost/cost-centers/new?form_mode=display\&cost_center_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost_center','edit','/intranet-cost/cost-centers/new?form_mode=edit\&cost_center_id=');

update acs_object_types set
	status_type_table = 'im_cost_centers',
	status_column = 'cost_center_status_id',
	type_column = 'cost_center_type_id'
where object_type = 'im_cost_center';



create table im_cost_centers (
	cost_center_id		integer
				constraint im_cost_centers_pk
				primary key
				constraint im_cost_centers_id_fk
				references acs_objects,
	cost_center_name	text
				constraint im_cost_centers_name_nn
				not null,
	cost_center_label	varchar(100)
				constraint im_cost_centers_label_nn
				not null
				constraint im_cost_centers_label_un
				unique,
				-- Hierarchical upper case code for cost center 
				-- with two characters for each level:
				-- ""=Company, "Ad"=Administration, "Op"=Operations,
				-- "OpAn"=Operations/Analysis, ...
	cost_center_code	varchar(400)
				constraint im_cost_centers_code_nn
				not null,
	cost_center_type_id	integer not null
				constraint im_cost_centers_type_fk
				references im_categories,
	cost_center_status_id	integer not null
				constraint im_cost_centers_status_fk
				references im_categories,
				-- Is this a department?
	department_p		char(1)
				constraint im_cost_centers_dept_p_ck
				check(department_p in ('t','f')),
				-- Where to report costs?
				-- The toplevel_center has parent_id=null.
	parent_id		integer 
				constraint im_cost_centers_parent_fk
				references im_cost_centers,
				-- Who is responsible for this cost_center?
	manager_id		integer
				constraint im_cost_centers_manager_fk
				references users,
	description		text,
	note			text,
		-- don't allow two cost centers under the same parent
		constraint im_cost_centers_un
		unique(cost_center_name, parent_id)
);
create index im_cost_centers_parent_id_idx on im_cost_centers(parent_id);
create index im_cost_centers_manager_id_idx on im_cost_centers(manager_id);



-- prompt *** intranet-costs: Creating im_cost_center
-- create or replace package im_cost_center
-- is
create or replace function im_cost_center__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, integer, integer, integer, char, varchar, varchar)
returns integer as '
DECLARE
	p_cost_center_id alias for $1;		-- cost_center_id  default null
	p_object_type	alias for $2;		-- object_type default ''im_cost_center''
	p_creation_date	alias for $3;		-- creation_date default now()
	p_creation_user alias for $4;		-- creation_user default null
	p_creation_ip	alias for $5;		-- creation_ip default null
	p_context_id	alias for $6;		-- context_id default null
	p_cost_center_name alias for $7;	-- cost_center_name
	p_cost_center_label alias for $8;	-- cost_center_label
	p_cost_center_code	alias for $9;	-- cost_center_code
	p_type_id		alias for $10;	-- type_id
	p_status_id		alias for $11;	-- status_id
	p_parent_id		alias for $12;	-- parent_id
	p_manager_id		alias for $13;	-- manager_id default null
	p_department_p		alias for $14;	-- department_p default ''t''
	p_description		alias for $15;	-- description default null
	p_note			alias for $16;	-- note default null
	v_cost_center_id	integer;
 BEGIN
	v_cost_center_id := acs_object__new (
		p_cost_center_id,		-- object_id
		p_object_type,			-- object_type
		p_creation_date,		-- creation_date
		p_creation_user,		-- creation_user
		p_creation_ip,			-- creation_ip
		p_context_id,			-- context_id
		''t''				-- security_inherit_p
	);

	insert into im_cost_centers (
		cost_center_id, 
		cost_center_name, cost_center_label,
		cost_center_code,
		cost_center_type_id, cost_center_status_id, 
		parent_id, manager_id,
		department_p,
		description, note
	) values (
		v_cost_center_id, 
		p_cost_center_name, p_cost_center_label,
		p_cost_center_code,
		p_type_id, p_status_id, 
		p_parent_id, p_manager_id, 
		p_department_p,
		p_description, p_note
	);
	return v_cost_center_id;
end;' language 'plpgsql';


-- Delete a single cost_center (if we know its ID...)
create or replace function im_cost_center__delete (integer)
returns integer as '
DECLARE 
	p_cost_center_id	alias for $1;	-- cost_center_id
	v_cost_center_id	integer;
begin
	-- copy the variable to desambiguate the var name
	v_cost_center_id := p_cost_center_id;

	-- Erase the im_cost_centers item associated with the id
	delete from im_cost_centers
	where cost_center_id = v_cost_center_id;

	-- Erase all the priviledges
	delete from acs_permissions
	where object_id = v_cost_center_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(v_cost_center_id);
	return 0;
end;' language 'plpgsql';

create or replace function im_cost_center__name (integer)
returns varchar as '
DECLARE
	p_cost_center_id alias for $1;		-- cost_center_id
	v_name	varchar;
BEGIN
	select	cost_center_name
	into	v_name
	from	im_cost_centers
	where	cost_center_id = p_cost_center_id;
	return v_name;
end;' language 'plpgsql';


-------------------------------------------------------------
-- Department View
-- (for compatibility reasons)
create or replace view im_departments as
select 
	cost_center_id as department_id,
	cost_center_name as department
from
	im_cost_centers
where
	department_p = 't';



-------------------------------------------------------------
-- Setup the cost_centers of a small consulting company that
-- offers strategic consulting projects and IT projects,
-- both following a fixed methodology (number project phases).


-- Creating sample cost center configuration
delete from im_cost_centers;
create or replace function inline_0 ()
returns integer as '
declare
	v_the_company_center		integer;
	v_administrative_center		integer;
	v_utilities_center		integer;
	v_marketing_center		integer;
	v_sales_center			integer;
	v_it_center			integer;
	v_projects_center		integer;
begin

	-- -----------------------------------------------------
	-- Main Center
	-- -----------------------------------------------------

	-- The Company itself: Profit Center (3002) with status "Active" (3101)
	-- This should be the only center with parent=null...
	v_the_company_center := im_cost_center__new (
		null,			-- cost_centee_id
		''im_cost_center'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''The Company'',	-- cost_center_name
		''company'',		-- cost_center_label
		''Co'',			-- cost_center_code
		3002,			-- type_id
		3101,			-- status_id
		null,			-- parent_id
		null,			-- manager_id
		''f'',			-- department_p
		''The top level center of the company'',	-- description
		''''			-- note
	);

	-- -----------------------------------------------------
	-- Sub Centers
	-- -----------------------------------------------------

	-- The Administrative Dept.: A typical cost center (3001)
	-- We asume a small company, so there is only one manager 
	-- taking budget control of Finance, Accounting, Legal and 
	-- HR stuff.
	--
	v_administrative_center := im_cost_center__new (
		null,			-- cost_centee_id
		''im_cost_center'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''Administration'',	-- cost_center_name
		''admin'',		-- cost_center_label
		''CoAd'',		-- cost_center_code
		3001,			-- type_id
		3101,			-- status_id
		v_the_company_center,	-- parent_id
		null,			-- manager_id
		''t'',			-- department_p
		''Administration Cervice Center'', -- description
		''''			-- note
	);

	-- Utilities Cost Center (3001)
	--
	v_utilities_center := im_cost_center__new (
		null,			-- cost_centee_id
		''im_cost_center'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''Rent and Utilities'',	-- cost_center_name
		''utilities'',		-- cost_center_label
		''CoUt'',		-- cost_center_code
		3001,			-- type_id
		3101,			-- status_id
		v_the_company_center,	-- parent_id
		null,			-- manager_id
		''f'',			-- department_p
		''Covers all repetitive costs such as rent, telephone, internet connectivity, ...'', -- description
		''''			-- note
	);

	-- Sales Cost Center (3001)
	--
	v_sales_center := im_cost_center__new (
		null,			-- cost_centee_id
		''im_cost_center'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''Sales'',		-- cost_center_name
		''sales'',		-- cost_center_label
		''CoSa'',		-- cost_center_code
		3001,			-- type_id
		3101,			-- status_id
		v_the_company_center,	-- parent_id
		null,			-- manager_id
		''t'',			-- department_p
		''Records all sales related activities, as oposed to marketing.'', -- description
		''''			-- note
	);

	-- Marketing Cost Center (3001)
	--
	v_marketing_center := im_cost_center__new (
		null,			-- cost_centee_id
		''im_cost_center'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''Marketing'',		-- cost_center_name
		''marketing'',		-- cost_center_label
		''CoMa'',		-- cost_center_code
		3001,			-- type_id
		3101,			-- status_id
		v_the_company_center,	-- parent_id
		null,			-- manager_id
		''t'',			-- department_p
		''Marketing activities, such as website, promo material, ...'', -- description
		''''			-- note
	);

	-- Project Operations Cost Center (3001)
	--
	v_projects_center := im_cost_center__new (
	null,			-- cost_centee_id
		''im_cost_center'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''Operations'',		-- cost_center_name
		''operations'',		-- cost_center_label
		''CoOp'',		-- cost_center_code
		3001,			-- type_id
		3101,			-- status_id
		v_the_company_center,	-- parent_id
		null,			-- manager_id
		''t'',			-- department_p
		''Covers all phases of project-oriented execution activities..'', -- description
		''''			-- note
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-------------------------------------------------------------
-- Update the context_id field of the "Co - The Company"
-- so that permissions are inherited from SubSite
--
create or replace function inline_0 ()
returns integer as '
DECLARE
	v_subsite_id		integer;
BEGIN
	-- Get the Main Site id, used as the global identified for permissions
	select package_id into v_subsite_id from apm_packages
	where package_key=''acs-subsite'';

	update acs_objects
		set context_id = v_subsite_id
	where object_id in (
			select cost_center_id
			from im_cost_centers
			where cost_center_label=''company''
		);

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



-------------------------------------------------------------
-- Update the context_id fields of the cost centers,
-- so that permissions are inherited
--
create or replace function inline_0 ()
returns integer as '
DECLARE
    row                         RECORD;
BEGIN
    FOR row IN
        select  *
        from    im_cost_centers
    LOOP
        RAISE NOTICE ''inline_0: cc_id=%'', row.cost_center_id;

        update acs_objects
        set context_id = row.parent_id
        where object_id = row.cost_center_id;

    END LOOP;
    return 0;

END;' language 'plpgsql';
select inline_0 ();
drop function inline_0();




-------------------------------------------------------------
-- Price List
--
-- Several objects expose a changing price over time,
-- such as employees (salary), rent, aDSL line etc.
-- However, we don't want to modify the price for
-- every month when generating monthly costs,
-- so it may be better to record the changing price
-- over time.
-- This object determines the price for an object
-- based on a start_date - end_date range.
-- End_date is kind of redundant, because it could
-- be deduced from the start_date of the next cost,
-- but that way we would need a max(...) query to
-- determine a current price which might be very slow.
--
create table im_prices (
	object_id		integer
				constraint im_prices_object_fk
				references acs_objects,
	attribute		text
				constraint im_prices_attribute_nn
				not null,
	start_date		timestamptz,
	end_date		timestamptz default '2099-12-31',
	amount			numeric(12,3),
	currency		char(3)
				constraint im_prices_currency_fk
				references currency_codes(iso),
		primary key (object_id, attribute, currency)
);

alter table im_prices
add constraint im_prices_start_end_ck
check(start_date < end_date);


-------------------------------------------------------------
-- Costs
--
-- Costs is the superclass for all financial items such as 
-- Invoices, Quotes, Purchase Orders, Bills (from providers), 
-- Travel Costs, Payroll Costs, Fixed Costs, Amortization Costs,
-- etc. in order to allow for simple SQL queries revealing the
-- financial status of a company.
--
-- Costs are also used for controlling, namely by assigning costs
-- to projects, companies and cost centers in order to allow for 
-- (more or less) accurate profit & loss calculation.
-- This assignment sometimes requires to split a large cost item
-- into several smaller items in order to assign them more 
-- accurately to project, companies or cost centers ("redistribution").
--
-- Costs reference acs_objects for customer and provider in order to
-- allow costs to be created for example between an employee and the
-- company in the case of travel costs.
--

-- prompt *** intranet-costs: Creating im_costs
create or replace function inline_0 ()
returns integer as '
declare
	v_object_type	integer;
begin
	v_object_type := acs_object_type__create_type (
		''im_cost'',		-- object_type
		''Cost'',		-- pretty_name
		''Costs'',		-- pretty_plural
		''acs_object'',		-- supertype
		''im_costs'',		-- table_name
		''cost_id'',		-- id_column
		''im_costs'',		-- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		''im_cost__name''	-- name_method
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Create URLs for viewing/editing costs
delete from im_biz_object_urls where object_type='im_cost';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost','view','/intranet-cost/costs/new?form_mode=display\&cost_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost','edit','/intranet-cost/costs/new?form_mode=edit\&cost_id=');

update acs_object_types set
	status_type_table = 'im_costs',
	status_column = 'cost_status_id',
	type_column = 'cost_type_id'
where object_type = 'im_cost';




-- Creating im_costs
create table im_costs (
	cost_id			integer
				constraint im_costs_pk
				primary key
				constraint im_costs_cost_fk
				references acs_objects,
	-- force a name because we may want to use object.name()
	-- later to list cost
	cost_name		varchar(400)
				constraint im_costs_name_nn
				not null,
	-- Nr is a current number to provide a unique 
	-- identifier of a cost item for backup/restore.
	cost_nr			varchar(400)
				constraint im_costs_nr_nn
				not null,
	project_id		integer
				constraint im_costs_project_fk
				references im_projects,
				-- who pays?
	customer_id		integer
				constraint im_costs_customer_nn
				not null
				constraint im_costs_customer_fk
				references acs_objects,
				-- who gets paid?
	cost_center_id		integer
				constraint im_costs_cost_center_fk
				references im_cost_centers,
	provider_id		integer
				constraint im_costs_provider_nn
				not null
				constraint im_costs_provider_fk
				references acs_objects,
	investment_id		integer
				constraint im_costs_inv_fk
				references acs_objects,
	cost_status_id		integer
				constraint im_costs_status_nn
				not null
				constraint im_costs_status_fk
				references im_categories,
	cost_type_id		integer
				constraint im_costs_type_nn
				not null
				constraint im_costs_type_fk
				references im_categories,
	-- reference to an object that has caused this cost,
	-- in particular to im_repeating_costs
	cause_object_id		integer
				constraint im_costs_cause_fk
				references acs_objects,
	template_id		integer
				constraint im_cost_template_fk
				references im_categories,
	-- when does the invoice start to be valid?
	-- due_date is effective_date + payment_days.
	effective_date		timestamptz,
	-- start_blocks are the first days every month. This allows
	-- for fast monthly grouping
	start_block		timestamptz
				constraint im_costs_startblck_fk
				references im_start_months,
	payment_days		integer,
	-- amount=null means calculated amount, for example
	-- with an invoice
	amount			numeric(12,3),
	currency		char(3) 
				constraint im_costs_currency_fk
				references currency_codes(iso),
	paid_amount		numeric(12,3),
	paid_currency		char(3) 
				constraint im_costs_paid_currency_fk
				references currency_codes(iso),
	-- % of total price is VAT
	vat			numeric(12,5) default 0,
	-- % of total price is TAX
	tax			numeric(12,5) default 0,
	-- Classification of variable against fixed costs
	variable_cost_p		char(1)
				constraint im_costs_var_ck
				check (variable_cost_p in ('t','f')),
	needs_redistribution_p	char(1)
				constraint im_costs_needs_redist_ck
				check (needs_redistribution_p in ('t','f')),
	-- Points to its parent if the parent was distributed
	parent_id		integer
				constraint im_costs_parent_fk
				references im_costs,
	-- Indicates that this cost has been redistributed to
	-- potentially several other costs, so we don't want to
	-- include this item in sums.
	redistributed_p		char(1)
				constraint im_costs_redist_ck
				check (redistributed_p in ('t','f')),
	planning_p		char(1)
				constraint im_costs_planning_ck
				check (planning_p in ('t','f')),
	planning_type_id	integer
				constraint im_costs_planning_type_fk
				references im_categories,
	read_only_p		char(1) default 'f'
				constraint im_costs_read_only_ck
				check (read_only_p in ('t','f')),
	description		text,
	note			text,
	-- Audit fields
	last_modified		timestamptz,
	last_modifying_user	integer
				constraint im_costs_last_mod_user
				references users,
	last_modifying_ip 	varchar(50)
);
create index im_costs_cause_object_idx on im_costs(cause_object_id);
create index im_costs_start_block_idx on im_costs(start_block);



-------------------------------------------------------------
-- Cost Object Packages
--

-- create or replace package body im_cost
-- is
create or replace function im_cost__new (
	integer, varchar, timestamptz, integer,	varchar, integer,
	varchar, integer, integer, integer, integer, integer, integer,
	integer, integer, timestamptz, integer, numeric,
	varchar, numeric, numeric, varchar, varchar, varchar, varchar,
	integer, varchar, varchar
)
returns integer as '
declare
	p_cost_id		alias for $1;		-- cost_id default null
	p_object_type		alias for $2;		-- object_type default ''im_cost''
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user default null
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_cost_name		alias for $7;		-- cost_name default null
	p_parent_id		alias for $8;		-- parent_id default null
	p_project_id		alias for $9;		-- project_id default null
	p_customer_id		alias for $10;		-- customer_id
	p_provider_id		alias for $11;		-- provider_id
	p_investment_id		alias for $12;		-- investment_id default null

	p_cost_status_id	alias for $13;		-- cost_status_id
	p_cost_type_id		alias for $14;		-- cost_type_id
	p_template_id		alias for $15;		-- template_id default null

	p_effective_date	alias for $16;		-- effective_date default now()
	p_payment_days		alias for $17;		-- payment_days default 30
	p_amount		alias for $18;		-- amount default null
	p_currency		alias for $19;		-- currency default ''EUR''
	p_vat			alias for $20;		-- vat default 0
	p_tax			alias for $21;		-- tax default 0

	p_variable_cost_p	alias for $22;		-- variable_cost_p default ''f''
	p_needs_redistribution_p alias for $23;		-- needs_redistribution_p default ''f''
	p_redistributed_p	alias for $24;		-- redistributed_p default ''f''
	p_planning_p		alias for $25;		-- planning_p default ''f''
	p_planning_type_id	alias for $26;		-- planning_type_id default null

	p_note			alias for $27;		-- note default null
	p_description		alias for $28;		-- description default null
	v_cost_cost_id		integer;
 begin
	v_cost_cost_id := acs_object__new (
		p_cost_id,			-- object_id
		p_object_type,			-- object_type
		p_creation_date,		-- creation_date
		p_creation_user,		-- creation_user
		p_creation_ip,			-- creation_ip
		p_context_id,			-- context_id
		''t''				-- security_inherit_p
	);

	insert into im_costs (
		cost_id, cost_name, cost_nr,
		project_id, customer_id, provider_id, 
		cost_status_id, cost_type_id,
		template_id, investment_id,
		effective_date, payment_days,
		amount, currency, vat, tax,
		variable_cost_p, needs_redistribution_p,
		parent_id, redistributed_p, 
		planning_p, planning_type_id, 
		description, note
	) values (
		v_cost_cost_id, p_cost_name, v_cost_cost_id,
		p_project_id, p_customer_id, p_provider_id, 
		p_cost_status_id, p_cost_type_id,
		p_template_id, p_investment_id,
		p_effective_date, p_payment_days,
		p_amount, p_currency, p_vat, p_tax,
		p_variable_cost_p, p_needs_redistribution_p,
		p_parent_id, p_redistributed_p, 
		p_planning_p, p_planning_type_id, 
		p_description, p_note
	);

	return v_cost_cost_id;
end' language 'plpgsql';


-- Delete a single cost (if we know its ID...)
create or replace function im_cost__delete (integer)
returns integer as '
DECLARE
	p_cost_id alias for $1;
begin
	-- Update im_hours relationship
	update	im_hours
	set	cost_id = null
	where	cost_id = p_cost_id;

	-- Erase the im_cost
	delete from im_costs
	where cost_id = p_cost_id;

	-- Erase the acs_rels entries pointing to this cost item
	delete	from acs_rels
	where	object_id_two = p_cost_id;
	delete	from acs_rels
	where	object_id_one = p_cost_id;

	-- Erase the object
	PERFORM acs_object__delete(p_cost_id);
	return 0;
end' language 'plpgsql';


create or replace function im_cost__name (integer)
returns varchar as '
DECLARE
	p_cost_id	alias for $1;	-- cost_id
	v_name		varchar;
begin
	select	cost_name into v_name from im_costs
	where	cost_id = p_cost_id;

	return v_name;
end;' language 'plpgsql';



-- Creating status and type views
create or replace view im_cost_status as
select
	category_id as cost_status_id,
	category as cost_status
from 	im_categories
where	category_type = 'Intranet Cost Status' and
	category_id not in (3812);


create or replace view im_cost_types as
select	category_id as cost_type_id, 
	category as cost_type,
	CASE 
	    WHEN category_id = 3700 THEN 'fi_read_invoices'
	    WHEN category_id = 3702 THEN 'fi_read_quotes'
	    WHEN category_id = 3704 THEN 'fi_read_bills'
	    WHEN category_id = 3706 THEN 'fi_read_pos'
	    WHEN category_id = 3716 THEN 'fi_read_repeatings'
	    WHEN category_id = 3718 THEN 'fi_read_timesheets'
	    WHEN category_id = 3720 THEN 'fi_read_expense_items'
	    WHEN category_id = 3722 THEN 'fi_read_expense_bundles'
	    WHEN category_id = 3724 THEN 'fi_read_delivery_notes'
	    WHEN category_id = 3730 THEN 'fi_read_interco_invoices'
            WHEN category_id = 3732 THEN 'fi_read_interco_quotes'
	    ELSE 'fi_read_all'
	END as read_privilege,
	CASE 
	    WHEN category_id = 3700 THEN 'fi_write_invoices'
	    WHEN category_id = 3702 THEN 'fi_write_quotes'
	    WHEN category_id = 3704 THEN 'fi_write_bills'
	    WHEN category_id = 3706 THEN 'fi_write_pos'
	    WHEN category_id = 3716 THEN 'fi_write_repeatings'
	    WHEN category_id = 3718 THEN 'fi_write_timesheets'
	    WHEN category_id = 3720 THEN 'fi_write_expense_items'
	    WHEN category_id = 3722 THEN 'fi_write_expense_bundles'
	    WHEN category_id = 3724 THEN 'fi_write_delivery_notes'
	    WHEN category_id = 3730 THEN 'fi_write_interco_invoices'
	    WHEN category_id = 3732 THEN 'fi_write_interco_quotes'
	    ELSE 'fi_write_all'
	END as write_privilege,
	CASE 
	    WHEN category_id = 3700 THEN 'invoice'
	    WHEN category_id = 3702 THEN 'quote'
	    WHEN category_id = 3704 THEN 'bill'
	    WHEN category_id = 3706 THEN 'po'
	    WHEN category_id = 3716 THEN 'repcost'
	    WHEN category_id = 3718 THEN 'timesheet'
	    WHEN category_id = 3720 THEN 'expitem'
	    WHEN category_id = 3722 THEN 'expbundle'
	    WHEN category_id = 3724 THEN 'delnote'
	    WHEN category_id = 3730 THEN 'interco_invoices'
	    WHEN category_id = 3732 THEN 'interco_quotes'
	    ELSE 'unknown'
	END as short_name
from 	im_categories
where 	category_type = 'Intranet Cost Type';


-------------------------------------------------------------
-- Invalidate the cost cache of related projects
-- (set dirty-flag to current date)
-------------------------------------------------------------

create or replace function im_cost_project_cache_invalidator (integer)
returns integer as '
declare
	p_project_id	alias for $1;

	v_project_id	integer;
	v_count		integer;
	v_parent_id	integer;
	v_last_dirty	timestamptz;
begin
	v_project_id := p_project_id;
	v_count := 20;
	
	WHILE v_project_id is not null AND v_count > 0 LOOP

		-- Get the projects parent and existing dirty flag to continue...
		select parent_id, cost_cache_dirty into v_parent_id, v_last_dirty from im_projects
		where project_id = v_project_id;

		-- Skip if the update if the project cache is already dirty
		-- Also, we keep a record which was the oldest dirty cache,
		-- so that the cleanup orden stays chronologic with the oldest
		-- dirty cache first.
		IF v_last_dirty is not null THEN return v_count; END IF;

		-- Set the "dirty"-flag. There is a sweeper to cleanup afterwards.
		RAISE NOTICE ''im_cost_project_cache_invalidator: invalidating cost cache of project %'', p_project_id;
		update im_projects
		set cost_cache_dirty = now()
		where project_id = v_project_id;

		-- Continue with the parent_id
		v_project_id := v_parent_id;

		-- Decrease the loop-protection counter
		v_count := v_count-1;
	END LOOP;

	return v_count;
end;' language 'plpgsql';



-------------------------------------------------------------
-- Trigger for im_cost to invalidate project cost cache on changes
-------------------------------------------------------------


create or replace function im_cost_project_cache_up_tr ()
returns trigger as '
begin
	RAISE NOTICE ''im_cost_project_cache_up_tr: %'', new.cost_id;
	PERFORM im_cost_project_cache_invalidator (old.project_id);
	PERFORM im_cost_project_cache_invalidator (new.project_id);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_costs_project_cache_up_tr
AFTER UPDATE
ON im_costs
FOR EACH ROW
EXECUTE PROCEDURE im_cost_project_cache_up_tr();



-------------------------------------------------------------
-- Costs Insert Trigger

create or replace function im_cost_project_cache_ins_tr ()
returns trigger as '
begin
	RAISE NOTICE ''im_cost_project_cache_ins_tr: %'', new.cost_id;
	PERFORM im_cost_project_cache_invalidator (new.project_id);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_costs_project_cache_ins_tr
AFTER INSERT
ON im_costs
FOR EACH ROW
EXECUTE PROCEDURE im_cost_project_cache_ins_tr();


-------------------------------------------------------------
-- Costs Delete Trigger

create or replace function im_cost_project_cache_del_tr ()
returns trigger as '
begin
	RAISE NOTICE ''im_cost_project_cache_del_tr: %'', old.cost_id;
	PERFORM im_cost_project_cache_invalidator (old.project_id);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_costs_project_cache_del_tr
AFTER DELETE
ON im_costs
FOR EACH ROW
EXECUTE PROCEDURE im_cost_project_cache_del_tr();





-------------------------------------------------------------
-- Trigger for im_projects to invalidate project cost cache on changes:
-- Changing the parent_id of a project or setting the parent_id
-- of a project invalidates the cost caches of its superprojects.


-------------------------------------------------------------
-- Project Update Trigger

create or replace function im_project_project_cache_up_tr ()
returns trigger as '
begin
	RAISE NOTICE ''im_project_project_cache_up_tr: %'', new.project_id;

	IF new.parent_id != old.parent_id THEN
		PERFORM im_cost_project_cache_invalidator (old.parent_id);
		PERFORM im_cost_project_cache_invalidator (new.parent_id);
	END IF;

	IF new.parent_id is null AND old.parent_id is not null THEN
		PERFORM im_cost_project_cache_invalidator (old.parent_id);
	END IF;

	IF new.parent_id is not null AND old.parent_id is null THEN
		PERFORM im_cost_project_cache_invalidator (new.parent_id);
	END IF;
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_projects_project_cache_up_tr
AFTER UPDATE
ON im_projects
FOR EACH ROW
EXECUTE PROCEDURE im_project_project_cache_up_tr();




-------------------------------------------------------------
-- Wrapper Functions for DB-independed execution
--

create or replace function im_cost_del (integer) 
returns integer as '
declare
	p_cost_id alias for $1;
begin
	PERFORM im_cost__delete(p_cost_id);
	return 0;
end;' language 'plpgsql';


-------------------------------------------------------------
-- Repeating Costs
--
-- These items generate a new cost every month that they
-- are active.
-- This item is used for diverse types of repeating costs
-- such as employees salaries, rent and utilities costs and
-- investment amortization, so it is kind of "aggregated"
-- to those objects.
--
-- Repeating Costs are a subtype of im_costs. However, we 
-- have to add the constraint later because im_costs 
-- depend on im_investment and im_investment depends on 
-- repeating_costs.
--
-- im_costs.cause_object_id contains the reference to the
-- business object that causes the repetitive cost.

create or replace function inline_0 ()
returns integer as '
declare
	v_object_type	integer;
begin
	v_object_type := acs_object_type__create_type (
		''im_repeating_cost'',		-- object_type
		''Repeating Cost'',		-- pretty_name
		''Repeating Cost'',		-- pretty_plural
		''im_cost'',			-- supertype
		''im_repeating_costs'',		-- table_name
		''rep_cost_id'',		-- id_column
		''im_repeating_cost'',		-- package_name
		''f'',				-- abstract_p
		null,				-- type_extension_table
		''im_repeating_cost__name''	-- name_method
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


update acs_object_types set
	status_type_table = 'im_costs',
	status_column = 'cost_status_id',
	type_column = 'cost_type_id'
where object_type = 'im_repeating_cost';



-- prompt *** intranet-costs: Creating im_repeating_costs
create table im_repeating_costs (
	rep_cost_id		integer
				constraint im_rep_costs_id_pk
				primary key
				constraint im_rep_costs_id_fk
				references im_costs,
	start_date		timestamptz 
				constraint im_rep_costs_start_date_nn
				not null,
	end_date		timestamptz default '2099-12-31'
				constraint im_rep_costs_end_date_nn
				not null,
		constraint im_rep_costs_start_end_date
		check(start_date <= end_date)
);


-- Delete a single cost (if we know its ID...)
create or replace function im_repeating_cost__delete (integer)
returns integer as '
DECLARE
	p_cost_id alias for $1;
begin
	-- Erase the im_repeating_costs entry
	delete from im_repeating_costs
	where rep_cost_id = p_cost_id;

	-- Erase the object
	PERFORM im_cost__delete(p_cost_id);
	return 0;
end' language 'plpgsql';


create or replace function im_repeating_cost__name (integer)
returns varchar as '
DECLARE
	p_cost_id	alias for $1;	-- cost_id
	v_name		varchar;
begin
	select	cost_name into v_name from im_costs
	where	cost_id = p_cost_id;

	return v_name;
end;' language 'plpgsql';




-------------------------------------------------------------
-- "Investments"
--
-- Investments are purchases of larger "investment items"
-- that are not treated as a cost item immediately.
-- Instead, investments are "amortized" over time
-- (monthly, quarterly or yearly) until their non-amortized
-- valeu is zero. A new cost item cost items is generated for 
-- every amortization interval.
--
-- The amortized amount of costs is calculated by summing up
-- all im_costs with the specific investment_id
--

-- prompt *** intranet-costs: Creating im_investments
create table im_investments (
	investment_id		integer
				constraint im_investments_pk
				primary key
				constraint im_investments_fk
				references im_repeating_costs,
	name			text,
	investment_status_id	integer
				constraint im_investments_status_fk
				references im_categories,
	investment_type_id	integer
				constraint im_investments_type_fk
				references im_categories
);


-- prompt *** intranet-costs: Creating im_cost packages
create or replace function inline_0 ()
returns integer as '
declare
	v_object_type	integer;
begin
	v_object_type := acs_object_type__create_type (
		''im_investment'',	-- object_type
		''Investment'',		-- pretty_name
		''Investments'',	-- pretty_plural
		''im_repeating_cost'',	-- supertype	
		''im_investments'',	-- table_name
		''investment_id'',	-- id_column
		''im_investment'',	-- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		''im_investment__name'' -- name_method
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- Creating URLs for viewing/editing investments
delete from im_biz_object_urls where object_type='im_investment';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_investment','view','/intranet-cost/investments/new?form_mode=display\&investment_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_investment','edit','/intranet-cost/investments/new?form_mode=edit\&investment_id=');

update acs_object_types set
	status_type_table = 'im_costs',
	status_column = 'cost_status_id',
	type_column = 'cost_type_id'
where object_type = 'im_investment';



-------------------------------------------------------------
-- Permissions and Privileges
--
select acs_privilege__create_privilege('view_costs','View Costs','View Costs');
select acs_privilege__add_child('admin', 'view_costs');

select acs_privilege__create_privilege('add_costs','Add Costs','Add Costs');
select acs_privilege__add_child('admin', 'add_costs');

select im_priv_create('view_costs','Accounting');
select im_priv_create('view_costs','P/O Admins');
select im_priv_create('view_costs','Senior Managers');

select im_priv_create('add_costs','Accounting');
select im_priv_create('add_costs','P/O Admins');
select im_priv_create('add_costs','Senior Managers');


-------------------------------------------------------------
-- Finance Menu System
--

select im_menu__del_module('intranet-trans-invoices');
select im_menu__del_module('intranet-payments');
select im_menu__del_module('intranet-invoices');
select im_menu__del_module('intranet-cost');


-- prompt *** intranet-costs: Create Finance Menu
-- Setup the "Finance" main menu entry
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;
	v_finance_menu		integer;

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
	into v_main_menu
	from im_menus
	where label=''main'';

	v_finance_menu := im_menu__new (
		null,				-- menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cost'',		-- package_name
		''finance'',			-- label
		''Finance'',			-- name
		''/intranet-cost/'',		-- url
		80,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_finance_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_finance_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_finance_menu, v_accounting, ''read'');

--	PERFORM acs_permission__grant_permission(v_finance_menu, v_customers, ''read'');
--	PERFORM acs_permission__grant_permission(v_finance_menu, v_freelancers, ''read'');

	-- -----------------------------------------------------
	-- General Costs
	-- -----------------------------------------------------

	v_menu := im_menu__new (
		null,				-- menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cost'',		-- package_name
		''costs_home'',			-- label
		''Finance Home'',		-- name
		''/intranet-cost/index'',	-- url
		10,				-- sort_order
		v_finance_menu,			-- parent_menu_id
		null				-- visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	v_menu := im_menu__new (
		null,				-- menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cost'',		-- package_name
		''costs'',			-- label
		''All Costs'',			-- name
		''/intranet-cost/list'',	-- url
		80,				-- sort_order
		v_finance_menu,			-- parent_menu_id
		null				-- visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


-- Cost Center Menu as part of the Finance menu
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_finance_menu		integer;

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
	into v_finance_menu
	from im_menus
	where label=''finance'';

	v_finance_menu := im_menu__new (
		null,				-- menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cost'',		-- package_name
		''finance_cost_centers'',	-- label
		''Cost Centers'',		-- name
		''/intranet-cost/cost-centers/index'',		-- url
		90,				-- sort_order
		v_finance_menu,			-- parent_menu_id
		null				-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_finance_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_finance_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_finance_menu, v_accounting, ''read'');
--	PERFORM acs_permission__grant_permission(v_finance_menu, v_customers, ''read'');
--	PERFORM acs_permission__grant_permission(v_finance_menu, v_freelancers, ''read'');

	return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


-- Setup the "New Cost" menu for /intranet-cost/index
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_invoices_new_menu	integer;
	v_finance_menu		integer;

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
	into v_invoices_new_menu
	from im_menus
	where label=''costs'';

	v_finance_menu := im_menu__new (
		null,				-- menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cost'',		-- package_name
		''cost_new'',			-- label
		''New Cost'',			-- name
		''/intranet-cost/costs/new'',	-- url
		10,				-- sort_order
		v_invoices_new_menu,		-- parent_menu_id
		null				-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_finance_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_finance_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_finance_menu, v_accounting, ''read'');
	return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

-- Repeating Costs Menu
create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu			integer;
	v_finance_menu		integer;

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

	select menu_id into v_finance_menu from im_menus
	where label=''finance'';

	v_menu := im_menu__new (
		null,				-- menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cost'',		-- package_name
		''costs_rep'',			-- label
		''Repeating Costs'',		-- name
		''/intranet-cost/rep-costs/'',	-- url
		90,				-- sort_order
		v_finance_menu,			-- parent_menu_id
		null				-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
	return 0;
end;' language 'plpgsql';

-- 050324 fraber: Repeating costs disabled for V3.0.0
-- select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu			integer;
	v_project_menu		integer;

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

	select menu_id into v_project_menu from im_menus
	where label=''project'';

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''project_finance'',	-- label
		''Finance'',		-- name
		''/intranet/projects/view?view_name=finance'',	-- url
		20,			-- sort_order
		v_project_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();



-------------------------------------------------------------
-- Cost Components
--

select im_component_plugin__del_module('intranet-cost');

-- Show the finance component in a projects "Finance" page
--
select	im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id

	'Project Finance Component',	-- plugin_name
	'intranet-cost',		-- package_name
	'finance',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	50,				-- sort_order
	'im_costs_project_finance_component $user_id $project_id'	-- component_tcl
);


-- Show the finance component (summary view) in a projects "Summary" page
--
select	im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id

	'Project Finance Summary Component',	-- plugin_name
	'intranet-cost',		-- package_name
	'left',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	80,				-- sort_order
	'im_costs_project_finance_component -show_details_p 0 $user_id $project_id'	-- component_tcl
);



-- Show the cost component in companies page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id

	'Company Cost Component',	-- plugin_name
	'intranet-cost',		-- package_name
	'left',				-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order

	'im_costs_company_component $user_id $company_id'	-- component_tcl
);



-- ------------------------------------------------
-- Return the final customer name for a cost item
--

create or replace function im_cost_get_final_customer_name(integer)
returns varchar as '
DECLARE
        v_cost_id       alias for $1;
        v_company_name  varchar;
BEGIN
	select	company_name into v_company_name
	from 	im_companies
	where 	company_id in ( 
	        select  company_id
	        from    im_projects
	        where   project_id in (
        	        select  project_id
                	from    im_costs c
	                where   c.cost_id = v_cost_id
        	        )
		);
        return v_company_name;
END;' language 'plpgsql';


-------------------------------------------------------------
-- Helper functions to make our queries easier to read
-- and to avoid outer joins with parent projects etc.

-- Return the Cost Center code
create or replace function im_dept_from_user_id(integer)
returns varchar as '
DECLARE
	v_user_id	alias for $1;
	v_dept		varchar;
BEGIN
	select	cost_center_code into v_dept
	from	im_employees e,
		im_cost_centers cc
	where	e.employee_id = v_user_id
		and e.department_id = cc.cost_center_id;

	return v_dept;
END;' language 'plpgsql';



-- Some helper functions to make our queries easier to read
create or replace function im_cost_center_label_from_id (integer)
returns varchar as '
DECLARE
	p_id	alias for $1;
	v_name	varchar;
BEGIN
	select	cc.cost_center_label into v_name from im_cost_centers cc
	where	cost_center_id = p_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_cost_center_name_from_id (integer)
returns varchar as '
DECLARE
	p_id	alias for $1;
	v_name	varchar;
BEGIN
	select	cc.cost_center_name into v_name from im_cost_centers cc
	where	cost_center_id = p_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_cost_center_code_from_id (integer)
returns varchar as '
DECLARE
	p_id	alias for $1;
	v_name	varchar;
BEGIN
	select	cc.cost_center_code into v_name from im_cost_centers cc
	where	cost_center_id = p_id;

	return v_name;
end;' language 'plpgsql';



create or replace function im_cost_nr_from_id (integer)
returns varchar as '
DECLARE
	p_id	alias for $1;
	v_name	varchar;
BEGIN
	select cost_nr into v_name from im_costs
	where cost_id = p_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_investment_name_from_id (integer)
returns varchar as '
DECLARE
	p_id	alias for $1;
	v_name	varchar;
BEGIN
	select i.name
	into v_name
	from im_investments
	where investment_id = p_id;

	return v_name;
end;' language 'plpgsql';



-------------------------------------------------------------
-- Import common functionality

\i ../common/intranet-cost-backup.sql



-------------------------------------------------------------
-- Cost Center Permissions for Financial Documents
-------------------------------------------------------------

-- Permissions and Privileges
--

-- All privilege - We cannot directly inherit from "read" or "write",
-- because all registered_users have read access to the "SubSite".
--
select acs_privilege__create_privilege('fi_read_all','Read All','Read All');
select acs_privilege__create_privilege('fi_write_all','Write All','Write All');
select acs_privilege__add_child('admin', 'fi_read_all');
select acs_privilege__add_child('admin', 'fi_write_all');

-- Start defining the cost_type specific privileges
--
select acs_privilege__create_privilege('fi_read_invoices','Read Invoices','Read Invoices');
select acs_privilege__create_privilege('fi_write_invoices','Write Invoices','Write Invoices');
select acs_privilege__add_child('fi_read_all', 'fi_read_invoices');
select acs_privilege__add_child('fi_write_all', 'fi_write_invoices');

select acs_privilege__create_privilege('fi_read_quotes','Read Quotes','Read Quotes');
select acs_privilege__create_privilege('fi_write_quotes','Write Quotes','Write Quotes');
select acs_privilege__add_child('fi_read_all', 'fi_read_quotes');
select acs_privilege__add_child('fi_write_all', 'fi_write_quotes');

select acs_privilege__create_privilege('fi_read_bills','Read Bills','Read Bills');
select acs_privilege__create_privilege('fi_write_bills','Write Bills','Write Bills');
select acs_privilege__add_child('fi_read_all', 'fi_read_bills');
select acs_privilege__add_child('fi_write_all', 'fi_write_bills');

select acs_privilege__create_privilege('fi_read_pos','Read Pos','Read Pos');
select acs_privilege__create_privilege('fi_write_pos','Write Pos','Write Pos');
select acs_privilege__add_child('fi_read_all', 'fi_read_pos');
select acs_privilege__add_child('fi_write_all', 'fi_write_pos');

select acs_privilege__create_privilege('fi_read_timesheets','Read Timesheets','Read Timesheets');
select acs_privilege__create_privilege('fi_write_timesheets','Write Timesheets','Write Timesheets');
select acs_privilege__add_child('fi_read_all', 'fi_read_timesheets');
select acs_privilege__add_child('fi_write_all', 'fi_write_timesheets');

select acs_privilege__create_privilege('fi_read_delivery_notes','Read Delivery Notes','Read Delivery Notes');
select acs_privilege__create_privilege('fi_write_delivery_notes','Write Delivery Notes','Write Delivery Notes');
select acs_privilege__add_child('fi_read_all', 'fi_read_delivery_notes');
select acs_privilege__add_child('fi_write_all', 'fi_write_delivery_notes');

select acs_privilege__create_privilege('fi_read_expense_items','Read Expense Items','Read Expense Items');
select acs_privilege__create_privilege('fi_write_expense_items','Write Expense Items','Write Expense Items');
select acs_privilege__add_child('fi_read_all', 'fi_read_expense_items');
select acs_privilege__add_child('fi_write_all', 'fi_write_expense_items');

select acs_privilege__create_privilege('fi_read_expense_bundles','Read Expense Bundles','Read Expense Bundles');
select acs_privilege__create_privilege('fi_write_expense_bundles','Write Expense Bundles','Write Expense Bundles');
select acs_privilege__add_child('fi_read_all', 'fi_read_expense_bundles');
select acs_privilege__add_child('fi_write_all', 'fi_write_expense_bundles');

select acs_privilege__create_privilege('fi_read_repeatings','Read Repeatings','Read Repeatings');
select acs_privilege__create_privilege('fi_write_repeatings','Write Repeatings','Write Repeatings');
select acs_privilege__add_child('fi_read_all', 'fi_read_repeatings');
select acs_privilege__add_child('fi_write_all', 'fi_write_repeatings');



select acs_privilege__create_privilege('fi_read_interco_invoices','Read Interco Invoices','Read Interco Invoices');
select acs_privilege__create_privilege('fi_write_interco_invoices','Write Interco Invoices','Write Interco Invoices');
select acs_privilege__add_child('fi_read_all', 'fi_read_interco_invoices');
select acs_privilege__add_child('fi_write_all', 'fi_write_interco_invoices');

select acs_privilege__create_privilege('fi_read_interco_quotes','Read Interco Quotes','Read Interco Quotes');
select acs_privilege__create_privilege('fi_write_interco_quotes','Write Interco Quotes','Write Interco Quotes');
select acs_privilege__add_child('fi_read_all', 'fi_read_interco_quotes');
select acs_privilege__add_child('fi_write_all', 'fi_write_interco_quotes');





select im_priv_create('fi_read_all','P/O Admins');
select im_priv_create('fi_read_all','Senior Managers');
select im_priv_create('fi_read_all','Accounting');
select im_priv_create('fi_write_all','P/O Admins');
select im_priv_create('fi_write_all','Senior Managers');
select im_priv_create('fi_write_all','Accounting');



-------------------------------------------------------------
-- Update the context_id fields of the cost centers, 
-- so that permissions are inherited
--
create or replace function inline_0 ()
returns integer as '
DECLARE
	row			RECORD;
BEGIN
	FOR row IN
	select	*
		from	im_cost_centers
	LOOP
		RAISE NOTICE ''inline_0: cc_id=%'', row.cost_center_id;
	
		update acs_objects
		set context_id = row.parent_id
		where object_id = row.cost_center_id;
	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();



-------------------------------------------------------------
-- Update the context_id field of the "Co - The Company"
-- so that permissions are inherited from SubSite
--
create or replace function inline_0 ()
returns integer as '
DECLARE
	v_subsite_id		integer;
BEGIN
	-- Get the Main Site id, used as the global identified for permissions
	select package_id into v_subsite_id from apm_packages
	where package_key=''acs-subsite'';

	update acs_objects
		set context_id = v_subsite_id
	where	object_id in (
			select cost_center_id
			from im_cost_centers
			where parent_id is null
		);

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

