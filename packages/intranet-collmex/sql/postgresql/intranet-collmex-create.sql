-- 
-- packages/intranet-collmex/sql/postgresql/intranet-collmex-create.sql
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
-- @author <yourname> (<your email>)
-- @creation-date 2012-01-06
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-collmex/sql/postgresql/intranet-collmex-create.sql','');

alter table im_companies add column collmex_id integer;
update im_offices set address_country_code = 'de' where address_country_code is null

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN

	v_attribute_id := im_dynfield_attribute_new (''im_company'', ''collmex_id'', ''Collmex ID'', ''integer'', ''integer'', ''f'');

	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Company Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''display'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''display'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;

END;' language 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();

alter table im_payments add column collmex_id varchar(20);

