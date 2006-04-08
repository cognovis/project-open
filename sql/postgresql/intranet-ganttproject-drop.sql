-- /packages/intranet-ganttproject/sql/postgresql/intranet-ganttproject-drop.sql
--
-- Copyright (c) 2003-2006 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select im_component_plugin__del_module('intranet-ganttproject');
select im_menu__del_module('intranet-ganttproject');


