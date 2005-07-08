

-- using "last_visit_formatted" instead of "last_visit"

delete from im_view_columns where column_id = 1315;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1315,13,NULL,'Last Visit',
'$last_visit_formatted','','',15,'');

