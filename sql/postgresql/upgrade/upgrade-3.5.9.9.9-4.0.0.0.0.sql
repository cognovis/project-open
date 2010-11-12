-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');


alter table apm_package_types
add column inherit_templates_p char(1);

alter table apm_package_types
add column implements_subsite_p char(1);


