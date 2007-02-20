-- /packages/intranet-ganttproject/sql/postgresql/intranet-ganttproject-create.sql
--
-- Copyright (c) 2003-2006 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


---------------------------------------------------------
-- Setup a GanttProject component for 
-- /intranet/projects/view page
--

alter table im_biz_object_members
add percentage numeric(8,2);


-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

-- select im_component_plugin__del_module('intranet-ganttproject');
-- select im_menu__del_module('intranet-ganttproject');


-- Show the ganttproject component in project page
--
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project GanttProject Component',      -- plugin_name
        'intranet-ganttproject',               -- package_name
        'right',                        -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        10,                            -- sort_order
	'im_ganttproject_component -project_id $project_id -current_page_url $current_url -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Scheduling "Scheduling"'
);



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
	'im_ganttproject_resource_component -project_id $project_id -level_of_detail 2 -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_Resource_Assignations "Project Gantt Resource Assignations"'
);




SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Gantt View',		-- plugin_name
        'intranet-ganttproject',	-- package_name
        'bottom',			-- location
        '/intranet/projects/view',	-- page_url
        null,                           -- view_name
        50,                             -- sort_order
	'im_ganttproject_gantt_component -project_id $project_id -level_of_detail 2 -return_url $return_url -export_var_list [list project_id]',
	'lang::message::lookup "" intranet-ganttproject.Project_Gantt_View "Project Gantt View"'
);

