
-- -------------------------------------------------------------
-- Helper function

create or replace function im_invoice_nr_from_id (integer)
returns varchar as '
DECLARE
        p_id    alias for $1;
        v_name  varchar(50);
BEGIN
        select i.invoice_nr
        into v_name
        from im_invoices i
        where invoice_id = p_id;

        return v_name;
end;' language 'plpgsql';

