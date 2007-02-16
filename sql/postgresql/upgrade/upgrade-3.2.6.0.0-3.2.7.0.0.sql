-- upgrade-3.2.6.0.0-3.2.7.0.0.sql

SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Gantt Resource Assignations',      -- plugin_name
        'intranet-ganttproject',               -- package_name
        'bottom',                        -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        10,                            -- sort_order
	'im_ganttproject_resource_cube -project_id $project_id -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_Resource_Assignations "Project Gantt Resource Assignations"'
);

