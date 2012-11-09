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

create table im_biz_object_members_availability (
       rel_id integer constraint rel_id_fk references im_biz_object_members(rel_id) on delete cascade,
       start_date date not null,
       availability float default 100,
       primary key(rel_id,start_date)
);
