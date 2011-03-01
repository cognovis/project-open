-- upgrade-3.4.0.0.0-3.4.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-invoices/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql','');


update im_view_columns
set column_render_tcl = '"<a href=/intranet/projects/view?project_id=$project_id>$project_name</a>"'
where column_id = 3107;


create or replace function  im_timesheet_invoice__delete (integer)
returns integer as '
DECLARE
        p_invoice_id    alias for $1;
BEGIN
        -- Reset the invoiced-flag of all invoiced tasks
        update  im_timesheet_tasks
        set     invoice_id = null
        where   invoice_id = p_invoice_id;

        -- Reset the invoiced-flag of all included hours
        update  im_hours
        set     cost_id = null
        where   cost_id = p_invoice_id;

        -- Erase the invoice itself
        delete from     im_timesheet_invoices
        where           invoice_id = p_invoice_id;

        -- Erase the CostItem
        PERFORM im_invoice__delete(p_invoice_id);

        return 0;
end;' language 'plpgsql';

