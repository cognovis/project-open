-- upgrade-0.2d-0.3d.sql

SELECT acs_log__debug('packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.2d-0.3d.sql','');

-- update project_parent_options widget
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_widget_id integer;
BEGIN

	SELECT widget_id INTO v_widget_id FROM im_dynfield_widgets where widget_name = ''project_parent_options'';

	UPDATE im_dynfield_widgets SET parameters = ''{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -exclude_tasks_p 1 -project_id $super_project_id} switch_p 1 global_var super_project_id}}'' WHERE widget_id = v_widget_id;

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



-- update open_projects widget
create or replace FUNCTION inline_0 ()
returns integer as '
DECLARE
	v_widget_id integer;

BEGIN
	SELECT widget_id INTO v_widget_id FROM im_dynfield_widgets where widget_name = ''open_projects'';

	UPDATE im_dynfield_widgets SET parameters = ''{custom {tcl {im_project_options -include_empty 1 -project_status_id [im_project_status_open] -exclude_tasks_p 1} switch_p 1}}'', widget = ''generic_tcl'' WHERE widget_id = v_widget_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();