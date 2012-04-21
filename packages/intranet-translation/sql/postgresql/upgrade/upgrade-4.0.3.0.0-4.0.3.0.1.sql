-- upgrade-4.0.3.0.0-4.0.3.0.1.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');

-- Delete previous columns.
delete from im_view_columns where view_id = 90 and column_id = 9083; 


-- Allow translation tasks to be checked/unchecked all together
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (9083,90,NULL,'Description','$description_input','','', 830,'');
