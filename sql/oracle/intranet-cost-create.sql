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


-------------------------------------------------------------
-- Setup the status and type im_categories

-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3299    Intranet CRM Tracking
-- 3300-3399    reserved for cost centers
-- 3400-3499    Intranet Investment Type
-- 3500-3599    Intranet Investment Status
-- 3600-3699	Intranet Investment Amortization Interval (reserved)
-- 3700-3799    Intranet Cost Item Type
-- 3800-3899    Intranet Cost Item Status
-- 3900-3999    Intranet Cost Item Planning Type
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
	name			varchar(100) not null,
	cost_center_type_id	integer not null
				constraint im_cost_centers_type_fk
				references im_categories,
	cost_center_status_id	integer not null
				constraint im_cost_centers_status_fk
				references im_categories,
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
		unique(name, parent_id)
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
	name		in varchar,
	type_id		in integer,
	status_id	in integer,
	parent_id	in integer,
	manager_id	in integer default null,
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
	name		in varchar,
	type_id		in integer,
	status_id	in integer,
	parent_id	in integer,
	manager_id	in integer default null,
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
		cost_center_id, name, cost_center_type_id, 
		cost_center_status_id, parent_id, manager_id, description, note
	) values (
		v_cost_center_id, name, type_id, 
		status_id, parent_id, manager_id, description, note
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
	v_name	im_cost_centers.name%TYPE;
    begin
	select	name
	into	v_name
	from	im_cost_centers
	where	cost_center_id = cost_center_id;
    end name;
end im_cost_center;
/
show errors


prompt *** intranet-costs: Creating Cost Center categories

-- Intranet Cost Center Type
delete from im_categories where category_id >= 3000 and category_id < 3100;
INSERT INTO im_categories VALUES (3001,'Cost Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO im_categories VALUES (3002,'Profit Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO im_categories VALUES (3003,'Investment Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO im_categories VALUES (3004,'Subdepartment','Department without budget responsabilities','Intranet Cost Center Type',1,'f','');
commit;
-- reserved until 3099


-- Intranet Cost Center Type
delete from im_categories where category_id >= 3100 and category_id < 3200;
INSERT INTO im_categories VALUES (3101,'Active','','Intranet Cost Center Status',1,'f','');
INSERT INTO im_categories VALUES (3102,'Inactive','','Intranet Cost Center Status',1,'f','');
commit;
-- reserved until 3099





-------------------------------------------------------------
-- Setup the cost_centers of a small consulting company that
-- offers strategic consulting projects and IT projects,
-- both following a fixed methodology (number project phases).


prompt *** intranet-costs: Creating sample cost center configuration
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
	name =>		'The Company',
	type_id =>	3002,
	status_id =>	3101,
	parent_id => 	null,
	manager_id =>	null,
	description =>	'The top level center of the company',
	note =>		''
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
	name =>		'Administration',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Administration Cervice Center',
	note =>		''
    );

    -- Utilities Cost Center (3001)
    --
    v_utilities_center := im_cost_center.new (
	name =>		'Rent and Utilities',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Covers all repetitive costs such as rent, telephone, internet connectivity, ...',
	note =>		''
    );

    -- Sales Cost Center (3001)
    --
    v_sales_center := im_cost_center.new (
	name =>		'Sales',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Records all sales related activities, as oposed to marketing.',
	note =>		''
    );

    -- Marketing Cost Center (3001)
    --
    v_marketing_center := im_cost_center.new (
	name =>		'Marketing',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Marketing activities, such as website, promo material, ...',
	note =>		''
    );

    -- Project Operations Cost Center (3001)
    --
    v_projects_center := im_cost_center.new (
	name =>		'Project Operations',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Covers all phases of project-oriented execution activities..',
	note =>		''
    );

end;
/
show errors


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
-- all im_cost_items with the specific investment_id
--
prompt *** intranet-costs: Creating im_investments
create table im_investments (
	investment_id		integer
				constraint im_investments_pk
				primary key
				constraint im_investments_fk
				references acs_objects,
	name			varchar(400),
	investment_status_id	integer
				constraint im_investments_status_fk
				references im_categories,
	investment_type_id	integer
				constraint im_investments_type_fk
				references im_categories,
	amount			number(12,3),
	currency		char(3)
				constraint im_investments_currency_fk
				references currency_codes(iso),
	amort_start_date	date,
	amortization_months	integer,
	description		varchar(4000)
);


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
-- Cost Items
--
-- Cost items are possibly assigned to project, customers and/or investments,
-- whereever this is reasonable.
-- The idea is to be able to come up with profit/loss on a per-project base
-- as well as on a per-customer base.
-- Amortization items are additionally related to an investment, so that we
-- can track the amortized money
--
prompt *** intranet-costs: Creating im_cost_items
create table im_cost_items (
	item_id			integer
				constraint im_cost_items_pk
				primary key,
	-- force a name because we may want to use object.name()
	-- later to list cost items
	item_name		varchar(400)
				constraint im_cost_items_name_nn
				not null,
	project_id		integer
				constraint im_cost_items_project_fk
				references im_projects,
				-- who pays?
	customer_id		integer
				constraint im_cost_items_customer_nn
				not null
				constraint im_cost_items_customer_fk
				references im_customers,
				-- who gets paid?
	provider_id		integer
				constraint im_cost_items_provider_nn
				not null
				constraint im_cost_items_provider_fk
				references im_customers,
	item_status_id		integer
				constraint im_cost_items_status_nn
				not null
				constraint im_cost_items_status_fk
				references im_categories,
	item_type_id		integer
				constraint im_cost_item_type_nn
				not null
				constraint im_cost_item_type_fk
				references im_categories,
	template_id		integer
				constraint im_cost_item_template_fk
				references im_categories,
	investment_id		integer
				constraint im_cost_items_inv_fk
				references im_investments,
	-- when does the invoice start to be valid?
	-- due_date is input_date + payment_days.
	effective_date		date,
	payment_days		integer,
	payment_date		date,
	-- amount=null means calculated amount, for example
	-- with an invoice
	amount			number(12,3),
	currency		char(3) 
				constraint im_cost_items_currency_fk
				references currency_codes(iso),
	-- % of total price is VAT
	vat			number(12,5),
	-- % of total price is TAX
	tax			number(12,5),
	-- Classification of variable against fixed costs
	variable_cost_p		char(1)
				constraint im_cost_items_var_ck
				check (variable_cost_p in ('t','f')),
	needs_redistribution_p	char(1)
				constraint im_cost_items_needs_redist_ck
				check (needs_redistribution_p in ('t','f')),
	-- Points to its parent if the parent was distributed
	parent_id		integer
				constraint im_cost_items_parent_fk
				references im_cost_items,
	-- Indicates that this cost item has been redistributed to
	-- potentially several other items, so we don't want to
	-- include such items in sums.
	redistributed_p		char(1)
				constraint im_cost_items_redist_ck
				check (redistributed_p in ('t','f')),
	planning_p		char(1)
				constraint im_cost_items_planning_ck
				check (planning_p in ('t','f')),
	planning_type_id	integer
				constraint im_cost_items_planning_type_fk
				references im_categories,
	description		varchar(4000),
	note			varchar(4000)
);

prompt *** intranet-costs: Creating category Cost Item Type
-- Cost Item Type
delete from im_categories where category_id >= 3700 and category_id < 3799;
INSERT INTO im_categories VALUES (3700,'Customer Invoice','','Intranet Cost Item Type','category','t','f');
INSERT INTO im_categories VALUES (3702,'Quote','','Intranet Cost Item Type','category','t','f');
INSERT INTO im_categories VALUES (3704,'Provider Bill','','Intranet Cost Item Type','category','t','f');
INSERT INTO im_categories VALUES (3706,'Purchase Order','','Intranet Cost Item Type','category','t','f');

INSERT INTO im_categories VALUES (3708,'Customer Documents','','Intranet Cost Item Type','category','t','f');
INSERT INTO im_categories VALUES (3710,'Provider Documents','','Intranet Cost Item Type','category','t','f');
-- reserved until 3799


prompt *** intranet-costs: Creating category Cost Item Status
-- Intranet Cost Item Status
delete from im_categories where category_id >= 3700 and category_id < 3799;
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3802,'Created','Intranet Cost Item Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3804,'Outstanding','Intranet Cost Item Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3806,'Past Due','Intranet Cost Item Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3808,'Partially Paid','Intranet Cost Item Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3810,'Paid','Intranet Cost Item Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3812,'Deleted','Intranet Cost Item Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3814,'Filed','Intranet Cost Item Status');
commit;
-- reserved until 3899


prompt *** intranet-costs: Creating status and type views
create or replace view im_cost_item_status as
select
        category_id as item_status_id,
        category as item_status
from 	im_categories
where	category_type = 'Intranet Cost Item Status' and
        category_id not in (3812);

create or replace view im_cost_item_type as
select	category_id as item_type_id, 
	category as item_type
from 	im_categories
where 	category_type = 'Intranet Cost Item Type';


-------------------------------------------------------------
-- Cost Item Object Packages
--

prompt *** intranet-costs: Creating im_cost_item packages
begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
	object_type =>		'im_cost_item',
	pretty_name =>		'Cost Item',
	pretty_plural =>	'Cost Items',
	table_name =>		'im_cost_items',
	id_column =>		'item_id',
	package_name =>		'im_cost_item',
	type_extension_table =>	null,
	name_method =>		'im_cost_item.name'
    );
end;
/
show errors


create or replace package im_cost_item
is
    function new (
	item_id			in integer default null,
	object_type		in varchar default 'im_cost_item',
	creation_date		in date default sysdate,
	creation_user		in integer default null,
	creation_ip		in varchar default null,
	context_id		in integer default null,

	item_name		in varchar default null,
	parent_id		in integer default null,
	project_id		in integer default null,
	customer_id		in integer,
	provider_id		in integer,
	investment_id		in integer default null,

	item_status_id		in integer,
	item_type_id		in integer,
	template_id		in integer default null,

	effective_date		in date default sysdate,
	payment_days		in integer default 30,
	payment_date		in date default sysdate+30,
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
    ) return im_cost_items.item_id%TYPE;

    procedure del (item_id in integer);
    function name (item_id in integer) return varchar;
end im_cost_item;
/
show errors




create or replace package body im_cost_item
is
    function new (
        item_id                 in integer default null,
        object_type             in varchar default 'im_cost_item',
        creation_date           in date default sysdate,
        creation_user           in integer default null,
        creation_ip             in varchar default null,
        context_id              in integer default null,

        item_name               in varchar default null,
        parent_id               in integer default null,
        project_id              in integer default null,
        customer_id             in integer,
        provider_id             in integer,
        investment_id           in integer default null,

        item_status_id          in integer,
        item_type_id            in integer,
        template_id             in integer default null,

        effective_date          in date default sysdate,
        payment_days            in integer default 30,
        payment_date            in date default sysdate+30,
        amount                  number default null,
        currency                in char default 'EUR',
        vat                     in number default 0,
        tax                     in number default 0,

        variable_cost_p         in char default 'f',
        needs_redistribution_p  in char default 'f',
        redistributed_p         in char default 'f',
        planning_p              in char default 'f',
        planning_type_id        in integer default null,

        note                    in varchar default null,
        description             in varchar default null
    ) return im_cost_items.item_id%TYPE
    is
	v_cost_item_id    im_cost_items.item_id%TYPE;
    begin
	v_cost_item_id := acs_object.new (
		object_id =>		item_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	insert into im_cost_items (
		item_id, item_name, project_id, 
		customer_id, provider_id, 
		item_status_id, item_type_id,
		template_id, investment_id,
		effective_date, payment_days, payment_date,
		amount, currency, vat, tax,
		variable_cost_p, needs_redistribution_p,
		parent_id, redistributed_p, 
		planning_p, planning_type_id, 
		description, note
	) values (
		v_cost_item_id, new.item_name, new.project_id, 
		new.customer_id, new.provider_id, 
		new.item_status_id, new.item_type_id,
		new.template_id, new.investment_id,
		new.effective_date, new.payment_days, new.payment_date,
		new.amount, new.currency, new.vat, new.tax,
		new.variable_cost_p, new.needs_redistribution_p,
		new.parent_id, new.redistributed_p, 
		new.planning_p, new.planning_type_id, 
		new.description, new.note
	);

	return v_cost_item_id;
    end new;

    -- Delete a single cost_item (if we know its ID...)
    procedure del (item_id in integer)
    is
    begin
	-- Erase the im_cost_item
	delete from     im_cost_items
	where		item_id = del.item_id;

	-- Erase the object
	acs_object.del(del.item_id);
    end del;

    function name (item_id in integer) return varchar
    is
	v_name  varchar(40);
    begin
	select  item_name
	into    v_name
	from    im_cost_items
	where   item_id = name.item_id;

	return v_name;
    end name;

end im_cost_item;
/
show errors

-------------------------------------------------------------
-- Permissions and Privileges
--
begin
    acs_privilege.create_privilege('view_cost_items','View Cost Items','View Costs');
    acs_privilege.create_privilege('add_cost_items','View Cost Items','View Costs');
end;
/
show errors;



BEGIN
    im_priv_create('view_cost_items','Accounting');
    im_priv_create('view_cost_items','P/O Admins');
    im_priv_create('view_cost_items','Senior Managers');
END;
/
show errors;

BEGIN
    im_priv_create('add_cost_items','Accounting');
    im_priv_create('add_cost_items','P/O Admins');
    im_priv_create('add_cost_items','Senior Managers');
END;
/
show errors;


-------------------------------------------------------------
-- Finance Menu System
--

prompt *** intranet-costs: Deleting existing menus
BEGIN
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
    where url='/';

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
	label =>	'cost_items',
	name =>		'Cost Items',
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


prompt *** intranet-costs: Create New Cost Item menus
-- Setup the "New Cost Item" menu for /intranet-cost/index
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
    where label='cost_items';

    v_finance_menu := im_menu.new (
	package_name =>	'intranet-cost',
	label =>	'cost_new_item',
	name =>		'New Cost Item',
	url =>		'/intranet-cost/new',
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
values (220, 'cost_item_list', 'view_finance');
insert into im_views (view_id, view_name, visible_for)
values (221, 'cost_item_new', 'view_finance');

-- Cost Item List Page
--
delete from im_view_columns where column_id > 22000 and column_id < 22099;
--
insert into im_view_columns values (22001,220,NULL,'Name',
'"<A HREF=/intranet-cost/view?item_id=$item_id>[string range $item_name 0 30]</A>"',
'','',1,'');

insert into im_view_columns values (22003,220,NULL,'Type',
'$item_type','','',3,'');

insert into im_view_columns values (22004,220,NULL,'Provider',
'"<A HREF=/intranet/customers/view?customer_id=$provider_id>$provider_name</A>"',
'','',4,'');

insert into im_view_columns values (22005,220,NULL,'Client',
'"<A HREF=/intranet/customers/view?customer_id=$customer_id>$customer_name</A>"',
'','',5,'');

insert into im_view_columns values (22007,220,NULL,'Due Date',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date_calculated</font>"
} else {
        set t "$due_date_calculated"
}]','','',7,'');

insert into im_view_columns values (22011,220,NULL,'Amount',
'$amount_formatted $currency','','',11,'');

-- insert into im_view_columns values (22013,220,NULL,'Paid',
-- '$payment_amount $payment_currency','','',13,'');

insert into im_view_columns values (22017,220,NULL,'Status',
'[im_cost_item_status_select "item_status.$item_id" $item_status_id]','','',17,'');

-- insert into im_view_columns values (22098,220,NULL,'Del',
-- '[if {[string equal "" $payment_amount]} {
--         set ttt "<input type=checkbox name=del_cost_item value=$item_id>"
-- }]','','',99,'');

insert into im_view_columns values (22098,220,NULL,'Del',
'<input type=checkbox name=del_cost_item value=$item_id>','','',99,'');
commit;
