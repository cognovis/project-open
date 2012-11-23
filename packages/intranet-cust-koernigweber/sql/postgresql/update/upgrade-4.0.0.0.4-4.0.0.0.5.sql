-- upgrade-4.0.0.0.4-4.0.0.0.5.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.0.0.4-4.0.0.0.5.sql','');

SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'im_component_plugin',          -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Profitibility',      	-- plugin_name
        'intranet-cust-koernigweber',   -- package_name
        'right',                        -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        15,                             -- sort_order
        'im_project_profitibility_component_weber -user_id $user_id -project_id $project_id -view_name $view_name'  --component_tcl
);

update 	im_component_plugins 
set 	title_tcl = 'lang::message::lookup "" intranet-cust-koernigweber.TitleComponentProjectProfitibility "Project Profitibility"' 
where 	plugin_name = 'Project Profitibility';

select im_grant_permission(
		(select plugin_id from im_component_plugins where plugin_name = 'Project Profitibility'), 
		(select group_id from groups where group_name='P/O Admins'), 
		'read'
);

select im_grant_permission(
		(select plugin_id from im_component_plugins where plugin_name = 'Project Profitibility'), 
		(select group_id from groups where group_name='Senior Managers'), 
		'read'
);

select im_grant_permission(
		(select plugin_id from im_component_plugins where plugin_name = 'Project Profitibility'), 
		(select group_id from groups where group_name='Employees'), 
		'read'
);

select im_grant_permission(
		(select plugin_id from im_component_plugins where plugin_name = 'Project Profitibility'), 
		(select group_id from groups where group_name='Technical Office'), 
		'read'
);
