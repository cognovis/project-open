
select im_component_plugin__del_module('intranet-timesheet2-tasks-info');
select im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creattion_ip
	null,					-- context_id

	'Project Timesheet Tasks Information',	-- plugin_name
	'intranet-timesheet2-tasks-info',	-- package_name
	'right',				-- location
	'/intranet-timesheet2-tasks/new',		-- page_url
	null,					-- view_name
	50,					-- sort_order
	'im_timesheet_task_info_component $project_id $task_id $return_url'
);


select im_component_plugin__del_module('intranet-timesheet2-tasks-resources');
select im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creattion_ip
	null,					-- context_id

	'Task Resources',			-- plugin_name
	'intranet-timesheet2-tasks-resources',	-- package_name
	'right',				-- location
	'/intranet-timesheet2-tasks/new',		-- page_url
	null,					-- view_name
	50,					-- sort_order
	'im_timesheet_task_members_component $project_id $task_id $return_url'
);

