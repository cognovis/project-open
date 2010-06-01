-- /package/intranet-sharepoint/sql/postgresql/intranet-sharepoint-drop.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-sharepoint');
select  im_menu__del_module('intranet-sharepoint');


