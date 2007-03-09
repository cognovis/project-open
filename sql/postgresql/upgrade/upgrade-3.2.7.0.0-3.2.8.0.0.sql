-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.2.7.0.0-3.2.8.0.0.sql


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2134,21,NULL,'Expenses',
'$cost_expense_logged_cache','','',34,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');


delete from im_view_columns where column_id = 2137;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2137,21,NULL,'Profit',
'[expr [n20 $cost_invoices_cache] - [n20 $cost_bills_cache] - [n20 $cost_expense_logged_cache] - [n20 $cost_timesheet_logged_cache]]',
'','',37,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

