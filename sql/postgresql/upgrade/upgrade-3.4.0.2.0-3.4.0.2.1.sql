-- upgrade-3.4.0.2.0-3.4.0.2.1.sql

-- Relax unique constraint to include sort_order, in order
-- to avoid errors if an invoice includes several identical lines.
alter table im_invoice_items 
drop constraint im_invoice_items_un;

alter table im_invoice_items 
add constraint im_invoice_items_un 
unique (item_name, invoice_id, project_id, sort_order, item_uom_id);

