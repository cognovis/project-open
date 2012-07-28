SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql','');

-------------------------------
-- Timesheet Task Scheduling Type
SELECT im_category_new(9700,'As soon as possible', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9701,'As late as possible', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9702,'Must start on', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9703,'Must finish on', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9704,'Start no earlier than', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9705,'Start no later than', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9706,'Finish no earlier than', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9707,'Finish no later than', 'Intranet Timesheet Task Scheduling Type');

update im_categories set aux_int1 = 0 where category_id = 9700;
update im_categories set aux_int1 = 1 where category_id = 9701;
update im_categories set aux_int1 = 2 where category_id = 9702;
update im_categories set aux_int1 = 3 where category_id = 9703;
update im_categories set aux_int1 = 4 where category_id = 9704;
update im_categories set aux_int1 = 5 where category_id = 9705;
update im_categories set aux_int1 = 6 where category_id = 9706;
update im_categories set aux_int1 = 7 where category_id = 9707;

-- upgrade-4.0.3.0.4-4.0.3.0.5.sql

delete from im_view_columns where column_id = 91014 and view_id = 910;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91014,910,NULL,'Log',
'"<p align=right><a href=[export_vars -base $timesheet_report_url { { project_id $project_id } return_url}]>
$reported_units_cache</a></p>"','','',14,'');

