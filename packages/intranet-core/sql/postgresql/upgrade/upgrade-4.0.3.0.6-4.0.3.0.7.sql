-- 
-- packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.6-4.0.3.0.7.sql
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
-- @creation-date 2012-04-07
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.6-4.0.3.0.7.sql','');

SELECT im_dynfield_widget__new (
                null,                   -- widget_id
                'im_dynfield_widget',   -- object_type
                now(),                  -- creation_date
                null,                   -- creation_user
                null,                   -- creation_ip
                null,                   -- context_id
                'tax_classification',              -- widget_name
                '#intranet-core.VAT#',      -- pretty_name
                '#intranet-core.VAT#',      -- pretty_plural
                10007,                  -- storage_type_id
                'integer',              -- acs_datatype
                'im_category_tree',             -- widget
                'integer',              -- sql_datatype
                '{custom {category_type "Intranet VAT Type"}}', 
                'im_name_from_id'
);

-- tax classification
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN

	 alter table im_companies add column tax_classification integer;
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_company'',			-- object_type
		 ''tax_classification'',			-- column_name
		 ''#intranet-core.Tax_classification#'',	-- pretty_name
		 ''tax_classification'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 90,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_companies''			-- table_name
	  );

	  

	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_type = ''Intranet Company Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''Choose the appropriate Tax Classification'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

