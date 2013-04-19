-- upgrade-4.0.3.5.1-4.0.3.5.2.sql

SELECT acs_log__debug('/packages/intranet-sysconfig/sql/postgresql/upgrade/upgrade-4.0.3.5.1-4.0.3.5.2.sql','');


-- Disable the old help page
update im_component_plugins
set enabled_p = 'f'
where plugin_name = 'Home Page Help Blurb';


