-- upgrade-3.3.1.0.0-3.3.1.1.0.sql


create or replace function im_cost__name (integer)
returns varchar as '
DECLARE
        p_cost_id  alias for $1;        -- cost_id
        v_name  varchar;
    begin
        select  cost_name
        into    v_name
        from    im_costs
        where   cost_id = p_cost_id;

        return v_name;
end;' language 'plpgsql';


update acs_object_types set name_method = 'im_cost__name' where object_type = 'im_cost';

