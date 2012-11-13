-- Create the budget object
create table im_budgets (
    budget_id integer constraint budget_id_pk primary key 
    constraint budget_id_fk references cr_revisions(revision_id) on delete cascade,
    budget float,
    budget_hours float,
    budget_hours_explanation text,
    economic_gain float,
    economic_gain_explanation text,
    single_costs float,
    single_costs_explanation text,
    investment_costs float,
    investment_costs_explanation text,
    annual_costs float,
    annual_costs_explanation text,
    approved_p boolean default 'f'
);

select content_type__create_type (
    'im_budget',
    'content_revision',
    'Budget',
    'Budgets',
    'im_budgets',
    'budget_id',
    'content_revision.revision_name'
);

insert into acs_object_type_tables (object_type, table_name, id_column) values ('im_budget','im_budgets','budget_id');

SELECT im_dynfield_attribute_new ('im_budget', 'budget', '#intranet-pmo.Budget#', 'currencies', 'float', 'f', 1, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'budget_hours', '#intranet-pmo.Hours#', 'numeric', 'float', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'budget_hours_explanation', '#intranet-pmo.HoursExplanation#', 'richtext', 'text', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'economic_gain', '#intranet-pmo.EconomicGain#', 'currencies', 'float', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'economic_gain_explanation', '#intranet-pmo.EconomicGainExplanation#', 'richtext', 'text', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'single_costs', '#intranet-pmo.SingleCosts#', 'currencies', 'float', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'single_costs_explanation', '#intranet-pmo.SingleCostsExplanation#', 'richtext', 'text', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'investment_costs', '#intranet-pmo.InvestmentCosts#', 'currencies', 'float', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'investment_costs_explanation', '#intranet-pmo.InvestmentCostsExplanation#', 'richtext', 'text', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'annual_costs', '#intranet-pmo.AnnualCosts#', 'currencies', 'float', 'f', 2, 't');
SELECT im_dynfield_attribute_new ('im_budget', 'annual_costs_explanation', '#intranet-pmo.AnnualCostsExplanation#', 'richtext', 'text', 'f', 2, 't');

select content_type__refresh_view('im_budget');

-- Create the Hour object
create table im_budget_hours (
    hour_id integer constraint hour_id_pk primary key 
    constraint hour_id_fk references cr_revisions(revision_id) on delete cascade,
    hours float,
    department_id integer,
    approved_p boolean default 'f'
);

select content_type__create_type (
    'im_budget_hour',
    'content_revision',
    'Budget Hour',
    'Budget Hours',
    'im_budget_hours',
    'hour_id',
    'content_revision.revision_name'
);

insert into acs_object_type_tables (object_type, table_name, id_column) values ('im_budget_hour','im_budget_hours','hour_id');
SELECT im_dynfield_attribute_new ('im_budget_hour', 'hours', '#intranet-pmo.Hours#', 'numeric', 'float', 'f', 1, 't');     
SELECT im_dynfield_attribute_new ('im_budget_hour', 'department_id', '#intranet-pmo.Department#', 'departments', 'integer', 'f', 2, 't');
select content_type__refresh_view('im_budget_hour');

-- Create the Cost object
create table im_budget_costs (
    cost_id integer constraint cost_id_pk primary key 
    constraint cost_id_fk references cr_revisions(revision_id) on delete cascade,
    amount float,
    type_id integer,
    approved_p boolean default 'f'
);

select content_type__create_type (
    'im_budget_cost',
    'content_revision',
    'Budget Cost',
    'Budget Costs',
    'im_budget_costs',
    'cost_id',
    'content_revision.revision_name'
);

insert into acs_object_type_tables (object_type, table_name, id_column) values ('im_budget_cost','im_budget_costs','cost_id');
SELECT im_dynfield_attribute_new ('im_budget_cost', 'amount', '#intranet-pmo.Amount#', 'currencies', 'float', 'f', 1, 't');     
SELECT im_dynfield_attribute_new ('im_budget_cost', 'type_id', '#intranet-pmo.Type#', 'numeric', 'integer', 'f', 2, 't');
update acs_object_types set type_column='type_id', type_category_type='Intranet Cost Type' where object_type = 'im_budget_cost';
select content_type__refresh_view('im_budget_cost');

-- Create the Benefit object
create table im_budget_benefits (
    benefit_id integer constraint benefit_id_pk primary key 
    constraint benefit_id_fk references cr_revisions(revision_id) on delete cascade,
    amount float,
    type_id integer,
    approved_p boolean default 'f'
);

select content_type__create_type (
    'im_budget_benefit',
    'content_revision',
    'Budget Benefit',
    'Budget Benefits',
    'im_budget_benefits',
    'benefit_id',
    'content_revision.revision_name'
);

insert into acs_object_type_tables (object_type, table_name, id_column) values ('im_budget_benefit','im_budget_benefits','benefit_id');
SELECT im_dynfield_attribute_new ('im_budget_benefit', 'amount', '#intranet-pmo.Amount#', 'currencies', 'float', 'f', 1, 't');     
SELECT im_dynfield_attribute_new ('im_budget_benefit', 'type_id', '#intranet-pmo.Type#', 'numeric', 'integer', 'f', 2, 't');
update acs_object_types set type_column='type_id', type_category_type='Intranet Benefit Type' where object_type = 'im_budget_benefit';
select content_type__refresh_view('im_budget_benefit');




SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Project Budget Component', 'intranet-pmo', 'left', '/intranet/projects/view', null, 10, 'im_budget_summary_component -user_id $user_id -project_id $project_id -return_url $return_url');

-- Set component as readable for employees and poadmins
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;

BEGIN
	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Project Budget Component'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();





SELECT im_category_new (3750,'Budget Cost Estimation','Intranet Cost Type');
SELECT im_category_new (3751,'Investment Cost Budget','Intranet Cost Type');
SELECT im_category_new (3752,'One Time Cost Budget ','Intranet Cost Type');
SELECT im_category_new (3753,'Repeating Cost Budget','Intranet Cost Type');

SELECT im_category_hierarchy_new(3751,3750);
SELECT im_category_hierarchy_new(3752,3750);
SELECT im_category_hierarchy_new(3753,3750);

SELECT im_category_new (3760,'Budget Benefit Estimation','Intranet Cost Type');

SELECT im_category_new (9015,'Budget','Intranet Material Type');


-- Add a "Priority" field to projects
--
alter table im_projects
add project_priority integer;


-- Define the value range for categories
-- The aux_int1 value will include a numeric value for the priorites
--
-- 70000-70999  Portfolio Management (1000)
-- 70000-70099  Intranet Department Planner Project Priority (100)
-- 70100-71999  Intranet Department Planner Action (100)

SELECT im_category_new (70000, '1 - Lowest Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70002, '2 - Very Low Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70004, '3 - Low Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70006, '4 - Medium Low Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70008, '5 - Average Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70010, '6 - Medium High Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70012, '7 - High Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70014, '8 - Very High Priority', 'Intranet Department Planner Project Priority');
SELECT im_category_new (70016, '9 - Highest Priority', 'Intranet Department Planner Project Priority');

-- Calculate 1 - 9 priority numeric value from category id. Ugly, but OK..
update im_categories
set aux_int1 = (category_id - 70000) / 2 + 1
where category_type = 'Intranet Department Planner Project Priority';

update im_categories
set sort_order = (category_id - 70000) / 2 + 1
where category_type = 'Intranet Department Planner Project Priority';

SELECT im_category_new (70001, 'Not set', 'Intranet Department Planner Project Priority');
update im_categories set sort_order = 0, aux_int1=0 where category_id = 70001;

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

-- Add a "Priority" field to projects
--
alter table im_projects
add project_priority_op_id integer
constraint im_projects_project_priority_op_fk references im_categories;

-- Create the DynField for the project
SELECT im_dynfield_attribute_new ('im_project', 'project_priority', 'Project Priority', 'project_priority', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_project', 'project_priority_op_id', 'Project Operational Priority', 'project_priority', 'integer', 'f');

-- Revoke the permissions for ordinary mortal (employees, customers, freelancers)
-- for this field, because it doesn't need to be visible.

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'write'
);


SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'write'
);

---- op_id

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'write'
);


SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_op_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'write'
);


-- Add a "Strategic Priority" field to projects
--
alter table im_projects
add project_priority_st_id integer
constraint im_projects_project_priority_st_fk references im_categories;



SELECT im_dynfield_attribute_new ('im_project', 'project_priority_st_id', 'Project Operational Priority ST', 'project_priority', 'integer', 'f');

---- st_id

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Employees'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Customers'),
	'write'
);

SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'read'
);
SELECT im_revoke_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Freelancers'),
	'write'
);


SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'read'
);
SELECT im_grant_permission(
	(select attribute_id from im_dynfield_attributes where acs_attribute_id in 
		(select attribute_id from acs_attributes where attribute_name = 'project_priority_st_id' and object_type = 'im_project')
	),
	(select group_id from groups where group_name = 'Senior Managers'),
	'write'
);




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
extra_select, extra_where, sort_order, visible_for) values (92005,920,NULL,'Priority','$project_priority','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (92010,920,NULL,'Project',
'"<nobr>$indent_html$gif_html<a href=[export_vars -base $project_base_url {project_id}]>$project_name</a></nobr>"','','',10,'');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92006,920,NULL,'Operational Priority',
'"[im_category_select -include_empty_p 1 {Intranet Department Planner Project Priority} project_priority_op_id.$project_id $project_priority_op_id]"','','',6,'','');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92007,920,NULL,'Strategic Priority',
'"[im_category_select -include_empty_p 1 {Intranet Department Planner Project Priority} project_priority_st_id.$project_id $project_priority_st_id]"','','',7,'','');


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
	'intranet-pmo',		-- package_name
	'department_planner',			-- label
	'Department Planner',			-- name
	'/intranet-pmo/department-planner/index?view_name=portfolio_department_planner_list',	-- url
	-40,					-- sort_order
	(select menu_id from im_menus where label = 'projects'),
	null					-- p_visible_tcl
);



SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'department_planner'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


delete from im_view_columns where view_id = 921;
delete from im_views where view_id = 921;

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (921, 'portfolio_department_planner_list_ajax', 'view_users', 1415);


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92015,921,NULL,'#intranet-pmo.Priority#','"$project_priority"','','',5,'','hidden project_priority "$project_priority"');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92016,921,NULL,'#intranet-pmo.Project_ID#','"$project_id"','','',0,'','hidden project_id "$project_id"');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92025,921,NULL,'#intranet-core.Project#',
'"<nobr>$indent_html$gif_html<a href=\\\\\\"[export_vars -base $project_base_url {project_id}]\\\\\\">$project_name</a></nobr>"','','',15,'','link Projekt "<nobr>$indent_html$gif_html<a href=[export_vars -base $project_base_url {project_id}]>$project_name</a></nobr>" 1 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92026,921,NULL,'#intranet-pmo.Operational_Priority#',
'"[im_category_from_id $project_priority_op_id]"','','',6,'','	dropdown project_priority_op_id { [im_department_planner_priority_list] } 1 1
');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92027,921,NULL,'#intranet-pmo.Strategic_Priority#',
'"[im_category_from_id $project_priority_st_id]"','','',10,'','	dropdown project_priority_st_id { [im_department_planner_priority_list] } 1 1
');

---------------------------------------------------------
-- Setup the "Budget" menu entry in "Projects"
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu		integer;
	v_parent_menu		integer;
	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers	integer;
	v_proman		integer;
	v_admins		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id into v_parent_menu from im_menus
	where label=''project'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-pmo'',	-- package_name
		''project_budget'',	-- label
		''Budget'',				-- name
		''/intranet-pmo/budget/budget'', -- url
		50,				-- sort_order
		v_parent_menu,			-- parent_menu_id
		''[expr [im_permission $user_id view_timesheet_tasks] && [im_project_has_type [ns_set get $bind_vars project_id] "Consulting Project"]]'' -- p_visible_tcl
	);

	-- Set permissions of the "Tasks" tab 
	update im_menus
	set visible_tcl = ''[expr [im_permission $user_id view_timesheet_tasks] && [im_project_has_type [ns_set get $bind_vars project_id] "Consulting Project"]]''
	where menu_id = v_menu;

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


select acs_privilege__create_privilege('approve_budgets','Approve Budgets','Approve Budgets');
select acs_privilege__add_child('admin', 'approve_budgets');


alter table im_projects add column cost_bills_planned numeric(12,2);
alter table im_projects add column cost_expenses_planned numeric(12,2);


-----------------------------------------------------------
-- Planning
--
-- Assign a monthly or weekly number to an object and its 1st and 2nd dimension


-- Create a new object type.
-- This statement only creates an entry in acs_object_types with some
-- meta-information (table name, ... as specified below) about the new 
-- object. 
-- Please note that this is quite different from creating a new object
-- class in Java or other languages.

SELECT acs_object_type__create_type (
	'im_planning_item',			-- object_type - only lower case letters and "_"
	'Planning Item',			-- pretty_name - Human readable name
	'Planning Items',			-- pretty_plural - Human readable plural
	'acs_object',				-- supertype - "acs_object" is topmost object type.
	'im_planning_items',			-- table_name - where to store data for this object?
	'item_id',				-- id_column - where to store object_id in the table?
	'intranet-planning',			-- package_name - name of this package
	'f',					-- abstract_p - abstract class or not
	null,					-- type_extension_table
	'im_planning_item__name'		-- name_method - a PL/SQL procedure that
						-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_planning_item object.
update acs_object_types set
        status_type_table = 'im_planning_items',	-- which table contains the status_id field?
        status_column = 'item_status_id',		-- which column contains the status_id field?
        type_column = 'item_type_id'			-- which column contains the type_id field?
where object_type = 'im_planning_item';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_planning_item object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_planning_item', 'im_planning_items', 'item_id');


-- Generic URLs to link to an object of type "im_planning_item".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_planning_item','view','/intranet-planning/new?display_mode=display&item_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_planning_item','edit','/intranet-planning/new?display_mode=edit&item_id=');

-- This table stores one time line of items.
-- It is not an OpenACS object, so the item_id does not reference acs_objects.
---
create table im_planning_items (
			-- The (fake) object_id: does not yet reference acs_objects.
	item_id		integer
			constraint im_planning_item_id_pk
			primary key
			constraint im_planning_item_itm_fk
			references acs_objects,
			-- Field to allow attaching the item to a project, user or
			-- company. So object_id references acs_objects.object_id,
			-- the supertype of all object types.
	item_object_id	integer
			constraint im_planning_object_id_nn
			not null
			constraint im_planning_items_object_fk
			references acs_objects,
			-- Type can be "Revenues" or "Costs"
	item_type_id	integer 
			constraint im_planning_item_type_nn
			not null
			constraint im_planning_item_type_fk
			references im_categories,
			-- Status of the planned row. May be "Active", "Approved"
			-- or "Deleted". Could be controlled by a workflow.
	item_status_id	integer 
			constraint im_planning_item_status_nn
			not null
			constraint im_planning_item_status_fk
			references im_categories,
			-- Project phase dimension
			-- for planning on project phases.
	item_project_phase_id integer
			constraint im_planning_items_project_phase_fk
			references im_projects,
			-- Project member dimension
			-- for planning per project member.
	item_project_member_id integer
			constraint im_planning_items_project_member_fk
			references parties,
			-- Only for planning hourly costs:
			-- Contains the hourly_cost of the resource in order
			-- to keep budgets from changing when changing the 
			-- im_employees.hourly_cost of a resource.
	item_project_member_hourly_cost numeric(12,3),
			-- Cost type dimension.
			-- Valid values include categories from "Intranet Cost Type"
			-- and "Intranet Expense Type" (as a sub-type for expenses)
	item_cost_type_id integer,
			-- Actual time dimension.
			-- The timestamptz indicates the start of the
			-- time range defined by item_date_type_id.
	item_date	timestamptz,
			-- Start of the time line for planning values.
			-- Should be set to the 1st day of week or month to plan.
	item_value	numeric(12,2),
			-- Note per line
	item_note	text
);

-- Speed up (frequent) queries to find all planning for a specific object.
create index im_planning_items_object_idx on im_planning_items(item_object_id);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint in order
-- to avoid creating duplicate entries during data import or if the user
-- performs a "double-click" on the "Create New Planning Item" button...
-- (This makes a lot of sense in practice. Otherwise there would be loads
-- of duplicated projects in the system and worse...)
create unique index im_planning_object_item_idx on im_planning_items(
	item_object_id,
	coalesce(item_project_phase_id,0), 
	coalesce(item_project_member_id,0),
	coalesce(item_cost_type_id,0),
	coalesce(item_date,'2000-01-01'::timestamptz)
);

-- Create a new planning item
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a item with
-- the required fields of the im_planning table.
create or replace function im_planning_item__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	integer, integer, integer,
	numeric, varchar,
	integer, integer, integer, timestamptz
) returns integer as $body$
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_item_id		alias for $1;		-- item_id  default null
	p_object_type   	alias for $2;		-- object_type default im_planning_item
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	-- Standard parameters
	p_item_object_id	alias for $7;		-- associated object (project, user, ...)
	p_item_type_id		alias for $8;		-- type (email, http, text comment, ...)
	p_item_status_id	alias for $9;		-- status ("active" or "deleted").

	-- Value parameters
	p_item_value		alias for $10;		-- the actual numeric value
	p_item_note		alias for $11;		-- A note per entry.

	-- Dimension parameter
	p_item_project_phase_id	alias for $12;
	p_item_project_member_id alias for $13;
	p_item_cost_type_id	alias for $14;
	p_item_date		alias for $15;

	v_item_id		integer;
BEGIN
	v_item_id := acs_object__new (
		p_item_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	-- Create an entry in the im_planning table with the same
	-- v_item_id from acs_objects.object_id
	insert into im_planning_items (
		item_id,
		item_type_id,
		item_status_id,
		item_object_id,
		item_project_phase_id,
		item_project_member_id,
		item_cost_type_id,
		item_date,
		item_value,
		item_note
	) values (
		v_item_id,
		p_item_type_id,
		p_item_status_id,
		p_item_object_id,
		p_item_project_phase_id,
		p_item_project_member_id,
		p_item_cost_type_id,
		p_item_date,
		p_item_value,
		p_item_note
	);

	-- Store the current hourly_rate with planning items.
	IF p_item_cost_type_id = 3736 AND p_item_project_member_id is not null THEN
		update im_planning_items
		set item_project_member_hourly_cost = (
			select hourly_cost
			from   im_employees
			where  employee_id = p_item_project_member_id
		    )
		where item_id = v_item_id;
	END IF;

	return 0;
END; $body$ language 'plpgsql';


-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for Planning type and status.
-- Status acutally is not used by the application, 
-- so we just define "active" and "deleted".
-- Type contains information on how to format the data
-- in the im_planning.note field. For example, a "HTTP"
-- note is shown as a link.
--
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own packages.
--
-- 73000-73999  Intranet Planning (1000)
-- 73000-73099  Intranet Planning Status (100)
-- 73100-73199  Intranet Planning Type (100)
-- 73200-73299  Intranet Planning Time Dimension (100)
-- 73200-73999  reserved (800)

-- Status
SELECT im_category_new (73000, 'Active', 'Intranet Planning Status');
SELECT im_category_new (73002, 'Deleted', 'Intranet Planning Status');

-- Type
SELECT im_category_new (73100, 'Revenues', 'Intranet Planning Type');
SELECT im_category_new (73102, 'Costs', 'Intranet Planning Type');
SELECT im_category_new (73121,'Investment Cost','Intranet Planning Type');
SELECT im_category_new (73122,'One Time Cost','Intranet Planning Type');
SELECT im_category_new (73123,'Repeating Cost','Intranet Planning Type');
SELECT im_category_new (73101,'Benefit Estimation','Intranet Planning Type');

SELECT im_category_hierarchy_new(73121,73102);
SELECT im_category_hierarchy_new(73122,73102);
SELECT im_category_hierarchy_new(73123,73102);

-- Time Dimension
SELECT im_category_new (73200, 'Quarter', 'Intranet Planning Time Dimension');
SELECT im_category_new (73202, 'Month', 'Intranet Planning Time Dimension');
SELECT im_category_new (73204, 'Week', 'Intranet Planning Time Dimension');
SELECT im_category_new (73206, 'Day', 'Intranet Planning Time Dimension');


-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_planning_item_status as
select	category_id as item_status_id, category as item_status
from	im_categories
where	category_type = 'Intranet Planning Status'
	and enabled_p = 't';

create or replace view im_planning_item_types as
select	category_id as item_type_id, category as item_type
from	im_categories
where	category_type = 'Intranet Planning Type'
	and enabled_p = 't';




-------------------------------------------------------------
-- Permissions and Privileges
--

-- A "privilege" is a kind of parameter that can be set per group
-- in the Admin -> Profiles page. This way you can define which
-- users can see planning.
-- In the default configuration below, only Employees have the
-- "privilege" to "view" planning.
-- The "acs_privilege__add_child" line below means that "view_planning_all"
-- is a sub-privilege of "admin". This way the SysAdmins always
-- have the right to view planning.

select acs_privilege__create_privilege('view_planning_all','View Planning All','View Planning All');
select acs_privilege__add_child('admin', 'view_planning_all');

-- Allow all employees to view planning. You can add new groups in 
-- the Admin -> Profiles page.
select im_priv_create('view_planning_all','Employees');

SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Project Assignment Component', 'intranet-pmo', 'left', '/intranet/projects/view', null, 10, 'im_project_assignment_component -user_id $user_id -project_id $project_id -return_url $return_url');

-- Set component as readable for employees and poadmins
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;

BEGIN
	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Project Assignment Component'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


