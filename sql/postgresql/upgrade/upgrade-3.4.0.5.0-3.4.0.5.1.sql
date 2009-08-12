--  upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');


insert into im_views (view_id, view_name, visible_for, view_type_id) values (153, 'invoice_tasks', 'view_projects', 1400);

insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) values (153,15310,10,'Task Name','');
insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) values (153,15311,20,'Units','');
insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) values (153,15312,30,'Billable Units','');
insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) values (153,15313,40,'UoM','');
insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) values (153,15314,50,'Type','');
insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) values (153,15315,60,'Status','');


