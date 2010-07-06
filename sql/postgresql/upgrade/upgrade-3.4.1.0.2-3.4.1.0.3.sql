-- upgrade-3.4.1.0.2-3.4.1.0.3.sql

SELECT acs_log__debug('/packages/intranet-simple-survey/sql/postgresql/upgrade/upgrade-3.4.1.0.2-3.4.1.0.3.sql','');

update apm_parameter_values
set attr_value = 'Project Status Report'
where attr_value = 'Project Status Survey';


update apm_parameters
set default_value = 'Project Status Report'
where default_value = 'Project Status Survey';

