

--------------------------------------------------------
-- Convert TimesheetTasks to Projects
--------------------------------------------------------


--------------------------------------------------------
-- 1. Create a new project for each timesheet task
create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select	t.*,
		p.company_id
        from	im_timesheet_tasks t,
		im_projects p
	where
		p.project_id = t.project_id
		and t.task_id not in (select project_id from im_projects)
	order by
		t.project_id
    loop
	RAISE NOTICE ''create projects for tasks: task_nr=%, project_id=%'', 
		row.task_nr, row.project_id;
	insert into im_projects (
		project_id, project_name, project_nr,
		project_path, parent_id, company_id,
		project_type_id, project_status_id, 
		description, start_date, end_date, 
		percent_completed
	) values (
		row.task_id, row.task_name, row.task_nr,
		row.task_nr, row.project_id, row.company_id,
		84, 76,
		row.description, row.start_date, row.end_date,
		row.percent_completed
	);
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


--------------------------------------------------------
-- 2. Remove tasks that don't have a project_id
-- (the referential integrity must have broken
-- at some moment in the past)


-- ToDo: Maybe create a new dummy project and MOVE the 
-- tasks to this dummy project so that the tasks and 
-- their timesheet information isn't lost?

delete from im_hours
where timesheet_task_id in (
	select	t.task_id
	from	im_timesheet_tasks t
	where	t.project_id not in (select project_id from im_projects)
);

delete from im_timesheet_tasks 
where project_id not in (select project_id from im_projects);



--------------------------------------------------------
-- 3. Change the foreign key constraint from acs_objects
-- to im_projects
--
alter table im_timesheet_tasks
drop constraint im_timesheet_task_fk;

alter table im_timesheet_tasks
add constraint im_timesheet_task_fk
FOREIGN KEY (task_id) references im_projects;



--------------------------------------------------------
-- 4. Delete the fields in im_timesheet_tasks that are
-- not necessary anymore (taken over by im_project)

alter table im_timesheet_tasks drop column project_id;
alter table im_timesheet_tasks drop column task_name;
alter table im_timesheet_tasks drop column task_type_id;
alter table im_timesheet_tasks drop column task_status_id;
alter table im_timesheet_tasks drop column description;
alter table im_timesheet_tasks drop column task_nr;
alter table im_timesheet_tasks drop column percent_completed;
alter table im_timesheet_tasks drop column start_date;
alter table im_timesheet_tasks drop column end_date;
alter table im_timesheet_tasks drop column gantt_project_id;




-- Create a unified view to tasks

drop view im_timesheet_tasks_view;

create or replace view im_timesheet_tasks_view as
select	t.*,
	p.parent_id as project_id,
	p.project_name as task_name,
	p.project_nr as task_nr,
	p.percent_completed,
	p.project_type_id as task_type_id,
	p.project_status_id as task_status_id,
	p.start_date,
	p.end_date
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

create index im_timesheet_tasks_dep_task_one_idx 
on im_timesheet_task_dependencies (task_id_one);

create index im_timesheet_tasks_dep_task_two_idx 
on im_timesheet_task_dependencies (task_id_two);




-- Allocate a user to a specific task 
-- with a certain percentage of his time
--
create table im_timesheet_task_allocations (
	task_id			integer
				constraint im_timesheet_task_alloc_task_nn
				not null
				constraint im_timesheet_task_alloc_task_fk
				references acs_objects,
        user_id			integer
				constraint im_timesheet_task_alloc_user_fk
				references users,
	role_id			integer
				constraint im_timesheet_task_alloc_role_fk
				references im_categories,
	percentage		numeric(6,2),
--				-- No check anymore - might want to alloc 120%...
--				constraint im_timesheet_task_alloc_perc_ck
--				check (percentage >= 0 and percentage <= 200),
	task_manager_p		char(1)
				constraint im_timesheet_task_resp_ck
				check (task_manager_p in ('t','f')),
	note			varchar(1000),

	primary key (task_id, user_id)
);

create index im_timesheet_tasks_dep_alloc_task_idx 
on im_timesheet_task_allocations (task_id);

create index im_timesheet_tasks_dep_alloc_user_idx 
on im_timesheet_task_allocations (user_id);


