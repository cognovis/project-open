-- upgrade-3.2.7.0.0-3.2.8.0.0.sql


update im_component_plugins
set title_tcl = 'lang::message::lookup "" intranet-timesheet2.Timesheet "Timesheet"'
where plugin_name = 'Project Timesheet Component';
