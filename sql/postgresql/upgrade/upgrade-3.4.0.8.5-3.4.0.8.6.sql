-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');



-- Groups of projects = "program"
-- To be added to the ProjectNewPage via DynField
alter table im_projects add
program_id                      integer
                                constraint im_projects_program_id
                                references im_projects
;


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'program_projects', 'Program Projects', 'Program Projects',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
select p.project_id, p.project_name
from im_projects p
where project_type_id = 2510
order by lower(project_name)
	}}}'
);



SELECT im_dynfield_attribute_new ('im_project', 'program_id', 'Program', 'program_projects', 'integer', 'f');

