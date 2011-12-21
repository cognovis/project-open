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

-- Define value range for views
-- 300-309              intranet-portfolio-management


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
-- DynField "department_planner_days_per_year" for Cost Center
-- -------------------------------------------------------------------

alter table im_cost_centers add column department_planner_days_per_year numeric;

SELECT im_dynfield_attribute_new ('im_cost_center', 'department_planner_days_per_year', 'Department Planner Days Per Year', 'numeric', 'integer', 'f');




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


-- -------------------------------
-- Create the menu item
-- -------------------------------

SELECT im_menu__new (
	null,					-- p_menu_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'intranet-portfolio-management',	-- package_name
	'department_planner',			-- label
	'Department Planner',			-- name
	'/intranet-portfolio-management/department-planner/index?view_name=portfolio_department_planner_list',	-- url
	-40,					-- sort_order
	(select menu_id from im_menus where label = 'projects'),
	null					-- p_visible_tcl
);



SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'department_planner'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


-- ----------------------------------------------------------------
-- Program Portfolio Portlet
-- ----------------------------------------------------------------

SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Program Portfolio List',	-- plugin_name
	'intranet-portfolio-management', -- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	15,				-- sort_order
	'im_program_portfolio_list_component -program_id $project_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Program Portfolio List'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-- 300-309              intranet-portfolio-management
-- 300			program_portfolio_list

--
delete from im_view_columns where column_id > 30000 and column_id < 30099;
delete from im_views where view_id > 30000 and view_id < 30099;
--
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (300, 'program_portfolio_list', 'view_projects', 1400);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30000,300,'Ok',
'"<center>[im_project_on_track_bb $on_track_status_id]</center>"','','',0,'');

-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (30001,300,'Project nr',
-- '"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"','','',1,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30010,300,'Project Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>[string range $project_name 0 30]</A>"','','',10,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30020,300,'Start','$start_date_formatted','','',20,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30025,300,'End','$end_date_formatted','','',25,'');


insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30030,300,'Budget','$project_budget','','',30,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30035,300,'Quoted','$cost_quotes_cache','','',35,'');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30050,300,'Done','"$percent_completed_rounded%"','','',50,'');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30080,300,'Plan Costs','$planned_costs','','',80,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30085,300,'Cur Costs','$real_costs','','',85,'');

