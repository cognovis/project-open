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


create or replace package im_cost_center
is
    function new (
	cost_center_id	in integer,
	object_type	in varchar,
	creation_date	in date,
	creation_user	in integer,
	creation_ip	in varchar,
	context_id	in integer,

	name		in varchar,
	type_id		in integer,
	status_id	in integer,
	parent_id	in integer,
	manager_id	in integer,
	description	in varchar,
	note		in varchar
    ) return im_cost_centers.cost_center_id%TYPE;

    procedure del (cost_center_id in integer);
    procedure name (cost_center_id in integer);
end im_cost_center;
/
show errors


create or replace package body im_cost_center
is

    function new (
	cost_center_id	in integer,
	object_type	in varchar,
	creation_date	in date,
	creation_user	in integer,
	creation_ip	in varchar,
	context_id	in integer,

	name		in varchar,
	type_id		in integer,
	status_id	in integer,
	parent_id	in integer,
	manager_id	in integer,
	description	in varchar,
	note		in varchar
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


-------------------------------------------------------------
-- Setup the status and type im_categories

-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3399	reserved for cost centers
-- 3400-3499	Intranet Cost Investment Type
-- 3500-3599	Intranet Cost Investment Status


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


declare
    v_the_company_center	integer;
    v_admin_center		integer;
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


    -- The Administrative Dept.: A typical cost center (3001)
    -- We asume a small company, so there is only one manager
    -- taking budget control of Finance, Accounting, Legal and
    -- HR stuff.
    --
    v_user_center := im_cost_center.new (
	name =>		'Administration',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Administration Cervice Center',
	note =>		''
    );

    -- Sales & Marketing Cost Center (3001)
    -- Project oriented companies normally doesn't have a lot 
    -- of marketing, so we don't overcomplicate here.
    --
    v_user_center := im_cost_center.new (
	name =>		'Sales & Marketing',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Takes all sales related activities, as oposed to project execution.',
	note =>		''
    );

    -- Sales & Marketing Cost Center (3001)
    -- Project oriented companies normally doesn't have a lot 
    -- of marketing, so we don't overcomplicate here.
    --
    v_user_center := im_cost_center.new (
	name =>		'Sales & Marketing',
	type_id =>	3001,
	status_id =>	3101,
	parent_id => 	v_the_company_center,
	manager_id =>	null,
	description =>	'Takes all sales related activities, as oposed to project execution.',
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


-- Setup the status and type im_categories
-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3399	reserved for cost centers
-- 3400-3499	Intranet Cost Investment Type
-- 3500-3599	Intranet Cost Investment Status
-- 3600-3699	Intranet Cost Investment Amortization Interval

-- Intranet Cost Investment Type
delete from im_categories where category_id >= 3400 and category_id < 3500;
INSERT INTO im_categories VALUES (3401,'Other','','Intranet Cost Investment Type',1,'f','');
INSERT INTO im_categories VALUES (3402,'Computer Hardware','','Intranet Cost Investment Type',1,'f','');
INSERT INTO im_categories VALUES (3403,'Computer Software','','Intranet Cost Investment Type',1,'f','');
INSERT INTO im_categories VALUES (3404,'Office Furniture','','Intranet Cost Investment Type',1,'f','');
commit;
-- reserved until 3499

-- Intranet Cost Investment Status
delete from im_categories where category_id >= 3500 and category_id < 3600;
INSERT INTO im_categories VALUES (3501,'Active','','Intranet Cost Investment Status',1,'f','Currently being amortized');
INSERT INTO im_categories VALUES (3502,'Deleted','','Intranet Cost Investment Status',1,'f','Deleted - was an error');
INSERT INTO im_categories VALUES (3503,'Amortized','','Intranet Cost Investment Status',1,'f','Finished amortization - no remaining book value');
commit;
-- reserved until 3599

-- Intranet Cost Investment Amortization Internval
delete from im_categories where category_id >= 3600 and category_id < 3700;
INSERT INTO im_categories VALUES (3601,'Month','','Intranet Cost Investment Amortization Internval',1,'f','Currently being amortized');
INSERT INTO im_categories VALUES (3602,'Quarter','','Intranet Cost Investment Amortization Internval',1,'f','Currently being amortized');
INSERT INTO im_categories VALUES (3603,'Year','','Intranet Cost Investment Amortization Internval',1,'f','Currently being amortized');
commit;
-- reserved until 3699



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
create table im_cost_items (
	item_id			integer
				constraint im_cost_items_pk
				primary key,
	name			varchar(400),
	project_id		integer
				constraint im_cost_items_project_fk
				references im_projects,
	customer_id		integer
				constraint im_cost_items_customer_fk
				references im_customers,
	investment_id		integer
				constraint im_cost_items_inv_fk
				references im_investments,
	creation_date		date,
	creator_id		integer
				constraint im_cost_items_creator_fk
				references parties,
	input_date		date,
	due_date		date,
	payment_date		date,
	amount			number(12,3),
	currency		char(3) 
				constraint im_cost_items_currency_fk
				references currency_codes(iso),
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
	description		varchar(4000)
);
