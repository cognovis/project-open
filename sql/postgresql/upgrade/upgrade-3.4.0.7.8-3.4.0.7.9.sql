--upgrade-3.4.0.7.8-3.4.0.7.9.sql

SELECT acs_log__debug('/packages/intranet-calendar/sql/postgresql/upgrade/upgrade-3.4.0.7.8-3.4.0.7.9.sql','');


-- SourceForge #1798720
--
-- Eliminate a constraint on the calendar name
-- and replace by constraint on owner + calendar name
drop index calendars_un_idx;
alter table calendars add constraint calendars_name_user_un UNIQUE (owner_id, calendar_name);


