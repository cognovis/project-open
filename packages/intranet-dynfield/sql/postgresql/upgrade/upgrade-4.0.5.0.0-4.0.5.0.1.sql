-- upgrade-4.0.5.0.0-4.0.5.0.1.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-4.0.5.0.0-4.0.5.0.1.sql','');

alter table im_dynfield_widgets alter column widget type text;


