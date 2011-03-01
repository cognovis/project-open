------------------------------------------------------------
-- Translation Tasks
------------------------------------------------------------

-- Get the Translation Tasks of a specific project
select
	t.*,
	p.project_name,
	im_category_from_id(t.task_status_id) as task_status,
	im_category_from_id(t.source_language_id) as source_language,
	im_category_from_id(t.target_language_id) as target_language
from
	im_trans_tasks t,
	im_projects p
where
	t.task_id = :task_id
	and t.project_id = p.project_id
	and p.project_id = :project_id"
;



-- Calculate the sum of the units of all tasks
-- of a given project
select
	sum(t.billable_units) as task_sum,
	'' as task_title,
	t.task_type_id,
	t.task_uom_id,
	t.source_language_id,
	t.target_language_id,
	p.company_id,
	p.project_id,
	p.subject_area_id
from
	im_trans_tasks t,
	im_projects p
where
	$tasks_where_clause
	and t.project_id=p.project_id
group by
	t.task_type_id,
	t.task_uom_id,
	p.company_id,
	p.project_id,
	t.source_language_id,
	t.target_language_id,
	p.subject_area_id
;


-- Get a list of all projects that contain uninvoiced tasks.
select
	p.*,
	t.*
from
	im_trans_tasks t,
	im_projects p
where
	t.project_id = p.project_id
	and t.invoice_id is null
	and t.task_status_id in (
		select task_status_id
		from im_task_status
		where upper(task_status) not in (
			'CLOSED','INVOICED','PARTIALLY PAID',
			'DECLINED','PAID','DELETED','CANCELED'
		)
	)
	$projects_where_clause
order by
	project_id, task_id
;


-- Determine the number of Trans Tasks per Project
select
	p.*,
	c.*
from
	im_projects p,
	im_companies c,
	(select project_id,
		count(*) as task_count
	 from   im_trans_tasks
	 where  1=1 $task_invoice_id_null
	 group by project_id
	) t
where
	p.project_id = t.project_id
	and t.task_count > 0
	and c.company_id = p.company_id
;


-- Update a Translation Task
UPDATE im_trans_tasks SET
	tm_integration_type_id = [im_trans_tm_integration_type_external],
	task_name = :task_name,
	task_filename = :task_name,
	description = :task_description,
	task_units = :task_units,
	billable_units = :billable_units,
	match_x = :px_words,
	match_rep = :prep_words,
	match100 = :p100_words,
	match95 = :p95_words,
	match85 = :p85_words,
	match75 = :p75_words,
	match50 = :p50_words,
	match0 = :p0_words
WHERE
	task_id = :new_task_id
;


-- Create a new Translation Task
SELECT im_trans_task__new (
	null,			-- task_id
	'im_trans_task',	-- object_type
	now(),			-- creation_date
	:user_id,		-- creation_user
	:ip_address,		-- creation_ip
	null,			-- context_id
	:project_id,		-- project_id
	:task_type_id,		-- task_type_id
	:task_status_id,	-- task_status_id
	:source_language_id,	-- source_language_id
	:target_language_id,	-- target_language_id
	:task_uom_id		-- task_uom_id
)


-- Assign translator, editor and proof reader to a task
update im_trans_tasks set
	trans_id=:trans,
	edit_id=:edit,
	proof_id=:proof,
	other_id=:other
where
	task_id=:task_id
;


-----------------------------------------------------------
-- Intranet Translation Tasks
--
-- - Every project can have any number of "Tasks".
-- - Each task represents a work unit that can be billed
--   independently and that will appear as a line in
--   the final invoice to be printed.


create table im_trans_tasks (
	task_id			integer
				constraint im_trans_tasks_pk
				primary key
				constraint im_trans_task_id_fk
				references acs_objects,
	project_id		integer not null
				constraint im_trans_tasks_project_fk
				references im_projects,
	target_language_id	integer
				constraint im_trans_tasks_target_lang_fk
				references im_categories,
				-- task_name take a filename for the
				-- language processing application
	task_name		varchar(1000),
				-- task_filename!=null indicates a file task
	task_filename		varchar(1000) default null,
	task_type_id		integer not null
				constraint im_trans_tasks_type_fk
				references im_categories,
	task_status_id		integer not null
				constraint im_trans_tasks_status_fk
				references im_categories,
				-- Trados or Ophelia or Xxxx
				-- not a Not Null constraint yet
	tm_type_id		integer
				constraint im_trans_tasks_tm_type_fk
				references im_categories,
	description		varchar(4000),
	source_language_id	integer not null
				constraint im_trans_tasks_source_fk
				references im_categories,
				-- fees: N units of "UoM" (Unit of Measurement)
				-- raw units to be delivered to the client
	task_units		numeric(12,1),
				-- sometimes, not all units can be billed...
	billable_units		numeric(12,1),
				-- UoM=Unit of Measure (hours, words, ...)
	task_uom_id		integer not null
				constraint im_trans_tasks_uom_fk
				references im_categories,
				-- references to financial documents: helps to make
				-- sure a single task isn't invoiced twice or not
				-- being invoiced at all...
				-- invoice_id=null => needs to be invoiced still
				-- invoice_id!= null => has already been invoiced
	invoice_id		integer
				constraint im_trans_tasks_invoice_fk
				references im_invoices,
	quote_id		integer
				constraint im_trans_tasks_quote_fk
				references im_invoices,
				-- "Trados Matrix" determine duplicated words
	match_x			numeric(12,0),
	match_rep		numeric(12,0),
	match100		numeric(12,0),
	match95			numeric(12,0),
	match85			numeric(12,0),
	match75			numeric(12,0),
	match50			numeric(12,0),
	match0			numeric(12,0),
				-- Translation Workflow
	trans_id		integer
				constraint im_trans_tasks_trans_fk
				references users,
	edit_id			integer
				constraint im_trans_tasks_edit_fk
				references users,
	proof_id		integer
				constraint im_trans_tasks_proof_fk
				references users,
	other_id		integer
				constraint im_trans_tasks_other_fk
				references users,
				-- New field to indicate translators when
				-- this task should be finished.
				-- Defaults to project end_date
	end_date		timestamptz
);


-- define into which language we have to translate a certain project.
create table im_target_languages (
	project_id		integer not null
				constraint im_target_lang_proj_fk
				references im_projects,
	language_id		integer not null
				constraint im_target_lang_lang_fk
				references im_categories,
	primary key (project_id, language_id)
);

