-- /packages/intranet-milestone/sql/postgresql/intranet-milestone-create.sql
--
-- Copyright (c) 2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @Author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Milestones
--
-- "Milestones" are just projects or Tasks with the "milestone_p"
-- field set to "t".
-- Milestones are shown as a kind of report on a separate page in
-- order to allow managers to get an idea of urgent tasks.


-----------------------------------------------------------
-- A Milestone is a project with milestone_p = 't'

alter table im_projects
add milestone_p char(1)
constraint im_projects_milestone_ck
check (milestone_p in ('t','f'));

SELECT im_dynfield_attribute_new ('im_project', 'milestone_p', 'Milestone?', 'checkbox', 'boolean', 'f');


-----------------------------------------------------------
-- Create a milestone project type in order to allow for 
-- milestone-specific dynfield variables
SELECT im_category_new (2504, 'Milestone', 'Intranet Project Type');
update im_categories set enabled_p = 'f'
where category = 'Milestone' and category_type = 'Intranet Project Type';




-----------------------------------------------------------
-- Show late milestones on the home page
--

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Late Milestones',		-- plugin_name
	'intranet-milestone',		-- package_name
	'right',			-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	95,				-- sort_order
	'im_milestone_list_component -end_date_before 0 -status_id 76',	-- component_tcl
	'lang::message::lookup "" intranet-milestone.Late_Milestones "Late Milestones"'
);

-- Allow Employees to see component
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Late Milestones'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Current Milestones',		-- plugin_name
	'intranet-milestone',		-- package_name
	'right',			-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	96,				-- sort_order
	'im_milestone_list_component -end_date_after 0 -end_date_before 7 -status_id 76',	-- component_tcl
	'lang::message::lookup "" intranet-milestone.Current_Milestones "Currrent Milestones"'
);

-- Allow Employees to see component
SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Current Milestones'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



-----------------------------------------------------------
-- Menu for Milestones
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_main_menu		integer;
	v_employees		integer;
	v_customers		integer;
	v_freelancers		integer;
BEGIN
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id into v_main_menu from im_menus where label=''main'';

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-milestone'',	-- package_name
		''milestones'',		-- label
		''Milestones'',		-- name
		''/intranet-milestone/'',   -- url
		85,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

