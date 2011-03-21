-- intranet-dw-light/upgrade-3.2.3.0.0-3.2.4.0.0.sql

SELECT acs_log__debug('/packages/intranet-dw-light/sql/postgresql/upgrade/upgrade-3.2.3.0.0-3.2.4.0.0.sql','');

delete from im_view_columns where column_id = 2489;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2489,24,NULL,'DelNotes','$cost_delivery_notes_cache','','',89,'');

