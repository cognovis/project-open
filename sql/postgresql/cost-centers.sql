------------------------------------------------------------
-- Cost Centers
------------------------------------------------------------

-- Get everything from a Cost Center
select  cc.*
from    im_cost_centers cc
where   cc.cost_center_id = :cost_center_id
;


-- Create a new Cost Center
PERFORM im_cost_center__new (
	null,		-- cost_center_id
	'im_cost_center',-- object_type
	now(),		-- creation_date
	null,		-- creation_user
	null,		-- creation_ip
	null,		-- context_id
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
);

-- Update a Cost Center
update im_cost_centers set
	cost_center_name	= :cost_center_name,
	cost_center_label       = :cost_center_label,
	cost_center_code	= :cost_center_code,
	cost_center_type_id     = :cost_center_type_id,
	cost_center_status_id   = :cost_center_status_id,
	department_p	    = :department_p,
	parent_id	       = :parent_id,
	manager_id	      = :manager_id,
	description	     = :description
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
	description		text,
	note			text,
		-- don't allow two cost centers under the same parent
		constraint im_cost_centers_un
		unique(cost_center_name, parent_id)
);
