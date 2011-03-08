-- upgrade-3.2.8.0.0-3.2.9.0.0.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-invoices/sql/postgresql/upgrade/upgrade-3.2.8.0.0-3.2.9.0.0.sql','');


create or replace function  im_timesheet_invoice__delete (integer)
returns integer as '
DECLARE
        p_invoice_id    alias for $1;
BEGIN
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

 