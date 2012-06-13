-- /packages/intranet-reporting-openoffice/sql/postgresql/intranet-reporting-openoffice-create.sql
--
-- Copyright (c) 2003-2011 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


---------------------------------------------------------------------
-- Returns a komma separated list of all areas included in a program
--
create or replace function im_reporting_oo_program_area_list(integer)
returns varchar as $body$
DECLARE
	p_program_id		alias for $1;
	v_result		varchar;
	row			RECORD;
BEGIN
	v_result := '';

	FOR row IN 
		select	im_category_from_id(p.project_type_id) as area
		from	im_projects p
		where	p.program_id = p_program_id
	LOOP
		IF v_result != '' THEN v_result := v_result || ', '; END IF;
		v_result := v_result || row.area;
	END LOOP;

        return v_result;
end;$body$ language 'plpgsql';



---------------------------------------------------------------------
-- Returns the 
--
create or replace function im_reporting_oo_project_cost(integer, timestamptz, timestamptz, integer[])
returns varchar as $body$
DECLARE
	-- The main project for which to calculate the financial situation
	p_project_id		alias for $1;

	p_start_date		alias for $2;
	p_end_date		alias for $3;

	-- The list of cost types to consider
	p_cost_type_ids	    	alias for $4;

	v_result		numeric(12,3);
	row			RECORD;
BEGIN
	v_result := 0.0;

	FOR row IN
		select	CASE WHEN c.cost_type_id in (3700, 3702) THEN c.amount ELSE -1.0 * c.amount END as amount
		from	im_costs c, 
			im_projects p, 
			im_projects main_p
		where	main_p.parent_id is null and 
			main_p.company_id = cust.company_id and 
			main_p.tipo_de_proyecto = c.category_id and
			main_p.area_id = :report_area_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
			c.project_id = p.project_id and 
			c.cost_type_id in () and
			c.effective_date <= p_end_date and
			c.effective_date >= p_start_date and


	LOOP
		IF v_result != '' THEN v_result := v_result || ', '; END IF;
		v_result := v_result || row.area;
	END LOOP;

        return v_result;
end;$body$ language 'plpgsql';

