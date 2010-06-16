-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');

delete from im_view_columns where column_id = 91101;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91101, 911, NULL, '"Task Name"',
'"<nobr>$indent_short_html$gif_html<a href=$object_url>$task_name</a></nobr>"','','',1,'');


delete from im_view_columns where column_id = 91002;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (91002,910,NULL,'"Task Name"',
'"<nobr>$indent_html$gif_html<a href=$object_url>$task_name</a></nobr>"','','',2,'');
