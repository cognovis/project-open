

-- Add new fields to timesheet tasks
--

alter table im_timesheet_tasks
add start_date timestamptz;

alter table im_timesheet_tasks
add end_date timestamptz;

alter table im_timesheet_tasks
add priority integer;

alter table im_timesheet_tasks
add gantt_project_id integer;

alter table im_timesheet_tasks
add sort_order integer;


