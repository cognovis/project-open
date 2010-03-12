-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');


-- Groups of projects = "program"
-- To be added to the ProjectNewPage via DynField
alter table im_projects add
program_id                      integer
                                constraint im_projects_program_id
                                references im_projects
;


SELECT im_category_new (2510, 'Program', 'Intranet Project Type');
update im_categories
set category_description = 'A group of projects with common resources or a common budget'
where category_id = 2510;


