-- /packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d9-0.5d10.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d9-0.5d10.sql','');



CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
BEGIN

	UPDATE im_component_plugins SET package_name = ''intranet-cognovis'' WHERE package_name = ''intranet-core'' AND page_url = ''intranet-cognovis/tasks/view'' AND plugin_name = ''Timesheet Task Info Component'';

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();