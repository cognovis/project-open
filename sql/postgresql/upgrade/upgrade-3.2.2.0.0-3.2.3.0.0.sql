-- /packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.2.2.0.0-3.2.2.0.0.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.2.2.0.0-3.2.3.0.0.sql','');


create or replace function im_expense__name (integer)
returns varchar as '
DECLARE
        p_expenses_id  alias for $1;    -- expense_id
        v_name  varchar(40);
begin
        select  cost_name
        into    v_name
        from    im_costs
        where   cost_id = p_expenses_id;

        return v_name;
end;' language 'plpgsql';

