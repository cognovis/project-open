-- 
-- packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-03-02
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-4.0.3.3.0-4.0.3.3.1.sql','');

-- Move Employee Start and End date into an im_employee dynfield

-- start_date
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''person'' AND attribute_name = ''start_date'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''date'',		-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       10,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  alter table im_employees add column start_date date;
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''person'',			-- object_type
		 ''start_date'',				-- column_name
		 ''#intranet-hr.Start_Date#'',	-- pretty_name
		 ''date'',		-- widget_name
		 ''date'',				-- acs_datatype
		 ''f'',					-- required_p   
		 10,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_employees''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_type = ''Intranet User Type''
	LOOP
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''Start date of the employee in the company'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;

	RETURN 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- end_date
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''person'' AND attribute_name = ''end_date'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''date'',		-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       11,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  alter table im_employees add column end_date date;
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''person'',			-- object_type
		 ''end_date'',				-- column_name
		 ''#intranet-hr.Termination_Date#'',	-- pretty_name
		 ''date'',		-- widget_name
		 ''date'',				-- acs_datatype
		 ''f'',					-- required_p   
		 11,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_employees''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_type = ''Intranet User Type''
	LOOP
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''End date of the employee in the company'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;

	RETURN 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- Update the start date for the employees.

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN
	FOR row IN 
		SELECT cause_object_id,start_date,end_date FROM im_costs, im_repeating_costs where cost_id = rep_cost_id
	LOOP
                update im_employees set start_date = row.start_date, end_date = row.end_date where employee_id = row.cause_object_id;
	END LOOP;

	RETURN 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
