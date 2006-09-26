

-- Get everything from a Cost Center
        select  cc.*
        from    im_cost_centers cc
        where   cc.cost_center_id = :cost_center_id
;


-- Create a new Cost Center
        PERFORM im_cost_center__new (
                null,                   -- cost_center_id
                'im_cost_center',       -- object_type
                now(),                  -- creation_date
                null,                   -- creation_user
                null,                   -- creation_ip
                null,                   -- context_id

                :cost_center_name,
                :cost_center_label,
                :cost_center_code,
                :cost_center_type_id,
                :cost_center_status_id,
                :parent_id,
                :manager_id,
                :department_p,
                :description,
                :note
        )
;


-- Update a Cost Center
        update im_cost_centers set
                cost_center_name        = :cost_center_name,
                cost_center_label       = :cost_center_label,
                cost_center_code        = :cost_center_code,
                cost_center_type_id     = :cost_center_type_id,
                cost_center_status_id   = :cost_center_status_id,
                department_p            = :department_p,
                parent_id               = :parent_id,
                manager_id              = :manager_id,
                description             = :description
        where
                cost_center_id = :cost_center_id
;


-- Delete a Cost Center

PERFORM im_cost_center__delete(:cost_center_id);




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


create or replace function inline_0 ()
returns integer as '
declare
	v_object_type		integer; 
begin
    v_object_type := acs_object_type__create_type (
	''im_cost_center'',	 -- object_type
	''Cost Center'',	 -- pretty_name
	''Cost Centers'',	 -- pretty_plural	
	''acs_object'',		 -- supertype
	''im_cost_centers'',	 -- table_name
	''cost_center_id'',	 -- id_column
	''im_cost_center'',	 -- package_name
	''f'',			 -- abstract_p
	null,			 -- type_extension_table
	''im_cost_center__name'' -- name_method
    );
    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


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
	description		varchar(4000),
	note			varchar(4000),
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
       integer,
       varchar,
       timestamptz,
       integer,
       varchar,
       integer,
       varchar,
       varchar,
       varchar,
       integer,
       integer,
       integer,
       integer,
       char,
       varchar,
       varchar)
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
	p_cost_center_code  alias for $9;	-- cost_center_code
	p_type_id	    alias for $10;	-- type_id
	p_status_id	    alias for $11;	-- status_id
	p_parent_id	    alias for $12;	-- parent_id
	p_manager_id	    alias for $13;	-- manager_id default null
	p_department_p	    alias for $14;	-- department_p default ''t''
	p_description	    alias for $15;	-- description default null
	p_note		    alias for $16;	-- note default null
	v_cost_center_id    integer;
 BEGIN
	v_cost_center_id := acs_object__new (
		p_cost_center_id,	    -- object_id
		p_object_type,		    -- object_type
		p_creation_date,	    -- creation_date
		p_creation_user,	    -- creation_user
		p_creation_ip,		    -- creation_ip
		p_context_id,		    -- context_id
		''t''			    -- security_inherit_p
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
	p_cost_center_id alias for $1;	-- cost_center_id
	v_cost_center_id	integer;
begin
	-- copy the variable to desambiguate the var name
	v_cost_center_id := p_cost_center_id;

	-- Erase the im_cost_centers item associated with the id
	delete from 	im_cost_centers
	where		cost_center_id = v_cost_center_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_cost_center_id;

	-- Finally delete the object iself
	acs_object__delete(v_cost_center_id);
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


-- prompt *** intranet-costs: Creating sample cost center configuration
delete from im_cost_centers;
create or replace function inline_0 ()
returns integer as '
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
	''The top level center of the company'',  -- description
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
	v_the_company_center,   -- parent_id
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
	''''		        -- note
    );
    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();



-------------------------------------------------------------
-- Helper functions to make our queries easier to read
-- and to avoid outer joins with parent projects etc.

-- Some helper functions to make our queries easier to read
create or replace function im_cost_center_label_from_id (integer)
returns varchar as '
DECLARE
        p_id	alias for $1;
        v_name	varchar(50);
BEGIN
        select	cc.cost_center_label
        into	v_name
        from	im_cost_centers cc
        where	cost_center_id = p_id;

        return v_name;
end;' language 'plpgsql';


create or replace function im_cost_center_name_from_id (integer)
returns varchar as '
DECLARE
        p_id	alias for $1;
        v_name	varchar(100);
BEGIN
        select	cc.cost_center_name
        into	v_name
        from	im_cost_centers cc
        where	cost_center_id = p_id;

        return v_name;
end;' language 'plpgsql';


create or replace function im_cost_center_code_from_id (integer)
returns varchar as '
DECLARE
        p_id	alias for $1;
        v_name	varchar(400);
BEGIN
        select	cc.cost_center_code
        into	v_name
        from	im_cost_centers cc
        where	cost_center_id = p_id;

        return v_name;
end;' language 'plpgsql';



