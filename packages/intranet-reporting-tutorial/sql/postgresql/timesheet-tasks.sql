------------------------------------------------------------
-- Timesheet Tasks
------------------------------------------------------------

-- Show everything about a specrific Timesheet Task
-- It's a subclass of im_project.
select  m.*
from    im_timesheet_tasks_view m
where   m.task_id = :task_id


-- Show timesheet tasks per project
select
	t.*,
	im_category_from_id(t.uom_id) as uom_name,
	im_category_from_id(t.task_type_id) as type_name,
	im_category_from_id(t.task_status_id) as task_status,
	p.project_name,
	p.project_path,
	p.project_path as project_short_name
from
	im_timesheet_tasks_view t,
	im_projects p
where
	$tasks_where_clause
	and t.project_id = p.project_id
order by
	project_id, task_id;


-- Show timesheet tasks per project and subproject
select
	children.project_id as subproject_id,
	children.project_nr as subproject_nr,
	children.project_name as subproject_name,
	tree_level(children.tree_sortkey) -
	tree_level(parent.tree_sortkey) as subproject_level
from
	im_projects parent,
	im_projects children
where
	children.project_status_id not in 
		([im_project_status_deleted],[im_project_status_canceled])
	and children.tree_sortkey 
		between parent.tree_sortkey 
		and tree_right(parent.tree_sortkey)
	and parent.project_id = :restrict_to_project_id
order by
	children.tree_sortkey;


-- Calculate the sum of tasks (distinct by TaskType and UnitOfMeasure)
-- and determine the price of each line using a custom definable
-- function.
select
	sum(t.planned_units) as planned_sum,
	sum(t.billable_units) as billable_sum,
	sum(t.reported_hours_cache) as reported_sum,
	t.task_type_id,
	t.uom_id,
	p.company_id,
	p.project_id,
	t.material_id
from
	im_timesheet_tasks_view t,
	im_projects p
where
	$tasks_where_clause
	and t.project_id=p.project_id
group by
	t.material_id,
	t.task_type_id,
	t.uom_id,
	p.company_id,
	p.project_id
;

--  Calculate the price for the specific service.
--  Complicated undertaking, because the price depends on a number of variables,
--  depending on client etc. As a solution, we act like a search engine, return
--  all prices and rank them according to relevancy. We take only the first
--  (=highest rank) line for the actual price proposal.
-- 
select
	p.relevancy as price_relevancy,
	trim(' ' from to_char(p.price,:number_format)) as price,
	p.company_id as price_company_id,
	p.uom_id as uom_id,
	p.task_type_id as task_type_id,
	p.material_id as material_id,
	p.valid_from,
	p.valid_through,
	c.company_path as price_company_name,
	im_category_from_id(p.uom_id) as price_uom,
	im_category_from_id(p.task_type_id) as price_task_type,
	im_category_from_id(p.material_id) as price_material
from
	(
		(select
			im_timesheet_prices_calc_relevancy (
				p.company_id,:company_id,
				p.task_type_id, :task_type_id,
				p.material_id, :material_id
			) as relevancy,
			p.price,
			p.company_id,
			p.uom_id,
			p.task_type_id,
			p.material_id,
			p.valid_from,
			p.valid_through
		from im_timesheet_prices p
		where
			uom_id=:uom_id
			and currency=:invoice_currency
		)
	) p,
	im_companies c
where
	p.company_id=c.company_id
	and relevancy >= 0
order by
	p.relevancy desc,
	p.company_id,
	p.uom_id


-- Updating a Timesheet Task.
-- The information is spread between two tables,
-- im_timesheet_tasks and im_projects.
update im_timesheet_tasks set
	material_id     = :material_id,
	cost_center_id  = :cost_center_id,
	uom_id	  = :uom_id,
	planned_units   = :planned_units,
	billable_units  = :billable_units
where
	task_id = :task_id;

-- Update the Project part:
update im_projects set
	project_name    = :task_name,
	project_nr      = :task_nr,
	project_type_id = :task_type_id,
	project_status_id = :task_status_id,
	note	    = :description
where
	project_id = :task_id;



-- Create a new Timesheet Task.
	PERFORM im_timesheet_task__new (
		:task_id,	       -- p_task_id
		'im_timesheet_task',    -- object_type
		now(),		  -- creation_date
		null,		   -- creation_user
		null,		   -- creation_ip
		null,		   -- context_id

		:task_nr,
		:task_name,
		:project_id,
		:material_id,
		:cost_center_id,
		:uom_id,
		:task_type_id,
		:task_status_id,
		:description
	);


-- Delete a Timesheet Task.
	PERFORM im_task__delete (:task_id);



-- Calculate the percentage of advance of the project.
-- The query get a little bit complex because we
-- have to take into account the advance of the subprojects.
--
select
	sum(s.planned_units) as planned_units,
	sum(s.advanced_units) as advanced_units
from
	(select
	    t.task_id,
	    t.project_id,
	    t.planned_units,
	    t.planned_units * t.percent_completed / 100 as advanced_units
	from
	    im_timesheet_tasks_view t
	where
	    project_id in (
		select
			children.project_id as subproject_id
		from
			im_projects parent,
			im_projects children
		where
			children.project_status_id not in (82,83)
			and children.tree_sortkey between
			parent.tree_sortkey and tree_right(parent.tree_sortkey)
			and parent.project_id = :project_id
	    )
	) s
;

update	im_projects
set	percent_completed = (:advanced_units::numeric / :planned_units::numeric) * 100
where	project_id = :project_id;



-- Specifies how many units of what material are planned for
-- each project / subproject / task (all the same...)
-- Timesheet Tasks are now a subtype of project.
-- That may give us some more trouble "nuking" projects, 
-- but apart from that it's going to simplify the 
-- GanttProject integration, the hierarchical display of
-- projects and tasks in the timesheet entry page etc.
-- The main distinction line between a Task and a Project
-- is that a Project is completely generic, while a Task
-- draws strongly on intranet-cost and the financial 
-- management infrastructure.
--
create table im_timesheet_tasks (
	task_id			integer
				constraint im_timesheet_tasks_pk 
				primary key
				constraint im_timesheet_task_fk 
				references im_projects,
	material_id		integer 
				constraint im_timesheet_material_nn
				not null
				constraint im_timesheet_tasks_material_fk
				references im_materials,
	uom_id			integer
				constraint im_timesheet_uom_nn
				not null
				constraint im_timesheet_tasks_uom_fk
				references im_categories,
	planned_units		float,
	billable_units		float,
				-- link this task to an invoice in order to
				-- make sure it is invoiced.
	cost_center_id		integer
				constraint im_timesheet_tasks_cost_center_fk
				references im_cost_centers,
	invoice_id		integer
				constraint im_timesheet_tasks_invoice_fk
				references im_invoices,
	priority		integer,
	sort_order		integer
);


-- sum of timesheet hours cached here for reporting
alter table im_projects add reported_hours_cache float;


create or replace view im_timesheet_tasks_view as
select  t.*,
	p.parent_id as project_id,
	p.project_name as task_name,
	p.project_nr as task_nr,
	p.percent_completed,
	p.project_type_id as task_type_id,
	p.project_status_id as task_status_id,
	p.start_date,
	p.end_date,
	p.reported_hours_cache,
	p.reported_hours_cache as reported_units_cache
from
	im_projects p,
	im_timesheet_tasks t
where
	t.task_id = p.project_id
;


-- Defines the relationship between two tasks, based on
-- the data model of GanttProject.
-- <depend id="5" type="2" difference="0" hardness="Strong"/>
create table im_timesheet_task_dependencies (
	task_id_one		integer
				constraint im_timesheet_task_map_one_nn
				not null
				constraint im_timesheet_task_map_one_fk
				references acs_objects,
	task_id_two		integer
				constraint im_timesheet_task_map_two_nn
				not null
				constraint im_timesheet_task_map_two_fk
				references acs_objects,
	dependency_type_id	integer
				constraint im_timesheet_task_map_dep_type_fk
				references im_categories,
	difference		numeric(12,2),
	hardness_type_id	integer
				constraint im_timesheet_task_map_hardness_fk
				references im_categories,

	primary key (task_id_one, task_id_two)
);

