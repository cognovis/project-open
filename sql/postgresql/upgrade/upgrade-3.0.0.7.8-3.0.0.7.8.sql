-- upgrade-3.0.0.7.8-3.0.0.7.8.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-3.0.0.7.8-3.0.0.7.8.sql','');


alter table im_timesheet_tasks add
        percent_completed       numeric(6,2)
                                constraint im_timesheet_tasks_perc_ck
                                check(percent_completed >= 0 and percent_completed <= 100)
;

-- Don't add a default to save time to update only
-- non-NULL values
--
-- add the default 0 value
-- alter table im_timesheet_tasks
-- alter column percent_completed
-- set default 0
-- ;



-- Wide View in "Tasks" page, including Description
--
delete from im_view_columns where view_id = 910;
delete from im_views where view_id = 910;
--
insert into im_views (view_id, view_name, visible_for) values (910, 'im_timesheet_task_list', 'view_projects');


delete from im_view_columns where column_id >= 91000 and column_id < 91099;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91000,910,NULL,'"Task Code"',
'"<a href=/intranet-timesheet2-tasks/new?[export_url_vars project_id task_id return_url]>
$task_nr</a>"','','',0,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91002,910,NULL,'"Task Name"',
'"<a href=/intranet-timesheet2-tasks/new?[export_url_vars project_id task_id return_url]>
$task_name</a>"','','',2,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91004,910,NULL,'Material',
'"<a href=/intranet-material/new?[export_url_vars material_id return_url]>$material_nr</a>"',
'','',4,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91006,910,NULL,'"Cost Center"',
'"<a href=/intranet-cost/cost-centers/new?[export_url_vars cost_center_id return_url]>$cost_center_name</a>"',
'','',6,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91010,910,NULL,'Plan',
'$planned_units','','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91012,910,NULL,'Bill',
'$billable_units','','',12,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91014,910,NULL,'Log',
'"<a href=[export_vars -base $timesheet_report_url { task_id { project_id $project_id } return_url}]>
$reported_units_cache</a>"','','',14,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91016,910,NULL,'UoM',
'$uom','','',16,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91018,910,NULL,'Status',
'$task_status','','',18,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91020,910,NULL, 'Description',
'[string_truncate -len 80 " $description"]', '','',20,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91021,910,NULL, 'Done',
'"<input type=textbox size=6 name=percent_completed.$task_id value=$percent_completed>"',
'','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91022,910,NULL,
'"[im_gif del "Delete"]"',
'"<input type=checkbox name=task_id.$task_id>"', '', '', 22, '');




--
-- short view in project homepage
--
delete from im_view_columns where view_id = 911;
delete from im_views where view_id = 911;
--
insert into im_views (view_id, view_name, visible_for) values (911,
'im_timesheet_task_list_short', 'view_projects');
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91100,911,NULL,'"Project Nr"',
'"<a href=/intranet/projects/view?[export_url_vars project_id]>$project_nr</a>"',
'','',0,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91101,911,NULL,'"Task Name"',
'"<a href=/intranet-timesheet2-tasks/new?[export_url_vars project_id task_id return_url]>
$task_name</a>"','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91103,911,NULL,'Material',
'"<a href=/intranet-material/new?[export_url_vars material_id return_url]>$material_nr</a>"',
'','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91104,911,NULL,'Plan',
'$planned_units','','',4,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91106,911,NULL,'Bill',
'$billable_units','','',6,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91108,911,NULL,'Log',
'"<a href=[export_vars -base $timesheet_report_url { task_id { project_id $project_id } return_url}]>
$reported_units_cache</a>"','','',8,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91109,911,NULL,'"%"',
'$percent_completed_rounded','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91110,911,NULL,'UoM',
'$uom','','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91112,911,NULL,
'"[im_gif del "Delete"]"',
'"<input type=checkbox name=task_id.$task_id>"', '', '', 12, '');

