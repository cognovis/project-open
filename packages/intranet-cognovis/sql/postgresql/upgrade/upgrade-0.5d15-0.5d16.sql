-- 
-- packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d15-0.5d16.sql
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
-- @creation-date 2011-06-15
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d15-0.5d16.sql','');

-- Update sort order (pos_y) and datatype 
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
        v_attribute_id integer;
BEGIN

       -- ticket_prio_id
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_prio_id'');

       UPDATE im_dynfield_layout SET pos_y = 7 WHERE attribute_id = v_attribute_id;


       -- ticket_assignee_id   
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_assignee_id'');

       UPDATE im_dynfield_layout SET pos_y = 8 WHERE attribute_id = v_attribute_id;



       -- ticket_note
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_note'');

       UPDATE im_dynfield_layout SET pos_y = 9 WHERE attribute_id = v_attribute_id;


       -- ticket_component_id
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_component_id'');

       UPDATE im_dynfield_layout SET pos_y = 10 WHERE attribute_id = v_attribute_id;


       -- ticket_conf_item_id
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_conf_item_id'');

       UPDATE im_dynfield_layout SET pos_y = 11 WHERE attribute_id = v_attribute_id;


       -- ticket_description
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_description'');

       UPDATE im_dynfield_layout SET pos_y = 12 WHERE attribute_id = v_attribute_id;


       -- ticket_customer_deadline
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_customer_deadline'');

       UPDATE im_dynfield_layout SET pos_y = 13 WHERE attribute_id = v_attribute_id;


       -- ticket_quote_comment
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_quote_comment'');

       UPDATE im_dynfield_layout SET pos_y = 14 WHERE attribute_id = v_attribute_id;


       -- ticket_telephony_request_type_id
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_telephony_request_type_id'');

       UPDATE im_dynfield_layout SET pos_y = 15 WHERE attribute_id = v_attribute_id;

       -- ticket_telephony_old_number
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_telephony_old_number'');

       UPDATE im_dynfield_layout SET pos_y = 16 WHERE attribute_id = v_attribute_id;


       -- ticket_telephony_new_number
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_telephony_new_number'');

       UPDATE im_dynfield_layout SET pos_y = 17 WHERE attribute_id = v_attribute_id;


       -- ticket_quote_days
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_quoted_days'');

       UPDATE im_dynfield_layout SET pos_y = 18 WHERE attribute_id = v_attribute_id;
       UPDATE acs_attributes SET datatype = ''float'' where attribute_name = ''ticket_quoted_days'' and object_type = ''im_ticket'';

       -- ticket_dept_id
       SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = (SELECT attribute_id FROM acs_attributes WHERE object_type = ''im_ticket'' AND attribute_name = ''ticket_dept_id'');

       UPDATE im_dynfield_layout SET pos_y = 19 WHERE attribute_id = v_attribute_id;


       RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();