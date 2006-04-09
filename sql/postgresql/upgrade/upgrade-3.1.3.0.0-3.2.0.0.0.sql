

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

create or replace view im_timesheet_tasks_view as
select  p.*,
        t.*,
	p.project_type_id as task_type_id,
	p.project_status_id as task_status_id,
from
	im_projects p,
	im_timesheet_tasks t
where
	t.task_id = p.project_id
;
