-- /packages/intranet-expenses-workflow/sql/postgresql/intranet-expenses-workflow-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Import default workflow for expense approval
\i workflow-expense_approval_wf-create.sql



-- Add new workflow states to costs.
-- These may also be used outside of this module though...
select im_category_new(3816, 'Requested', 'Intranet Cost Status');
select im_category_new(3818, 'Rejected', 'Intranet Cost Status');



-- ------------------------------------------------------
-- Workflow Graph & Journal on Absence View Page
-- ------------------------------------------------------

SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Expense Bundle Confirmation Workflow',	-- component_name
	'intranet-expenses-workflow',		-- package_name
	'right',				-- location
	'/intranet-expenses/bundle-new',	-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_workflow_graph_component -object_id $bundle_id'
);

SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Expense Bundle Confirmation Journal',			-- component_name
	'intranet-timesheet2-workflow',		-- package_name
	'bottom',				-- location
	'/intranet-expenses/bundle-new',	-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_workflow_journal_component -object_id $bundle_id'
);


-----------------------------------------------------------
-- Add "Start Timesheet Workflow" link to TimesheetNewPage
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_proman		integer;
	v_admins		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';

	-- Determine the main menu. "Label" is used to identify menus.
	select menu_id into v_main_menu
	from im_menus where label = ''timesheet_hours_new_admin'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-expenses-workflow'',	-- package_name
		''timesheet_hours_new_start_workflow'',	-- label
		''Start Confirmation Workflow'',		-- name
		''/intranet-expenses-workflow/new-workflow?'',	-- url
		15,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
