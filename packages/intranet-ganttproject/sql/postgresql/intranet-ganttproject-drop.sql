-- /packages/intranet-ganttproject/sql/postgresql/intranet-ganttproject-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select im_component_plugin__del_module('intranet-ganttproject');
select im_menu__del_module('intranet-ganttproject');


alter table im_biz_object_members DROP column percentage;
