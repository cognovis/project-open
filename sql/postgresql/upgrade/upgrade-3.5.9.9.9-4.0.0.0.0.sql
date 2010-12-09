-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-release-mgmt/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');


-- Task Board component
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Task Board',			-- plugin_name
	'intranet-release-mgmt',	-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order - top one of the "bottom" portlets
	'im_release_mgmt_task_board_component -project_id $project_id',
	'lang::message::lookup "" intranet-release-mgmt.Task_Board "Task Board"'
);


SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Task Board' and package_name = 'intranet-release-mgmt'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
