------------------------------------------------------------
-- Projects
------------------------------------------------------------


-- Get everything about a Project
select
	p.*,
	c.company_name,
	c.company_path,
	to_char(p.end_date, 'HH24:MI') as end_date_time,
	to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
	to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
	to_char(p.percent_completed, '999990.9%') as percent_completed_formatted,
	im_category_from_id(p.project_type_id) as project_type,
	im_category_from_id(p.project_status_id) as project_status,
	c.primary_contact_id as company_contact_id,
	im_name_from_user_id(c.primary_contact_id) as company_contact,
	im_email_from_user_id(c.primary_contact_id) as company_contact_email,
	im_name_from_user_id(p.project_lead_id) as project_lead,
	im_name_from_user_id(p.supervisor_id) as supervisor,
	im_name_from_user_id(c.manager_id) as manager
from
	im_projects p,
	im_companies c

where
	p.project_id=:project_id
	and p.company_id = c.company_id
;


-- Get the entire Project hierarchy of a main project
select
	children.project_id as subproject_id,
	children.project_nr as subproject_nr,
	children.project_name as subproject_name,
	im_category_from_id(children.project_status_id) as subproject_status,
	im_category_from_id(children.project_type_id) as subproject_type,
	tree_level(children.tree_sortkey) -
	tree_level(parent.tree_sortkey) as subproject_level
from
	im_projects parent,
	$perm_sql children
where
	children.project_status_id not in (
		[im_project_status_deleted],
		[im_project_status_canceled]
	)
	and children.project_type_id not in (
		84, [im_project_type_task]
	)
	and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
	and parent.project_id = :super_project_id
order by 
	children.tree_sortkey
;


-- Select projects with permissions 
-- Only show projects with :user_id as a member.
SELECT *
FROM
	( SELECT
		p.*,
		c.company_name,
		im_name_from_user_id(project_lead_id) as lead_name,
		im_category_from_id(p.project_type_id) as project_type,
		im_category_from_id(p.project_status_id) as project_status,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
		to_char(p.end_date, 'HH24:MI') as end_date_time
		$extra_select
	FROM (
		select	p.*
		from	im_projects p,
			acs_rels r
		where	r.object_id_one = p.project_id
			and r.object_id_two = :user_id
			$where_clause
		) p,
		im_companies c
		$extra_from
	WHERE
		p.company_id = c.company_id
		$where_clause
		$extra_where
	) projects
$order_by_clause


-- Get all members of a Project
select
	r.*,
	m.object_role_id,
	o.object_type
from
	acs_rels r
		left outer join im_biz_object_members m
		on r.rel_id = m.rel_id,
	acs_objects o
where
	r.object_id_two = o.object_id
	and r.object_id_one = :project_id;


-- Partial update of a Project
-- We can never know all fields of a Project, because other
-- modules might have extended the project. However, other
-- modules can't add non-null fields.
update im_projects set
	project_name =  :project_name,
	project_path =  :project_path,
	project_nr =    :project_nr,
	project_type_id =:project_type_id,
	project_status_id =:project_status_id,
	project_lead_id =:project_lead_id,
	company_id =    :company_id,
	supervisor_id = :supervisor_id,
	parent_id =     :parent_id,
	description =   :description,
	requires_report_p =:requires_report_p,
	percent_completed = :percent_completed,
	on_track_status_id =:on_track_status_id,
	start_date =    $start_date,
	end_date =      $end_date
where
	project_id = :project_id;


-- Update the translation specific fields of a Project
update im_projects set
	company_project_nr =    :company_project_nr,
	company_contact_id =    :company_contact_id,
	source_language_id =    :source_language_id,
	subject_area_id =       :subject_area_id,
	expected_quality_id =   :expected_quality_id,
	final_company =	 :final_company,
	trans_project_words =   :trans_project_words,
	trans_project_hours =   :trans_project_hours
where
	project_id = :new_project_id;


-- Update Cost specific fields of a Project
update im_projects set
	cost_quotes_cache =	     :cost_quotes_cache,
	cost_invoices_cache =	   :cost_invoices_cache,
	cost_timesheet_planned_cache =  :cost_timesheet_planned_cache,
	cost_purchase_orders_cache =    :cost_purchase_orders_cache,
	cost_bills_cache =	      :cost_bills_cache,
	cost_timesheet_logged_cache =   :cost_timesheet_logged_cache
where
	project_id = :new_project_id;


-- Update a Project's budget
-- Only available for users with special permissions.
update	im_projects set
	project_budget =:project_budget,
	project_budget_currency =:project_budget_currency
where
	project_id = :project_id;


-- Create a new Project
select im_project__new (
	NULL,
	'im_project',
	:creation_date,
	:creation_user,
	:creation_ip,
	:context_id,
	:project_name,
	:project_nr,
	:project_path,
	:parent_id,
	:company_id,
	:project_type_id,
	:project_status_id
);

-- Select all subprojects (including the main project)
-- of a "main"-project
select
	p.*
from
	im_projects p
where
	p.project_id in (
		      select    children.project_id
		      from      im_projects parent,
				im_projects children
		      where
				children.tree_sortkey
					between parent.tree_sortkey
					and tree_right(parent.tree_sortkey)
				and parent.project_id = :project_id
		)
;

-------------------------------------------------------------
-- Projects
--

create table im_projects (
	project_id		integer
				constraint im_projects_pk 
				primary key 
				constraint im_project_prj_fk 
				references acs_objects,
	project_name		varchar(1000) not null,
	project_nr		varchar(100) not null,
	project_path		varchar(100) not null
				constraint im_projects_path_un unique,
	parent_id		integer 
				constraint im_projects_parent_fk 
				references im_projects,
	tree_sortkey		varbit,
	max_child_sortkey	varbit,

	-- Should be customer_id, but got renamed badly...
	company_id		integer not null
				constraint im_projects_company_fk 
				references im_companies,
	-- Should be customer_project_nr. Refers to the customers
	-- reference to our project.
	company_project_nr	varchar(200),
	-- Field indicating the final_customer if we are a subcontractor
	final_company		varchar(200),
	-- type of actions pursued during the project 
	-- implementation, for example "ERP Installation" or
	-- "ERP Upgrade", ...
	project_type_id		integer not null 
				constraint im_projects_prj_type_fk 
				references im_categories,
	-- status in the project cycle, from "potential", "quoting", ... to
	-- "open", "invoicing", "paid", "closed"
	project_status_id	integer not null 
				constraint im_projects_prj_status_fk 
				references im_categories,
	description		varchar(4000),
	billing_type_id		integer
				constraint im_project_billing_fk
				references im_categories,
	start_date		timestamptz,
	end_date		timestamptz,
				-- make sure the end date is after the start date
				constraint im_projects_date_const 
				check( end_date - start_date >= 0 ),	
	note			varchar(4000),
	-- project leader is responsible for the operational execution
	project_lead_id		integer 
				constraint im_projects_prj_lead_fk 
				references users,
	-- supervisor is the manager responsible for the financial success
	supervisor_id		integer 
				constraint im_projects_supervisor_fk 
				references users,
	requires_report_p	char(1) default('t')
				constraint im_project_requires_report_p 
				check (requires_report_p in ('t','f')),
				-- Total project budget (top-down planned)
	project_budget		float,
	project_budget_currency	char(3)
				constraint im_costs_paid_currency_fk
				references currency_codes(iso),
				-- Max number of hours for project.
				-- Does not require "view_finance" permission
	project_budget_hours	float,
				-- completion perc. estimation
	percent_completed	float
				constraint im_project_percent_completed_ck
				check (
					percent_completed >= 0 
					and percent_completed <= 100
				),
				-- green, yellow or red?
	on_track_status_id	integer
				constraint im_project_on_track_status_id_fk
				references im_categories,
				-- Should this project appear in the list of templates?
	template_p		char(1) default('f')
				constraint im_project_template_p
				check (requires_report_p in ('t','f')),
	company_contact_id	integer
				constraint im_project_company_contact_id_fk
				references users,
	sort_order		integer
);
