

-- Rename the im_price_idx to im_timesheet_price_idx
drop index im_price_idx;


create unique index im_timesheet_price_idx on im_timesheet_prices (
        uom_id, company_id, task_type_id, material_id, currency
);


-- Recompile the __delete procedure

-- Delete a single invoice (if we know its ID...)
create or replace function  im_timesheet_invoice__delete (integer)
returns integer as '
DECLARE
        p_invoice_id    alias for $1;
BEGIN
        -- Reset the status of all project to "delivered" that
        -- were included in the invoice
        update im_projects
        set project_status_id = 78
        where project_id in (
                select distinct
                        r.object_id_one
                from
                        acs_rels r
                where
                        r.object_id_two = p_invoice_id
        );

        -- Set all projects back to "delivered" that have tasks
        -- that were included in the invoices to delete.
        update im_projects
        set project_status_id = 78
        where project_id in (
                select distinct
                        t.project_id
                from
                        im_timesheet_tasks_view t
                where
                        t.invoice_id = p_invoice_id
        );

        -- Reset the status of all invoiced tasks to delivered.
        update  im_timesheet_tasks
        set     invoice_id = null
        where   invoice_id = p_invoice_id;

        -- Erase the invoice itself
        delete from     im_timesheet_invoices
        where           invoice_id = p_invoice_id;

        -- Erase the CostItem
        PERFORM im_invoice__delete(p_invoice_id);

        return 0;
end;' language 'plpgsql';

