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

