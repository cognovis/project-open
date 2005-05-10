

alter table im_hours add
        timesheet_task_id       integer
                                constraint im_hours_task_id_fk
                                references im_timesheet_tasks
;

create index im_hours_day_idx on im_hours(day);
