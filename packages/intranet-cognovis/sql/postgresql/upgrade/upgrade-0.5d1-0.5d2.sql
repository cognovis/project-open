-- upgrade-0.5d1-0.5d2.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d1-0.5d2.sql','');

alter table im_projects alter column note type text;

-- Make sure we can upgrade existing notes for tasks to use richtext
update im_projects set note = '{' || note || '} text/html' where project_id in (select task_id from im_timesheet_tasks) and note not like '%text/html';


