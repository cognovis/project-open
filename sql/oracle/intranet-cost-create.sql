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
-- Responsability Centers
--
-- Responsability Centers (cost-, revenue- and investment centers) 
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
	object_type =>		'im_center',
	pretty_name =>		'Responsability Center',
	pretty_plural =>	'Responsability Centers',
	table_name =>		'im_centers',
	id_column =>		'center_id',
	package_name =>		'im_center',
	type_extension_table =>	null,
	name_method =>		'im_center.name'
    );
end;
/
show errors


create table im_centers (
	center_id		integer
				constraint im_centers_pk
				primary key
				constraint im_centers_id_fk
				references acs_objects,
	center_name		varchar(100) not null,
	center_type_id		integer not null
				constraint im_centers_type_fk
				references categories,
	center_status_id	integer not null
				constraint im_centers_status_fk
				references categories,
				-- Where to report costs?
				-- The "Corporate" center has parent_id=null.
	parent_id		integer 
				constraint im_centers_parent_fk
				references im_centers,
				-- Who is responsible for this center?
	manager_id		integer
				constraint im_centers_manager_fk
				references users,
	description		varchar(4000),
	note			varchar(4000)
);
create index im_centers_parent_id_idx on im_centers(parent_id);
create index im_centers_manager_id_idx on im_centers(manager_id);


create or replace package im_center
is
    function new (
	center_id	in integer,
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
    ) return im_centers.center_id%TYPE;

    procedure del (center_id in integer);
    procedure name (center_id in integer);
end im_center;
/
show errors


create or replace package body im_center
is

    function new (
	center_id	in integer,
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
    ) return im_centers.center_id%TYPE
    is
	v_center_id	im_centers.center_id%TYPE;
    begin
	v_center_id := acs_object.new (
		object_id =>		center_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	insert into im_centers (
		center_id, center_name, center_type_id, 
		center_status_id, parent_id, manager_id, description, note
	) values (
		v_center_id, name, type_id, 
		status_id, parent_id, manager_id, description, note
	);
	return v_center_id;
    end new;


    -- Delete a single center (if we know its ID...)
    procedure del (center_id in integer)
    is
	v_center_id	integer;
    begin
	-- copy the variable to desambiguate the var name
	v_center_id := center_id;

	-- Erase the im_centers item associated with the id
	delete from 	im_centers
	where		center_id = v_center_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_center_id;

	-- Finally delete the object iself
	acs_object.del(v_center_id);
    end del;


    procedure name (center_id in integer)
    is
	v_name	im_centers.center_name%TYPE;
    begin
	select	center_name
	into	v_name
	from	im_centers
	where	center_id = center_id;
    end name;
end im_center;
/
show errors


-------------------------------------------------------------
-- Setup the status and type categories

-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status

-- Intranet Cost Center Type
delete from categories where category_id >= 3000 and category_id < 3100;

INSERT INTO categories VALUES (3001,'Cost Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO categories VALUES (3002,'Profit Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO categories VALUES (3003,'Investment Center','','Intranet Cost Center Type',1,'f','');
INSERT INTO categories VALUES (3004,'Subdepartment','Department without budget responsabilities','Intranet Cost Center Type',1,'f','');

commit;
-- reserved until 3099


-- Intranet Cost Center Type
delete from categories where category_id >= 3100 and category_id < 3200;

INSERT INTO categories VALUES (3101,'Active','','Intranet Cost Center Status',1,'f','');
INSERT INTO categories VALUES (3102,'Inactive','','Intranet Cost Center Status',1,'f','');

commit;
-- reserved until 3099





-------------------------------------------------------------
-- Setup the centers of a small consulting company that
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
    v_the_company_center := im_center.new (
	center_id =>	null,
	object_type =>	'im_center',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
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
    v_user_center := im_center.new (
	center_id =>	null,
	object_type =>	'im_center',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
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
    v_user_center := im_center.new (
	center_id =>	null,
	object_type =>	'im_center',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
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
    v_user_center := im_center.new (
	center_id =>	null,
	object_type =>	'im_center',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
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

