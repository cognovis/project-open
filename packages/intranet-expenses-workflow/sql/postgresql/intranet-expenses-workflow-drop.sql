-- /package/intranet-expenses-workflow/sql/intranet-expenses-workflow-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------
-- Drop menus and components defined by the module

select im_menu__del_module('intranet-expenses-workflow');
select im_component_plugin__del_module('intranet-expenses-workflow');

