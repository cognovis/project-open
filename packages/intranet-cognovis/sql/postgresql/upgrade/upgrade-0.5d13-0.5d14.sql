SELECT acs_log__debug(' /packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d13-0.5d14.sql','');

create or replace FUNCTION inline_0 ()
returns integer as '
DECLARE
	v_widget_id integer;

BEGIN
	SELECT widget_id INTO v_widget_id FROM im_dynfield_widgets where widget_name = ''open_projects'';
	
	UPDATE im_dynfield_widgets 
	SET parameters = ''{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -exclude_tasks_p 1} switch_p 1}}'', widget = ''generic_tcl'' WHERE widget_id = v_widget_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

update acs_attributes set datatype='date' where attribute_name = 'end_date';
update acs_attributes set datatype='date' where attribute_name = 'start_date';

