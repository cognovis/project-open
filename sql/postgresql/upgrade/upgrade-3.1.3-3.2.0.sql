--
-- upgrade-3.1.3-3.2.0.sql


-- Very ugly - we need to reverse the introduction
-- of timesheet-tasks in for logging hours. Now
-- timesheet-tasks are a subclass of im_project.

-- copy the timesheet_task column to projects 
-- and drop the column
update im_hours set project_id = timesheet_task_id;
alter table im_hours drop timesheet_task_id;


-- Recreate the indices. 
-- Got lost when removing the timesheet-task field
--
alter table im_hours add primary key (user_id, project_id, day);
create index im_hours_project_id_idx on im_hours(project_id);
create index im_hours_user_id_idx on im_hours(user_id);
create index im_hours_day_idx on im_hours(day);


