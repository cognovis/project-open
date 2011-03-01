-- /packages/intranet-big-brother/sql/oracle/intranet-big-brother-create.sql
--
-- Sets up an interface to the Big Brother System Monitoring system
-- @author Frank Bergmann (frank.bergmann@project-open.com)


---------------------------------------------------------
-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...
BEGIN
    im_component_plugin.del_module(module_name => 'intranet-big-brother');
    im_menu.del_module(module_name => 'intranet-big-brother');
END;
/
show errors

commit;


---------------------------------------------------------
-- Register the component:
--	- at the P/O homepage ('/intranet/index')
-- 	- at the left page column ('left')
--	- at the beginning of the left column ('10')
--
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the big-brother to the very end.
    --
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Home Big Brother Component',
	package_name =>	'intranet-big-brother',
        page_url =>     '/intranet/index',
        location =>     'right',
        sort_order =>   60,
        component_tcl => 'im_big_brother_component $user_id'
    );
end;
/
show errors
commit;
