-- upgrade-4.0.3.0.3-4.0.3.0.4.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');





----------------------------------------------------------------
-- Show MS-Project warnings in project page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'MS-Project Warning Component',	-- plugin_name
	'intranet-ganttproject',	-- package_name
	'top',					-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_ganttproject_ms_project_warning_component -project_id $project_id',
	'lang::message::lookup "" intranet-ganttproject.MS_Project_Warnings "MS-Project Warnings"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'MS-Project Warning Component'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


