--  upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');


insert into im_views (view_id, view_name, visible_for, view_type_id) values (153, 'invoice_tasks', 'view_projects', 1400);
insert into im_views (view_id, view_name, visible_for, view_type_id) values (154, 'invoice_tasks_sum', 'view_projects', 1400);


insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15310,10,'t.task_name','Task Name','');
insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15311,20,'t.task_units','Units','');
insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15312,30,'t.billable_units','Billable Units','');
insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15316,35,'target_language','Target','');
insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15313,40,'t.task_uom_id','UoM','');
insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15314,50,'t.task_type_id','Type','');
insert into im_view_columns (view_id, column_id, sort_order, order_by_clause, column_name, column_render_tcl) values (153,15315,60,'task_status','Status','');
