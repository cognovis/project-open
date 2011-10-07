-- upgrade-3.2.1.0.0-3.2.2.0.0.sql

SELECT acs_log__debug('/packages/intranet-freelance-invoices/sql/postgresql/upgrade/upgrade-3.2.1.0.0-3.2.2.0.0.sql','');

update im_menus 
set visible_tcl = '[im_cost_type_write_p $user_id 3704]'
where label = 'invoices_freelance_new_prov_invoice';


update im_menus 
set visible_tcl = '[im_cost_type_write_p $user_id 3706]'
where label = 'invoices_freelance_new_po';


