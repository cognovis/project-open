-- intranet-cognovis-drop.sql

-- Drop component plugins

SELECT im_component_plugin__del_module('intranet-cognovis');


CREATE OR REPLACE FUNCTION inline_0 () 
RETURN integer AS '
DECLARE 
	v_widget_id	integer;
BEGIN
	SELECT widget_id INTO v_widget_id 
	FROM im_dynfield_widgets
	WHERE widget_name = ''project_nr'';

	PERFORM im_dynfield_widget__del(v_widget_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();




-- Delete "im_project" Dynfield Attributes


CREATE OR REPLACE FUNCTION inline_0 () 
RETURN integer AS '
DECLARE 
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project'';
	AND attribute_name = ''project_name''

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();




CREATE OR REPLACE FUNCTION inline_0 () 
RETURN integer AS '
DECLARE 
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project'';
	AND attribute_name = ''project_nr''

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();




CREATE OR REPLACE FUNCTION inline_0 () 
RETURN integer AS '
DECLARE 
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project'';
	AND attribute_name = ''parent_id''

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();
