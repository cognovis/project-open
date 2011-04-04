-- upgrade-4.0.0.9.9-4.0.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.2.0.0.sql','');



insert into im_views (view_id, view_name, visible_for, view_type_id)
values (26, 'personal_todo_list', 'view_projects', 1400);

--
delete from im_view_columns where column_id > 2600 and column_id < 2699;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2600,26,NULL,'Task',
'"<a HREF=$task_url$task_id>$task_name</A>"','','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2610,26,NULL,'Type',
'$task_type','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2620,26,NULL,'End',
'<nobr>$end_date_pretty</nobr>','','',20,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2630,26,NULL,'Prio',
'$priority</nobr>','','',30,'');

