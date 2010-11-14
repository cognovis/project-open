-- /packages/intranet-earned-value-management/sql/postgresql/intranet-earned-value-management-create.sql
--
-- Copyright (c) 2010 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-earned-value-management');
select  im_menu__del_module('intranet-earned-value-management');

