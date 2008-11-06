-- upgrade-3.4.0.2.0-3.4.0.2.1.sql

-- Relax unique constraint to include sort_order, in order
-- to avoid errors if an invoice includes several identical lines.
alter table im_invoice_items 
drop constraint im_invoice_items_un;

alter table im_invoice_items 
add constraint im_invoice_items_un 
unique (item_name, invoice_id, project_id, sort_order, item_uom_id);


-- Update the link to the report to show included timesheet hours
update apm_parameter_values
set attr_value = '/intranet-reporting/timesheet-invoice-hours'
where parameter_id in (
	select	parameter_id
	from	apm_parameters
	where	package_key = 'intranet-invoices' and parameter_name = 'TimesheetInvoiceReport'
);

