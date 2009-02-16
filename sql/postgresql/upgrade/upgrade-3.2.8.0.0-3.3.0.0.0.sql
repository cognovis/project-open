-- intranet-dw-light/upgrade-3.2.8.0.0-3.3.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-dw-light/sql/postgresql/upgrade/upgrade-3.2.8.0.0-3.3.0.0.0.sql','');


delete from im_view_columns where column_id = 2411;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2411,24,NULL,'PM','$project_lead','','',11,'');


delete from im_view_columns where column_id = 2413;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2413,24,NULL,'Key Account','$keyacc_name','','',13,'');


