-- /packages/intranet-resource-management/sql/postgresql/intranet-resource-management-drop.sql
--
-- Copyright (c) 2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select im_component_plugin__del_module('intranet-resource-management');
select im_menu__del_module('intranet-resource-management');

