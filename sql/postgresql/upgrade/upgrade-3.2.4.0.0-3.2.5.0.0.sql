-- upgrade-3.2.4.0.0-3.2.5.0.0.sql

-- Add a "Username" field to the users view page


delete from im_view_columns where column_id=1107;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1107,11,NULL,'Username',
'$username','','',4,
'parameter::get_from_package_key -package_key intranet-core -parameter EnableUsersUsernameP -default 0');






