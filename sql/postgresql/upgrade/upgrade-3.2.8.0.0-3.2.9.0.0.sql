-- upgrade-3.2.8.0.0-3.2.9.0.0.sql

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.2.8.0.0-3.2.9.0.0.sql','');


-- Delete a single invoice (if we know its ID...)
-- DONT reset projects to status delivered anymore.
-- This should be done via a wizard or similar.
create or replace function  im_trans_invoice__delete (integer)
returns integer as '
DECLARE
        p_invoice_id    alias for $1;
BEGIN
        -- Reset the status of all invoiced tasks to delivered.
        update  im_trans_tasks
        set     invoice_id = null
        where   invoice_id = p_invoice_id;

        -- Erase the invoice itself
        delete from     im_trans_invoices
        where           invoice_id = p_invoice_id;

        -- Erase the CostItem
        PERFORM im_invoice__delete(p_invoice_id);

        return 0;
end;' language 'plpgsql';



