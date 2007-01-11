-- upgrade-3.2.6.0.0-3.2.7.0.0.sql


-- Delete the "project_nr" column from the Tasks list

delete from im_view_columns where column_id= 91100;


# Replaced by im_biz_object_member relationship "pecentage" column
drop table im_timesheet_task_allocations;

