-- upgrade-3.2.1.0.0-3.2.2.0.0.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-invoices/sql/postgresql/upgrade/upgrade-3.2.1.0.0-3.2.2.0.0.sql','');


update im_menus 
set visible_tcl = '[im_cost_type_write_p $user_id 3700]'
where label = 'invoices_timesheet_new_cust_invoice';


update im_menus 
set visible_tcl = '[im_cost_type_write_p $user_id 3702]'
where label = 'invoices_timesheet_new_quote';

