-- upgrade-3.2.1.0.0-3.2.2.0.0.sql

-- -------------------------------------------------------------------
-- Cost Centers

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
3402,34,NULL,'CostCenter','$cost_center_code','','',2,'');





