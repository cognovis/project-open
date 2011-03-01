-- /packages/intranet-big-brother/sql/oracle/intranet-big-brother-create.sql
--
-- Sets up an interface to the Big Brother System Monitoring system
-- @author Frank Bergmann (frank.bergmann@project-open.com)


---------------------------------------------------------
-- delete potentially existing menus and plugins
BEGIN
    im_component_plugin.del_module(module_name => 'intranet-big-brother');
    im_menu.del_module(module_name => 'intranet-big-brother');
END;
/
commit;
