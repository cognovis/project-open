-- intranet-dw-light/upgrade-3.2.7.0.0-3.2.8.0.0.sql

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
2478,24,NULL,'LoggedHours','$reported_hours_cache','','',78,'');

