-- /packages/intranet-cost/sql/oracle/intranet-cost-create.sql
--
-- Project/Open Cost Core
-- 040207 fraber@fraber.de
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>


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

set escape \

-------------------------------------------------------------
-- Setup the status and type im_categories

-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3299    Intranet CRM Tracking
-- 3300-3399    reserved for cost centers
-- 3400-3499    Intranet Investment Type
-- 3500-3599    Intranet Investment Status
-- 3600-3699	Intranet Investment Amortization Interval (reserved)
-- 3700-3799    Intranet Cost Type
-- 3800-3899    Intranet Cost Status
-- 3900-3999    Intranet Cost Planning Type
-- 4000-4599    (reserved)



prompt *** intranet-costs: Creating acs_object_type
begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
	object_type =>		'im_cost_center',
	pretty_name =>		'Cost Center',
	pretty_plural =>	'Cost Centers',
	table_name =>		'im_centers',
	id_column =>		'cost_center_id',
	package_name =>		'im_cost_center',
	type_extension_table =>	null,
	name_method =>		'im_cost_center.name'
    );
end;
/
show errors


prompt *** intranet-costs: Creating im_cost_centers
create table im_cost_centers (
	cost_center_id		integer
				constraint im_cost_centers_pk
				primary key
				constraint im_cost_centers_id_fk
				references acs_objects,
	cost_center_name	varchar(100) 
				constraint im_cost_centers_name_nn
				not null,
	cost_center_label	varchar(100)
				constraint im_cost_centers_label_nn
				not null
				constraint im_cost_centers_label_un
				unique,
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
	description		varchar(4000),
	note			varchar(4000),
		-- don't allow two cost centers under the same parent
		constraint im_cost_centers_un
		unique(cost_center_name, parent_id)
);
create index im_cost_centers_parent_id_idx on im_cost_centers(parent_id);
create index im_cost_centers_manager_id_idx on im_cost_centers(manager_id);



prompt *** intranet-costs: Creating im_cost_center
create or replace package im_cost_center
is
    function new (
	cost_center_id	in integer default null,
	object_type	in varchar default 'im_cost_center',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	cost_center_name in varchar,
	cost_center_label in varchar,
	type_id		in integer,
	status_id	in integer,
	parent_id	in integer,
	manager_id	in integer default null,
	department_p	in char default 't',
	description	in varchar default null,
	note		in varchar default null
    ) return im_cost_centers.cost_center_id%TYPE;

    procedure del (cost_center_id in integer);
    procedure name (cost_center_id in integer);
end im_cost_center;
/
show errors


prompt *** intranet-costs: Creating im_cost_center body
create or replace package body im_cost_center
is
    function new (
	cost_center_id	in integer default null,
	object_type	in varchar default 'im_cost_center',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	cost_center_name in varchar,
	cost_center_label in varchar,
	type_id		in integer,
	status_id	in integer,
	parent_id	in integer,
	manager_id	in integer default null,
	department_p	in char default 't',
	description	in varchar default null,
	note		in varchar default null
    ) return im_cost_centers.cost_center_id%TYPE
    is
	v_cost_center_id	im_cost_centers.cost_center_id%TYPE;
    begin
	v_cost_center_id := acs_object.new (
		object_id =>		cost_center_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	insert into im_cost_centers (
		cost_center_id, 
		cost_center_name, cost_center_label,
		cost_center_type_id, cost_center_status_id, 
		parent_id, manager_id,
		department_p,
		description, note
	) values (
		new.v_cost_center_id, 
		new.cost_center_name, new.cost_center_label,
		new.type_id, new.status_id, 
		new.parent_id, new.manager_id, 
		new.department_p,
		new.description, new.note
	);
	return v_cost_center_id;
    end new;


    -- Delete a single cost_center (if we know its ID...)
    procedure del (cost_center_id in integer)
    is
	v_cost_center_id	integer;
    begin
	-- copy the variable to desambiguate the var name
	v_cost_center_id := cost_center_id;

	-- Erase the im_cost_centers item associated with the id
	delete from 	im_cost_centers
	where		cost_center_id = v_cost_center_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_cost_center_id;

	-- Finally delete the object iself
	acs_object.del(v_cost_center_id);
    end del;


    procedure name (cost_center_id in integer)
    is
	v_name	im_cost_centers.cost_center_name%TYPE;
    begin
	select	cost_center_name
	into	v_name
	from	im_cost_centers
	where	cost_center_id = cost_center_id;
    end name;
end im_cost_center;
/
show errors


prompt *** intranet-costs: Creating URLs for viewing/editing cost centers
delete from im_biz_object_urls where object_type='im_cost_center';
insert into im_biz_object_urls (
	object_type, 
	url_type, 
	url
) values (
	'im_cost_center',
	'view',
	'/intranet-cost/cost-centers/new?form_mode=display\&cost_center_id='
);
insert into im_biz_object_urls (
	object_type, 
	url_type, 
	url
) values (
	'im_cost_center',
	'edit',
	'/intranet-cost/cost-centers/new?form_mode=edit\&cost_center_id='
);


prompt *** intranet-costs: Creating Cost Center categories
-- Intranet Cost Center Type
delete from im_categories where category_id >= 3000 and category_id < 3100;
INSERT INTO im_categories VALUES (3001,'Cost Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO im_categories VALUES (3002,'Profit Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO im_categories VALUES (3003,'Investment Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO im_categories VALUES (3004,'Subdepartment','Department without budget responsabilities',
'Intranet Cost Center Type',1,'f','');
commit;
-- reserved until 3099


-- Intranet Cost Center Type
delete from im_categories where category_id >= 3100 and category_id < 3200;
INSERT INTO im_categories VALUES (3101,'Active','','Intranet Cost Center Status',1,'f','');
INSERT INTO im_categories VALUES (3102,'Inactive','','Intranet Cost Center Status',1,'f','');
commit;
-- reserved until 3099


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


prompt *** intranet-costs: Creating sample cost center configuration
delete from im_cost_centers;
declare
    v_the_company_center	integer;
    v_administrative_center	integer;
    v_utilities_center		integer;
    v_marketing_center		integer;
    v_sales_center		integer;
    v_it_center			integer;
    v_projects_center		integer;
begin

    -- -----------------------------------------------------
    -- Main Center
    -- -----------------------------------------------------

    -- The Company itself: Profit Center (3002) with status "Active" (3101)
    -- This should be the only center with parent=null...
    v_the_company_center := im_cost_center.new (
	cost_center_name =>	'The Company',
	cost_center_label =>	'company',
	type_id =>		3002,
	status_id =>		3101,
	parent_id => 		null,
	manager_id =>		null,
	department_p =>		'f',
	description =>		'The top level center of the company',
	note =>			''
    );

    -- -----------------------------------------------------
    -- Sub Centers
    -- -----------------------------------------------------

    -- The Administrative Dept.: A typical cost center (3001)
    -- We asume a small company, so there is only one manager 
    -- taking budget control of Finance, Accounting, Legal and 
    -- HR stuff.'
    --
    v_administrative_center := im_cost_center.new (
	cost_center_name =>		'Administration',
	cost_center_label =>	'admin',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	department_p =>		't',
	description =>	'Administration Cervice Center',
	note =>		''
    );

    -- Utilities Cost Center (3001)
    --
    v_utilities_center := im_cost_center.new (
	cost_center_name =>	'Rent and Utilities',
	cost_center_label =>	'utilities',
	type_id =>		3001,
	status_id =>		3101,
	parent_id => 		v_the_company_center,
	manager_id =>		null,
	department_p =>		'f',
	description =>		'Covers all repetitive costs such as rent, telephone, internet connectivity, ...',
	note =>			''
    );

    -- Sales Cost Center (3001)
    --
    v_sales_center := im_cost_center.new (
	cost_center_name =>	'Sales',
	cost_center_label =>	'sales',
	type_id =>		3001,
	status_id =>		3101,
	parent_id => 		v_the_company_center,
	manager_id =>		null,
	department_p =>		't',
	description =>		'Records all sales related activities, as oposed to marketing.',
	note =>			''
    );

    -- Marketing Cost Center (3001)
    --
    v_marketing_center := im_cost_center.new (
	cost_center_name =>	'Marketing',
	cost_center_label =>	'marketing',
	type_id =>		3001,
	status_id =>		3101,
	parent_id => 		v_the_company_center,
	manager_id =>		null,
	department_p =>		't',
	description =>		'Marketing activities, such as website, promo material, ...',
	note =>			''
    );

    -- Project Operations Cost Center (3001)
    --
    v_projects_center := im_cost_center.new (
	cost_center_name =>	'Project Operations',
	cost_center_label =>	'operations',
	type_id =>		3001,
	status_id =>		3101,
	parent_id => 		v_the_company_center,
	manager_id =>		null,
	department_p =>		't',
	description =>		'Covers all phases of project-oriented execution activities..',
	note =>			''
    );

end;
/
show errors






-------------------------------------------------------------
-- Repeating Costs
--
-- These items generate a new cost every month that they
-- are active.
-- This item is used for diverse types of repeating costs
-- such as employees salaries, rent and utilities costs and
-- investment amortization, so it is kind of "aggregated"
-- to those objects.

prompt *** intranet-costs: Creating im_repeating_costs
create table im_repeating_costs (
	cost_id			integer
				constraint im_rep_costs_id_pk
				primary key
				constraint im_rep_costs_id_fk
				references acs_objects,
	cost_name		varchar(400),
				-- who pays?
	customer_id		integer
				constraint im_rep_costs_customer_fk
				references acs_objects,
				-- who gets paid?
	provider_id		integer
				constraint im_rep_costs_provider_fk
				references acs_objects,
	cost_center_id		integer not null
				constraint im_rep_costs_centers_fk
				references im_cost_centers,
	start_date		date 
				constraint im_rep_costs_start_date_nn
				not null,
	end_date		date default '2099-12-31'
				constraint im_rep_costs_end_date_nn
				not null,
	amount			number(12,3),
	currency		char(3)
				constraint im_rep_costs_currency_fk
				references currency_codes,
	description		varchar(4000),
	note			varchar(4000),
		constraint im_rep_costs_start_end_date
		check(start_date < end_date)
);



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
---
prompt *** intranet-costs: Creating im_prices
create table im_prices (
	object_id		integer
				constraint im_prices_object_fk
				references acs_objects,
	attribute		varchar(100)
				constraint im_prices_attribute_nn
				not null,
	start_date		date,
	end_date		date default '2099-12-31',
	amount			number(12,3),
	currency		char(3)
				constraint im_prices_currency_fk
				references currency_codes(iso),
		primary key (object_id, attribute, currency)
);

alter table im_prices
add constraint im_prices_start_end_ck
check(start_date < end_date);



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

prompt *** intranet-costs: Creating im_investments
create table im_investments (
	investment_id		integer
				constraint im_investments_pk
				primary key
				constraint im_investments_fk
				references im_repeating_costs,
	name			varchar(400),
	investment_status_id	integer
				constraint im_investments_status_fk
				references im_categories,
	investment_type_id	integer
				constraint im_investments_type_fk
				references im_categories
);



prompt *** intranet-costs: Creating im_cost packages
begin
    acs_object_type.create_type (
        supertype =>            'acs_object',
        object_type =>          'im_investment',
        pretty_name =>          'Investment',
        pretty_plural =>        'Investments',
        table_name =>           'im_investments',
        id_column =>            'investment_id',
        package_name =>         'im_investment',
        type_extension_table => null,
        name_method =>          'im_investment.name'
    );
end;
/
show errors


prompt *** intranet-costs: Creating URLs for viewing/editing investments
delete from im_biz_object_urls where object_type='im_investment';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_investment','view','/intranet-cost/investments/new?form_mode=display\&investment_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_investment','edit','/intranet-cost/investments/new?form_mode=edit\&investment_id=');


prompt *** intranet-costs: Creating Investment categories
-- Intranet Investment Type
delete from im_categories where category_id >= 3400 and category_id < 3500;
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3401,'Other','Intranet Investment Type');
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3403,'Computer Hardware','Intranet Investment Type');
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3405,'Computer Software','Intranet Investment Type');
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3407,'Office Furniture','Intranet Investment Type');
commit;
-- reserved until 3499

-- Intranet Investment Status
delete from im_categories where category_id >= 3500 and category_id < 3599;
INSERT INTO im_categories (category_id, category, category_type, category_description) 
VALUES (3501,'Active','Intranet Investment Status','Currently being amortized');
INSERT INTO im_categories (category_id, category, category_type, category_description) 
VALUES (3503,'Deleted','Intranet Investment Status','Deleted - was an error');
INSERT INTO im_categories (category_id, category, category_type, category_description) 
VALUES (3505,'Amortized','Intranet Investment Status','No remaining book value');
commit;
-- reserved until 3599




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
-- to projects, customers and cost centers in order to allow for 
-- (more or less) accurate profit & loss calculation.
-- This assignment sometimes requires to split a large cost item
-- into several smaller items in order to assign them more 
-- accurately to project, customers or cost centers ("redistribution").
--
-- Costs reference acs_objects for customer and provider in order to
-- allow costs to be created for example between an employee and the
-- company in the case of travel costs.
--
prompt *** intranet-costs: Creating im_costs
create table im_costs (
	cost_id			integer
				constraint im_costs_pk
				primary key,
	-- force a name because we may want to use object.name()
	-- later to list cost
	cost_name		varchar(400)
				constraint im_costs_name_nn
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
				references im_investments,
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
	effective_date		date,
	-- start_blocks are the first days every month. This allows
	-- for fast monthly grouping
	start_block		date
				constraint im_costs_startblck_fk
				references im_start_months,
	payment_days		integer,
	-- amount=null means calculated amount, for example
	-- with an invoice
	amount			number(12,3),
	currency		char(3) 
				constraint im_costs_currency_fk
				references currency_codes(iso),
	-- % of total price is VAT
	vat			number(12,5),
	-- % of total price is TAX
	tax			number(12,5),
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
	description		varchar(4000),
	note			varchar(4000)
);

-- Cost Templates
delete from im_categories where category_id >= 900 and category_id < 1000;
INSERT INTO im_categories VALUES (900,'invoice-english.adp','','Intranet Cost Template','category','t','f');
INSERT INTO im_categories VALUES (902,'invoice-spanish.adp','','Intranet Cost Template','category','t','f');
-- reserved until 999



prompt *** intranet-costs: Creating category Cost Type
-- Cost Type
delete from im_categories where category_id >= 3700 and category_id < 3799;
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3700,'Customer Invoice','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3702,'Quote','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3704,'Provider Bill','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3706,'Purchase Order','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3708,'Customer Documents','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3710,'Provider Documents','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3712,'Travel Cost','Intranet Cost Type');
commit;
-- reserved until 3799

-- Establish the super-categories "Provider Documents" and "Customer Documents"
insert into im_category_hierarchy values (3710,3704);
insert into im_category_hierarchy values (3710,3706);
insert into im_category_hierarchy values (3708,3700);
insert into im_category_hierarchy values (3708,3702);


prompt *** intranet-costs: Creating category Cost Status
-- Intranet Cost Status
delete from im_categories where category_id >= 3800 and category_id < 3899;
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3802,'Created','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3804,'Outstanding','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3806,'Past Due','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3808,'Partially Paid','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3810,'Paid','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3812,'Deleted','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3814,'Filed','Intranet Cost Status');
commit;
-- reserved until 3899


prompt *** intranet-costs: Creating status and type views
create or replace view im_cost_status as
select
	category_id as cost_status_id,
	category as cost_status
from 	im_categories
where	category_type = 'Intranet Cost Status' and
	category_id not in (3812);

create or replace view im_cost_type as
select	category_id as cost_type_id, 
	category as cost_type
from 	im_categories
where 	category_type = 'Intranet Cost Type';


-------------------------------------------------------------
-- Cost Object Packages
--

prompt *** intranet-costs: Creating im_cost packages
begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
	object_type =>		'im_cost',
	pretty_name =>		'Cost',
	pretty_plural =>	'Costs',
	table_name =>		'im_costs',
	id_column =>		'cost_id',
	package_name =>		'im_cost',
	type_extension_table =>	null,
	name_method =>		'im_cost.name'
    );
end;
/
show errors


create or replace package im_cost
is
    function new (
	cost_id			in integer default null,
	object_type		in varchar default 'im_cost',
	creation_date		in date default sysdate,
	creation_user		in integer default null,
	creation_ip		in varchar default null,
	context_id		in integer default null,

	cost_name		in varchar default null,
	parent_id		in integer default null,
	project_id		in integer default null,
	customer_id		in integer,
	provider_id		in integer,
	investment_id		in integer default null,

	cost_status_id		in integer,
	cost_type_id		in integer,
	template_id		in integer default null,

	effective_date		in date default sysdate,
	payment_days		in integer default 30,
	amount			number default null,
	currency		in char default 'EUR',
	vat			in number default 0,
	tax			in number default 0,

	variable_cost_p		in char default 'f',
	needs_redistribution_p  in char default 'f',
	redistributed_p		in char default 'f',
	planning_p		in char default 'f',
	planning_type_id	in integer default null,

	note			in varchar default null,
	description		in varchar default null
    ) return im_costs.cost_id%TYPE;

    procedure del (cost_id in integer);
    function name (cost_id in integer) return varchar;
end im_cost;
/
show errors




create or replace package body im_cost
is
    function new (
	cost_id		 in integer default null,
	object_type	     in varchar default 'im_cost',
	creation_date	   in date default sysdate,
	creation_user	   in integer default null,
	creation_ip	     in varchar default null,
	context_id	      in integer default null,

	cost_name	       in varchar default null,
	parent_id	       in integer default null,
	project_id	      in integer default null,
	customer_id	     in integer,
	provider_id	     in integer,
	investment_id	   in integer default null,

	cost_status_id	  in integer,
	cost_type_id	    in integer,
	template_id	     in integer default null,

	effective_date	  in date default sysdate,
	payment_days	    in integer default 30,
	amount		  number default null,
	currency		in char default 'EUR',
	vat		     in number default 0,
	tax		     in number default 0,

	variable_cost_p	 in char default 'f',
	needs_redistribution_p  in char default 'f',
	redistributed_p	 in char default 'f',
	planning_p	      in char default 'f',
	planning_type_id	in integer default null,

	note		    in varchar default null,
	description	     in varchar default null
    ) return im_costs.cost_id%TYPE
    is
	v_cost_cost_id    im_costs.cost_id%TYPE;
    begin
	v_cost_cost_id := acs_object.new (
		object_id =>		cost_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	insert into im_costs (
		cost_id, cost_name, project_id, 
		customer_id, provider_id, 
		cost_status_id, cost_type_id,
		template_id, investment_id,
		effective_date, payment_days,
		amount, currency, vat, tax,
		variable_cost_p, needs_redistribution_p,
		parent_id, redistributed_p, 
		planning_p, planning_type_id, 
		description, note
	) values (
		v_cost_cost_id, new.cost_name, new.project_id, 
		new.customer_id, new.provider_id, 
		new.cost_status_id, new.cost_type_id,
		new.template_id, new.investment_id,
		new.effective_date, new.payment_days,
		new.amount, new.currency, new.vat, new.tax,
		new.variable_cost_p, new.needs_redistribution_p,
		new.parent_id, new.redistributed_p, 
		new.planning_p, new.planning_type_id, 
		new.description, new.note
	);

	return v_cost_cost_id;
    end new;

    -- Delete a single cost (if we know its ID...)
    procedure del (cost_id in integer)
    is
    begin
	-- Erase the im_cost
	delete from     im_costs
	where		cost_id = del.cost_id;

	-- Erase the object
	acs_object.del(del.cost_id);
    end del;

    function name (cost_id in integer) return varchar
    is
	v_name  varchar(40);
    begin
	select  cost_name
	into    v_name
	from    im_costs
	where   cost_id = name.cost_id;

	return v_name;
    end name;

end im_cost;
/
show errors



-- Create URLs for viewing/editing costs
delete from im_biz_object_urls where object_type='im_cost';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost','view','/intranet-cost/costs/new?form_mode=display\&cost_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost','edit','/intranet-cost/costs/new?form_mode=edit\&cost_id=');




-------------------------------------------------------------
-- Permissions and Privileges
--
begin
    acs_privilege.create_privilege('view_costs','View Costs','View Costs');
    acs_privilege.create_privilege('add_costs','View Costs','View Costs');
end;
/
show errors;



BEGIN
    im_priv_create('view_costs','Accounting');
    im_priv_create('view_costs','P/O Admins');
    im_priv_create('view_costs','Senior Managers');
END;
/
show errors;

BEGIN
    im_priv_create('add_costs','Accounting');
    im_priv_create('add_costs','P/O Admins');
    im_priv_create('add_costs','Senior Managers');
END;
/
show errors;


-------------------------------------------------------------
-- Finance Menu System
--

prompt *** intranet-costs: Deleting existing menus
BEGIN
    im_menu.del_module(module_name => 'intranet-trans-invoices');
    im_menu.del_module(module_name => 'intranet-payments');
    im_menu.del_module(module_name => 'intranet-invoices');
    im_menu.del_module(module_name => 'intranet-cost');
END;
/
show errors


prompt *** intranet-costs: Create Finance Menu
-- Setup the "Finance" main menu entry
--
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

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_customers from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_main_menu
    from im_menus
    where label='main';

    v_finance_menu := im_menu.new (
	package_name =>	'intranet-cost',
	label =>	'finance',
	name =>		'Finance',
	url =>		'/intranet-cost/',
	sort_order =>	80,
	parent_menu_id => v_main_menu
    );

    acs_permission.grant_permission(v_finance_menu, v_admins, 'read');
    acs_permission.grant_permission(v_finance_menu, v_senman, 'read');
    acs_permission.grant_permission(v_finance_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_finance_menu, v_customers, 'read');
    acs_permission.grant_permission(v_finance_menu, v_freelancers, 'read');

    -- -----------------------------------------------------
    -- General Costs
    -- -----------------------------------------------------

    -- needs to be the first submenu in order to get selected
    v_menu := im_menu.new (
	package_name =>	'intranet-cost',
	label =>	'costs',
	name =>		'Costs',
	url =>		'/intranet-cost/index',
	sort_order =>	80,
	parent_menu_id => v_finance_menu
    );
    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
end;
/
commit;


prompt *** intranet-costs: Create New Cost menus
-- Setup the "New Cost" menu for /intranet-cost/index
--
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
    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_customers from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_invoices_new_menu
    from im_menus
    where label='costs';

    v_finance_menu := im_menu.new (
	package_name =>	'intranet-cost',
	label =>	'cost_new',
	name =>		'New Cost',
	url =>		'/intranet-cost/costs/new',
	sort_order =>	10,
	parent_menu_id => v_invoices_new_menu
    );

    acs_permission.grant_permission(v_finance_menu, v_admins, 'read');
    acs_permission.grant_permission(v_finance_menu, v_senman, 'read');
    acs_permission.grant_permission(v_finance_menu, v_accounting, 'read');
end;
/
commit;


-------------------------------------------------------------
-- Cost Views
--

-- Cost Views
--
insert into im_views (view_id, view_name, visible_for)
values (220, 'cost_list', 'view_finance');
insert into im_views (view_id, view_name, visible_for)
values (221, 'cost_new', 'view_finance');

-- Cost List Page
--
delete from im_view_columns where column_id > 22000 and column_id < 22099;
--
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22001,220,'Name',
'"<A HREF=${cost_url}$cost_id>[string range $cost_name 0 30]</A>"',1);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22003,220,'Type','$object_type_pretty_name',3);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22005,220,'Project',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',5);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22007,220,'Provider',
'"<A HREF=/intranet/customers/view?customer_id=$provider_id>$provider_name</A>"',7);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22011,220,'Client',
'"<A HREF=/intranet/customers/view?customer_id=$customer_id>$customer_name</A>"',11);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22015,220,'Due Date',
'[if {$overdue > 0} {
	set t "<font color=red>$due_date_calculated</font>"
} else {
	set t "$due_date_calculated"
}]',15);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22021,220,'Amount','$amount_formatted $currency',21);

-- insert into im_view_columns values (22013,220,'Paid',
-- '$payment_amount $payment_currency',13);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22025,220,'Status',
'[im_cost_status_select "cost_status.$cost_id" $cost_status_id]',25);

-- insert into im_view_columns values (22098,220,'Del',
-- '[if {[string equal "" $payment_amount]} {
--	 set ttt "<input type=checkbox name=del_cost value=$cost_id>"
-- }]',99);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22098,220,'Del',
'<input type=checkbox name=del_cost value=$cost_id>',99);
commit;



-------------------------------------------------------------
-- Cost Components
--

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-cost');
END;
/

-- Show the cost component in project page
--
declare
    v_plugin	integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Project Cost Component',
	package_name =>	'intranet-cost',
	page_url =>     '/intranet/projects/view',
	location =>     'left',
	sort_order =>   90,
	component_tcl => 
	'im_costs_project_component $user_id $project_id'
    );
end;
/

-- Show the cost component in customers page
--
declare
    v_plugin	integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Customer Cost Component',
	package_name =>	'intranet-cost',
	page_url =>     '/intranet/customers/view',
	location =>     'left',
	sort_order =>   90,
	component_tcl => 
	'im_costs_customer_component $user_id $customer_id'
    );
end;
/
commit;
