--upgrade-0.1d-0.2d1

SELECT acs_log__debug('/packages/intranet-cust-berendsen/sql/postgresql/upgrade/upgrade-0.1d-0.2d1.sql','');


-- Project Base Data Component                                                                                                                              
SELECT im_component_plugin__new (
       null, 
       'acs_object', 
       now(), 
       null, 
       null, 
       null, 
       'Project Base Data Berendsen', 
       'intranet-cust-berendsen', 
       'left', 
       '/intranet/projects/view', 
       null, 
       10, 
       'im_project_base_data_berendsen_component -project_id $project_id -return_url $return_url'
);

update im_component_plugins set enabled_p = 'f' where plugin_name = 'Project Base Data';
update im_component_plugins set enabled_p = 'f' where plugin_name = 'Project Base Data Cognovis';
update im_component_plugins set sort_order = 5 where plugin_name = 'Project Hierarchy';
	
-- Enable the component for the correct users

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Project Base Data Berendsen' and package_name = 'intranet-cust-berendsen'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);