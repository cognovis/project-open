-- upgrade-3.4.0.2.1-3.4.0.5.0.sql

-- ------------------------------------------------
-- Return the final customer name for a cost item
--

create or replace function im_cost_get_final_customer_name(integer)
returns varchar as '
DECLARE
        v_cost_id       alias for $1;
        v_company_name  varchar;
BEGIN
	select	company_name into v_company_name
	from 	im_companies
	where 	company_id in ( 
	        select  company_id
	        from    im_projects
	        where   project_id in (
        	        select  project_id
                	from    im_costs c
	                where   c.cost_id = v_cost_id
        	        )
		);
        return v_company_name;
END;' language 'plpgsql';

