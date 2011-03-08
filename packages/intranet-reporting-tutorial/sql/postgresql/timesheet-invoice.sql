------------------------------------------------------------
-- Timesheet Invoices
------------------------------------------------------------

-- Timesheet Invoices are a subtype of Invoice.
--
-- There are actually no additional data associated
-- with im_timesheet_invoice. Instead, it serves
-- to provide a specific "desctructor"
-- (im_timesheet_invoice__delete(:cost_id)) that
-- removes dependencies with im_timesheet_tasks.


-- Get the list of timesheet prices for a company.
select
	p.*,
	c.company_path as company_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_material_nr_from_id(material_id) as material
from
	im_timesheet_prices p
      LEFT JOIN
	im_companies c USING (company_id)
where
	p.company_id = :company_id
order by
	currency,
	uom_id,
	task_type_id desc;


-- Create a new Timesheet Invoice
select im_timesheet_invoice__new (
	:invoice_id,
	'im_timesheet_invoice',
	now(),
	:user_id,
	'[ad_conn peeraddr]',
	null,
	:invoice_nr,
	:customer_id,
	:provider_id,
	null,
	:invoice_date,
	'EUR',
	:template_id,
	:cost_status_id,
	:cost_type_id,
	:payment_method_id,
	:payment_days,
	'0',
	:vat,
	:tax,
	null
);

-- Associate a Timesheet Invoice with a project.
-- This works the same as with im_invoices and im_costs.
select acs_rel__new(
       null,
       'relationship',
       :project_id,
       :invoice_id,
       null,
       null,
       null
);

-- Update Timesheet Tasks and set points to the Timesheet Invoice.
-- These points are used to make sure that there is no TimesheetTask
-- that has not been invoiced yet.
--
update  im_timesheet_tasks
set     invoice_id = :invoice_id
where   task_id in ([join $im_timesheet_task ","]);



---------------------------------------------------------
-- Timesheet Invoices
--
-- We have made a "Timesheet Invoice" a separate object
-- mainly because it requires a different treatment when
-- it gets deleted, because of its interaction with
-- im_timesheet2_tasks and im_projects, that may get affected
-- affected (set back to the status "delivered") when a 
-- timesheet2-invoice is deleted.


create table im_timesheet_invoices (
	invoice_id		integer
				constraint im_timesheet_invoices_pk
				primary key
				constraint im_timesheet_invoices_fk
				references im_invoices
);
