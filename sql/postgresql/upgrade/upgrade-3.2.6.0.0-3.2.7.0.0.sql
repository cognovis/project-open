-- upgrade-3.2.6.0.0-3.2.7.0.0.sql

update im_component_plugins
set component_tcl = 'im_employee_info_component $user_id_from_search $return_url [im_opt_val employee_view_name]'
where plugin_name = 'User Employee Component';
