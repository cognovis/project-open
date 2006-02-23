-- /packages/intranet-timesheet2-task-popup/sql/postgresql/intranet-timesheet2-task-popup-create.sql
--
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


---------------------------------------------------------
-- Popup Register
--
-- Registers popup entries, suitable for adding time to the
-- im_hours table
--

create sequence im_timesheet_popup_seq start 1;
create table im_timesheet_popups (
	popup_id		integer
				constraint im_timesheet_popup_pk 
				primary key,
	user_id			integer
				constraint im_timesheet_popup_user_fk
				references parties,
	task_id			integer
				constraint im_timesheet_popups_task_fk
				references im_timesheet_tasks,
	log_time		timestamptz,
	log_duration		interval,
	note			varchar(400)
);
create unique index im_timesheet_popups_time_idx 
on im_timesheet_popups  (log_time);
create unique index im_timesheet_popups_user_idx 
on im_timesheet_popups  (user_id);

