-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-material/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');

alter table im_materials alter column material_name type text;
alter table im_materials alter column material_nr type text;
alter table im_materials alter column description type text;

