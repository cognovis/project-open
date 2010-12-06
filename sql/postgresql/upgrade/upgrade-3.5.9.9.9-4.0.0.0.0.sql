-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');

-- -----------------------------------------------------
-- Remove the duplicated Gantt Resources portlet
-- -----------------------------------------------------

select im_component_plugin__delete(
	(select plugin_id from im_component_plugins where plugin_name = 'Project Gantt Resource Assignations')
);

