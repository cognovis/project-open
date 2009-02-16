-- upgrade-3.0.0.4.1-3.0.0.4.2.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-3.0.0.4.1-3.0.0.4.2.sql','');


-- Add a "Del" column for tasks

delete from im_view_columns where column_id = 91022;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91022,910,NULL,
'"[im_gif del "Delete"]"',
'"<input type=checkbox name=task_id.$task_id>"', '', '', 22, '');



delete from im_view_columns where column_id = 91112;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91112,911,NULL, 
'"[im_gif del "Delete"]"', 
'"<input type=checkbox name=task_id.$task_id>"', '', '', 12, '');
