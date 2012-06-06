-- /package/intranet-forum/sql/intranet-nagios-drop.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-nagios');
select  im_menu__del_module('intranet-nagios');

