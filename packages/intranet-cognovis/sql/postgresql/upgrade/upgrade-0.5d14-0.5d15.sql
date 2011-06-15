-- 
-- packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d14-0.5d15.sql
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
-- @creation-date 2011-06-07
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d14-0.5d15.sql','');

-- create dynfield attributes of object_type im_project
-- ticket_name
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_attribute_id	integer;
BEGIN

	
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''project_name'');

	UPDATE acs_attributes SET min_n_values = 1 WHERE object_type = ''im_ticket'' AND attribute_name = ''project_name'';

	UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;
	
	UPDATE im_dynfield_layout SET pos_y = 0 WHERE attribute_id = v_attribute_id;
		
	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- project_nr
SELECT im_dynfield_attribute_new (
       'im_ticket',		        -- object_type
       'project_nr',			-- column_name
       '#intranet-helpdesk.Ticket_Nr#',	-- pretty_name
       'textbox_medium',	 	-- widget_name
       'string',			-- acs_datatype
       't',				-- required_p   
       1,				-- pos y
       'f',				-- also_hard_coded
       'im_projects'			-- table_name
);


-- parent_id/ticket_sla_id
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_attribute_id	integer;
BEGIN

	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''parent_id'');

	
	UPDATE im_dynfield_attributes SET also_hard_coded_p = ''f'' WHERE attribute_id = v_attribute_id;

	UPDATE im_dynfield_layout SET pos_y = 2 WHERE attribute_id = v_attribute_id;
	
	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- ticket_customer_contact_id
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_attribute_id	integer;
BEGIN

	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_customer_contact_id'');

	
	UPDATE im_dynfield_layout SET pos_y = 3 WHERE attribute_id = v_attribute_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



-- ticket_type_id
SELECT im_dynfield_widget__new (
       null,
      'im_dynfield_widget', 
       now(),
       null,
       null,
       null,
       'ticket_type',
       'Ticket Type',
       'Ticket Types',
       10007,
       'integer',
       'im_category_tree',
       'integer',
       '{custom {category_type "Intranet Ticket Type"}}',
       'im_name_from_id'
 );


SELECT im_dynfield_attribute_new (
       'im_ticket',				-- object_type
       'ticket_type_id',			-- column_name
       '#intranet-helpdesk.Ticket_Type#',	-- pretty_name
       'ticket_type',				-- widget_name
       'integer',				-- acs_datatype
       't',					-- required_p   
       4,					-- pos y
       'f',					-- also_hard_coded
       'im_tickets'				-- table_name
);



-- ticket_status_id
SELECT im_dynfield_widget__new (
       null,
       'im_dynfield_widget', 
       now(), 
       null,
       null, 
       null, 
       'ticket_status',
       'Ticket Status',
       'Ticket Status',
       10007,
       'integer',
       'im_category_tree',
       'integer',
       '{custom {category_type "Intranet Ticket Status"}}',
       'im_name_from_id'
       );


SELECT im_dynfield_attribute_new (
       'im_ticket',				-- object_type
       'ticket_status_id',			-- column_name
       '#intranet-helpdesk.Ticket_Status#',	-- pretty_name
       'ticket_status',				-- widget_name
       'integer',				-- acs_datatype
       't',					-- required_p
       5,					-- pos y
       'f',					-- also_hard_coded
       'im_tickets'				-- table_name
);




-- Ticket Info Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Ticket Info Component',
       'intranet-helpdesk',
       'left', 
       '/intranet-cognovis/tickets/view', 
       null,
       1,
       'im_ticket_info_cognovis_component $ticket_id $return_url');
