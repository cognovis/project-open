-- upgrade-0.3d-0.4d.sql
SELECT acs_log__debug('packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.3d-0.4d.sql','');

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	row	record;
BEGIN
	FOR row IN
		SELECT plugin_id FROM im_component_plugins 
		WHERE page_url = ''/intranet-timesheet2-tasks/view'' OR page_url = ''/intranet-cognovis/tasks/view''
	LOOP
		PERFORM im_component_plugin__delete(row.plugin_id);
	END LOOP;


	RETURN 0;
END;' language 'plpgsql';
select inline_0 ();
DROP FUNCTION inline_0 ();

-- Right Side Components

-- Timesheet Task Members Component
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Task Members Cognovis', 'intranet-core', 'right', '/intranet-timesheet2-tasks/view', null, 20, 'im_group_member_component $task_id $current_user_id $project_write $return_url "" "" 1');

-- Project Timesheet Tasks Information
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Timesheet Task Project Information Cognovis', 'intranet-timesheet2-tasks', 'right', '/intranet-timesheet2-tasks/view', null, '50', 'im_timesheet_task_info_component $project_id $task_id $return_url');


-- Timesheet Task Resources
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Task Resources Cognovis', 'intranet-timesheet2-tasks', 'right', '/intranet-timesheet2-tasks/view', null, '50', 'im_timesheet_task_members_component $project_id $task_id $return_url');

-- Timsesheet Task Forum


-- Timesheet Tasks Forum Component 
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Timesheet Task Forum',-- plugin_name
        'intranet-forum',               -- package_name
        'right',                        -- location
        '/intranet-timesheet2-tasks/view', -- page_url
        null,                           -- view_name
        10,                             -- sort_order
	'im_forum_component -user_id $user_id -forum_object_id $task_id -current_page_url $return_url -return_url $return_url -forum_type "task" -export_var_list [list task_id forum_start_idx forum_order_by forum_how_many forum_view_name] -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -start_idx [im_opt_val forum_start_idx] -restrict_to_mine_p "f" -restrict_to_new_topics 0',
	'im_forum_create_bar "<B><nobr>[_ intranet-forum.Forum_Items]</nobr></B>" $task_id $return_url');
	




-- Left Side Components

-- Timesheet Task Info Component 
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Timesheet Task Info Component', 'intranet-cognovis', 'left', '/intranet-timesheet2-tasks/view', null, 1, 'im_timesheet_task_info_cognovis_component $task_id $return_url');
