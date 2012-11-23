-- upgrade-3.3.1.2.2-3.3.1.2.3.sql

SELECT acs_log__debug('/packages/intranet-reporting-cubes/sql/postgresql/upgrade/upgrade-3.3.1.2.2-3.3.1.2.3.sql','');



-- ------------------------------------------------
-- Return the final customer id for a cost item
--  

create or replace function im_cost_get_final_customer(integer)
returns varchar as '
DECLARE
        v_cost_id       alias for $1;
        v_company_id    integer;
BEGIN
	select	company_id into v_company_id
	from 	im_projects 
	where 	project_id in (
	        select  project_id
	        from    im_costs c
	        where   c.cost_id = v_cost_id
		);
        return v_company_id;
END;' language 'plpgsql';


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
