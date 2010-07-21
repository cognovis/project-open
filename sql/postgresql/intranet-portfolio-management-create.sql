-- /packages/intranet-portfolio-management/sql/postgresql/intranet-portfolio-management-create.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Add a "Priority" field to projects
--
alter table im_projects
add project_priority_id integer
constraint im_projects_project_priority_fk references im_categories;

-- Define the value range for categories
-- The aux_int1 value will include a numeric value for the priorites
--
-- 70000-70999  Portfolio Management (1000)
-- 70000-70099  Intranet Department Planner Project Priority (100)
-- 70100-71999  Intranet Department Planner Action (100)

SELECT im_category_new (70000, '1 - Highest Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70002, '2 - Very High Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70004, '3 - High Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70006, '4 - Medium High Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70008, '5 - Average Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70010, '6 - Medium Low Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70012, '7 - Low Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70014, '8 - Very Low Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70016, '9 - Lowest Priority', 'Intranet Department Planner Project Priority');

-- Calculate 1 - 9 priority numeric value from category id. Ugly, but OK..
update im_categories
set aux_int1 = (category_id - 70000) / 2 + 1
where category_type = 'Intranet Department Planner Project Priority';

update im_categories
set sort_order = (category_id - 70000) / 2 + 1
where category_type = 'Intranet Department Planner Project Priority';



-- 70100-71999  Intranet Department Planner Action (100)
-- Currently there is only one action: Save (the priorities of the projects)
SELECT im_category_new (70100, 'Save', 'Intranet Department Planner Action');



-- Create a widget to show the project priorities
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'project_priority', 'Project Priority', 'Project Priority',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Department Planner Project Priority"}}'
);

-- Create the DynField for the project
SELECT im_dynfield_attribute_new ('im_project', 'project_priority_id', 'Project Priority', 'project_priority', 'integer', 'f');

-- Revoke the permissions for ordinary mortal (employees, customers, freelancers)
-- for this field, because it doesn't need to be visible.

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'write'
);


SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'write'
);





-- Set all main projects to average priority by default
update im_projects set project_priority_id = 70008
where parent_id is null;


-- -------------------------------------------------------------------
-- Dynamic View
-- -------------------------------------------------------------------

--
-- Wide View in "Tasks" page, including Description
--
delete from im_view_columns where view_id = 920;
delete from im_views where view_id = 920;
--
insert into im_views (view_id, view_name, visible_for) values (920, 'portfolio_department_planner_list', 'view_projects');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (92005,920,NULL,'Priority',
'"[im_category_select {Intranet Department Planner Project Priority} project_priority_id.$project_id $project_priority_id]"','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (92010,920,NULL,'Project',
'"<nobr>$indent_html$gif_html<a href=[export_vars -base $project_base_url {project_id}]>$project_name</a></nobr>"','','',10,'');

