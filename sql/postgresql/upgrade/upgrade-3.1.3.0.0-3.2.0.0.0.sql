
-------------------------------------------------------------
-- Updates to upgrade to the "unified" V3.2 model where
-- Task is a subclass of Project.
-------------------------------------------------------------

-- Drop the generic uniquentess constraint on project_nr.
alter table im_projects drop constraint im_projects_nr_un;

-- Create a new constraing that makes sure that the project_nr
-- are unique per parent-project.
-- Project with parent_id != null don't have a filestorage...
--


-- alter table im_projects drop constraint im_projects_nr_un;

-- Dont allow the same project_nr  for the same company+level
alter table im_projects add
        constraint im_projects_nr_un
        unique(project_nr, company_id, parent_id);


-- Add a new category for the project_type.
-- Puff, difficult to find one while maintaining compatible
-- the the fixed IDs from ACS 3.4 Intranet...
--
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE) 
values ('84', 'Project Task', 'Intranet Project Type');


-------------------------------------------------------------
-- Add a "sort order" field to Projects
--
alter table im_projects add sort_order integer;

