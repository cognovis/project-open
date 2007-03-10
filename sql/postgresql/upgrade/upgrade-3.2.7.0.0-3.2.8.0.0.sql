-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.2.7.0.0-3.2.8.0.0.sql


-- Dirty field with date when the cache became "dirty"
alter table im_projects add     cost_cache_dirty                timestamptz;


-- Audit fields
alter table im_costs add last_modified           timestamptz;
alter table im_costs add last_modifying_user     integer;
alter table im_costs add constraint im_costs_last_mod_user foreign key (last_modifying_user) references users;
alter table im_costs add last_modifying_ip 	 varchar(20);




insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2134,21,NULL,'Expenses',
'$cost_expense_logged_cache','','',34,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');


delete from im_view_columns where column_id = 2137;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2137,21,NULL,'Profit',
'[expr [n20 $cost_invoices_cache] - [n20 $cost_bills_cache] - [n20 $cost_expense_logged_cache] - [n20 $cost_timesheet_logged_cache]]',
'','',37,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');


-- Add entry to show invalid cost cache
delete from im_view_columns where column_id = 2110;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2110,21,NULL,'Invalid Since',
'"$cost_cache_dirty"','','',10,'');


