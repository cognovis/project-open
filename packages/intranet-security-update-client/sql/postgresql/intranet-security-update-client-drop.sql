-- /packages/intranet-security-update-client/sql/postgres/intranet-security-update-client-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

---------------------------------------------------------
-- delete menus and plugins

select im_component_plugin__del_module('intranet-security-update-client');
select im_menu__del_module('intranet-security-update-client');

