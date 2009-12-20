-- upgrade-3.4.0.8.1-3.4.0.8.2.sql

SELECT acs_log__debug('/packages/intranet-notes/sql/postgresql/upgrade/upgrade-3.4.0.8.1-3.4.0.8.2.sql','');


update im_component_plugins set
	component_tcl = 'im_notes_component -object_id $project_id'
where	component_tcl = 'im_notes_project_component -object_id $project_id';


update im_component_plugins set
	component_tcl = 'im_notes_component -object_id $company_id'
where	component_tcl = 'im_notes_project_component -object_id $company_id';

update im_component_plugins set
	component_tcl = 'im_notes_component -object_id $user_id'
where	component_tcl = 'im_notes_project_component -object_id $user_id';


