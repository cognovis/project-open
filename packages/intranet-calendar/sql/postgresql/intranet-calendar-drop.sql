-- /packages/intranet-calendar/sql/postgresql/intranet-calendar-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



-----------------------------------------------------
-- Drop menus and components defined by the module

select im_menu__del_module('intranet-calendar');
select im_component_plugin__del_module('intranet-calendar');



drop trigger im_projects_calendar_update_tr on im_projects;
drop trigger im_trans_tasks_calendar_update_tr on im_trans_tasks;
drop trigger im_forum_topics_calendar_update_tr on im_forum_topics;


drop function im_projects_calendar_update_tr();
drop function im_trans_tasks_calendar_update_tr();
drop function im_forum_topics_calendar_update_tr();

