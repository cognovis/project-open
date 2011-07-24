-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

alter table im_invoice_items add column item_source_project_id integer constraint im_invoice_items_project_id_fk references im_projects; 



