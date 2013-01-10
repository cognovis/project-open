-- upgrade-4.0.3.2.1-4.0.3.2.2.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.2.1-4.0.3.2.2.sql','');



select im_component_plugin__new (
	null,						-- plugin_id
	'im_component_plugin',				-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creattion_ip
	null,						-- context_id

	'Home Timesheet Tasks',				-- plugin_name
	'intranet-timesheet2-tasks',			-- package_name
	'right',					-- location
	'/intranet/index',				-- page_url
	null,						-- view_name
	0,						-- sort_order
	'im_timesheet_task_list_component -max_entries_per_page 20 -view_name im_timesheet_task_list_short -restrict_to_mine_p mine -restrict_to_status_id [im_project_status_open]'
);

