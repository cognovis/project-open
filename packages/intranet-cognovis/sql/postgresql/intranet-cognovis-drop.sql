-- intranet-cognovis-drop.sql

-- Drop component plugins

SELECT im_component_plugin__del_module('intranet-cognovis');


CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
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




-- Delete "im_project" Dynfield Attributes. Only the ones we created new
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE 
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''parent_id'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''project_lead_id'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''project_status_id'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''end_date'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''on_track_status_id'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''percent_completed'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''project_budget_hours'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_acs_attribute_id 
	FROM acs_attributes
	WHERE object_type = ''im_project''
	AND attribute_name = ''project_budget_currency'';

	SELECT attribute_id INTO v_attribute_id
	FROM im_dynfield_attributes
	WHERE acs_attribute_id = v_acs_attribute_id;

	PERFORM im_dynfield_attribute__del(v_attribute_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



-- Deactivate Original Component: Project Base Data and Project Hierarchy
-- it needs to add a flush memory in the end of this function

create or replace function inline_0 () 
returns integer as '
DECLARE 
	v_plugin_id integer;

BEGIN
	SELECT plugin_id into v_plugin_id
	FROM im_component_plugins
	WHERE plugin_name = ''Project Base Data'' 
	AND package_name = ''intranet-core'' 
	AND page_url = ''/intranet/projects/view'';

	UPDATE im_component_plugins 
	SET enabled_p = ''t'' 
	WHERE plugin_id = v_plugin_id;

	return 0;
end;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();	







---------------------------------------
-- Remove Task Components
---------------------------------------

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Task Members Cognovis'' AND package_name = ''intranet-core'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Project Information Cognovis'' AND package_name = ''intranet-timesheet2-tasks'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Task Resources Cognovis'' AND package_name = ''intranet-timesheet2-tasks'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Forum'' AND package_name = ''intranet-forum'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Info Component'' AND package_name = ''intranet-cogonovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


---------------------------------------
-- Remove User Components
---------------------------------------

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''User Basic Information'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/users/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''User Contact Information'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/users/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''User Skin Information'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/users/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''User Admin Information'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/users/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''User Locale'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/users/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''User Portrait'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/users/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


---------------------------------------
-- Remove Company Components
---------------------------------------

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Company Information'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Company Projects'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Company Employees'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	v_plugin_id	integer;
BEGIN

	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Company Contacts'' AND package_name = ''intranet-core'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_component_plugin__delete (v_plugin_id);

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


-- Remove view and view_columns
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

BEGIN
	DELETE FROM im_view_columns WHERE view_id = 950;
	DELETE FROM im_views WHERE view_id = 950;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();






-- Remove Dynfield Attributes im_timesheet_task

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''cost_center_id'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''cost_center_id'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''planned_units'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''billable_units'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''percent_completed'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''start_date'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''end_date'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();




CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
BEGIN
      SELECT ida.attribute_id INTO v_attribute_id 
      FROM acs_attributes aa, im_dynfield_attributes ida 
      WHERE ida.acs_attribute_id = aa.attribute_id 
      AND aa.object_type = ''im_timesheet_task'' 
      AND aa.attribute_name = ''description'';

      PERFORM im_dynfield_attribute__del(v_attribute_id);

      RETURN 0;


END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



-- Disable components
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_plugin_id	integer;
	row		record;

BEGIN
    -- Disable the project wiki component (for projects)

    SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/projects/view'' AND plugin_name = ''Project Wiki Component'';

    UPDATE im_component_plugins SET enabled_p = ''t'' WHERE plugin_id = v_plugin_id

    -- Disable the project conf component (for projects)

    SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/projects/view'' AND plugin_name = ''Project Configuration Items'';

    UPDATE im_component_plugins SET enabled_p = ''t'' WHERE plugin_id = v_plugin_id

    -- Disable the ]project-open[ news component from the home screen.
    FOR row IN 
        SELECT plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/index'' AND plugin_name = ''Home &#93;po&#91; News''
    LOOP
        UPDATE im_component_plugins SET enabled_p = ''t'' WHERE plugin_id = row.plugin_id;
    END LOOP;

    -- Disable the intranet-filestorage components
    FOR row IN
        SELECT plugin_id FROM im_component_plugins WHERE package_name = ''intranet-filestorage''
    LOOP
        UPDATE im_component_plugins SET enabled_p = ''t'' WHERE plugin_id = row.plugin_id;
    END LOOP;

    -- Disable the project note component.

    SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE page_url = ''/intranet/projects/view'' AND plugin_name = ''Project Notes'';

    UPDATE im_component_plugins SET enabled_p = ''t'' WHERE plugin_id = v_plugin_id

    -- Disable the Translation Workflow Rating Survey (it is one of two surveys for each project)
    SELECT survey_id INTO v_plugin_id FROM survsimp_surveys WHERE name = ''Translation Workflow Rating: Translator'' AND short_name = ''Translation Workflow'';
    UPDATE survsimp_surveys SET enabled_p = ''f'' WHERE survey_id = v_plugin_id;

    
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();
