-- upgrade-4.0.3.0.1-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');

alter table im_timesheet_conf_objects add column comment text;