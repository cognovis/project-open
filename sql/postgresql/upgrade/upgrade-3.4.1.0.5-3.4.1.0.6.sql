-- upgrade-3.4.1.0.5-3.4.1.0.6.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.4.1.0.5-3.4.1.0.6.sql','');

-- -----------------------------------------------------
-- Fix length of the im_gantt_projects field
-- -----------------------------------------------------

alter table im_gantt_projects
alter column xml_elements type text;


