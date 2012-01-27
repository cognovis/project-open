-- upgrade-0.5d8-0.5d9.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d8-0.5d9.sql','');

-- Disable Project Translation Wizard Component
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 

	v_plugin_id	integer;
BEGIN
	SELECT plugin_id INTO v_plugin_id FROM im_component_plugins WHERE plugin_name = ''Project Translation Wizard'' AND page_url = ''/intranet/projects/view'';

	SELECT im_component_plugin__delete(v_plugin_id);

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();