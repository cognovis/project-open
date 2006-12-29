-- /packages/intranet-calendar/sql/postgresql/intranet-calendar-drop.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


drop trigger im_projects_calendar_update_tr on im_projects;
drop function im_projects_calendar_update_tr();

