-- 
-- 
-- 
-- @author <yourname> (<your email>)
-- @creation-date 2011-09-22
-- @cvs-id $Id$
--


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id		integer;
BEGIN
	-- source_language_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''source_language_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);
	
	-- bt_fix_for_version_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''bt_fix_for_version_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- bt_found_in_version_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''bt_found_in_version_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- bt_project_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''bt_project_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- confirm_date
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''confirm_date'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- milestone_p
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''milestone_p'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);
	
	-- presales_probability
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''presales_probability'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- presales_value
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''presales_value'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- program_id
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''program_id'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);

	-- release_item_p
	SELECT attribute_id INTO v_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''release_item_p'';
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = v_attribute_id;
	PERFORM im_dynfield_attribute__del (v_attribute_id);


	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

