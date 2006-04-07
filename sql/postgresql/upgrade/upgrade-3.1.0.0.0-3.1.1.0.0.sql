
-- Add an "office_id" field to the Invoice to allow
-- to select different delivery addresses 
alter table im_invoices
add invoice_office_id integer
	constraint im_invoices_office_fk
	references im_offices
;



-- Recompile the "im_invoices_active" view
--
-- all invoices that are not deleted (600) nor that have
-- been lost during creation (612).

drop view im_invoices_active;

create or replace view im_invoices_active as
select  i.*,
        ci.*,
        to_date(to_char(ci.effective_date,'YYYY-MM-DD'),'YYYY-MM-DD') + ci.payment_days as due_date,
        ci.effective_date as invoice_date,
        ci.cost_status_id as invoice_status_id,
        ci.cost_type_id as invoice_type_id,
        ci.template_id as invoice_template_id
from
        im_invoices i,
        im_costs ci
where
        ci.cost_id = i.invoice_id
        and ci.cost_status_id not in (3712);

