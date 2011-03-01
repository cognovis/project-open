-- /packages/intranet-bug-tracker/sql/postgresql/intranet-bug-tracker-drop.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


alter table im_timesheet_tasks drop column bt_bug_id;


select im_menu__del_module('intranet-bug-tracker');
select im_component_plugin__del_module('intranet-bug-tracker');
