-- /packages/intranet-wall/sql/postgresql/intranet-wall-create.sql
--
-- Copyright (c) 2003-2012 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



SELECT im_lang_add_message('en_US','intranet-wall','Comments','Comments');
SELECT im_lang_add_message('en_US','intranet-wall','Status','Status');
SELECT im_lang_add_message('en_US','intranet-wall','Type','Type');
SELECT im_lang_add_message('en_US','intranet-wall','Thumbs','Thumbs');
SELECT im_lang_add_message('en_US','intranet-wall','Name','Name');
SELECT im_lang_add_message('en_US','intranet-wall','Description_of_activities','Description of Activities');



---------------------------------------------------------
-- Wall Menu
-- 
-- This is a sub-menu im the "Reporting" section

create or replace function inline_0 ()
returns integer as $body$
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	select group_id into v_admins from groups where group_name = 'P/O Admins';
	select group_id into v_senman from groups where group_name = 'Senior Managers';
	select group_id into v_proman from groups where group_name = 'Project Managers';
	select group_id into v_accounting from groups where group_name = 'Accounting';
	select group_id into v_employees from groups where group_name = 'Employees';
	select group_id into v_customers from groups where group_name = 'Customers';
	select group_id into v_freelancers from groups where group_name = 'Freelancers';
	select group_id into v_reg_users from groups where group_name = 'Registered Users';

	select menu_id into v_main_menu
	from im_menus where label='reporting';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		'im_menu',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		'intranet-wall',			-- package_name
		'reporting-wall',			-- label
		'Project-Wall (System)',		-- name
		'/intranet-wall/',			-- url
		200,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, 'read');

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


----------------------------------------------------------------------
-- New Objects Report
----------------------------------------------------------------------

SELECT im_report_new (
	'Project-Wall New Project Task',				-- report_name
	'wall_new_project_task',					-- report_code
	'intranet-wall',						-- package_key
	1000,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-wall'),	-- parent_menu_id
'
select	''wall_new_project_task'' as type,

	acs_lang_lookup_message(:user_id, ''intranet-wall'', ''New Task'')  as title,
	''blue'' as color,
	''new'' as icon,
	o.creation_date as date,
	coalesce(p.description, p.note, p.project_name) as message,

	main_p.project_id as container_object_id,
	''im_project'' as container_object_type,
	main_p.project_name as container_object_name,

	t.task_id as specific_object_id,
	o.object_type as specific_object_type,
	p.project_name as specific_object_name,

	im_name_from_user_id(o.creation_user) as user_name,
	o.creation_user as user_id

from	acs_objects o,
	im_projects p,
	im_timesheet_tasks t,
	im_projects main_p
where
	o.object_id = p.project_id and
	o.object_id = t.task_id and
	tree_root_key(p.tree_sortkey) = main_p.tree_sortkey and
	o.creation_date >= ''%wall_date%''
order by
	o.object_type, o.object_id
'
);

update im_reports 
set report_description = 'Lists all objects created since %wall_date%.'
where report_code = 'wall_new_project_task';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'wall_new_project_task'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);






SELECT im_report_new (
	'Project-Wall New Objects',					-- report_name
	'wall_new_objects',						-- report_code
	'intranet-wall',						-- package_key
	1000,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-wall'),	-- parent_menu_id
'
select	''new_object'' as type,
	acs_lang_lookup_message(:user_id, ''intranet-wall'', ''New'') || '' '' || 
		acs_lang_lookup_message(:user_id, ''intranet-wall'', o.object_type) || ''  '' || 
		acs_object__name(o.object_id) as title,
	''blue'' as color,
	''new'' as icon,
	o.creation_date as date,
	'''' as message,
	o.object_id as container_object_id,
	o.object_type as container_object_type,
	acs_object__name(o.object_id) as container_object_name,
	null as specific_object_id,
	null as specific_object_type,
	null as specific_object_name,
	im_name_from_user_id(o.creation_user) as user_name,
	o.creation_user as user_id
from	acs_objects o
where	o.creation_date >= ''%wall_date%'' and
	o.object_type in (
		''im_company'',
		''user'',
		''::xowiki::Page''
	)
order by
	o.object_type, o.object_id
'
);

update im_reports 
set report_description = 'Lists all objects created since %wall_date%.'
where report_code = 'wall_new_objects';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'wall_new_objects'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



/*
	o.object_type not in (
		''acs_activity'',
		''acs_object'',
		''acs_reference_repository'',
		''acs_sc_contract'',
		''acs_sc_implementation'',
		''acs_sc_operation'',
		''acs_sc_msg_type'',
		''apm_package'', 
		''apm_package_version'',
		''apm_parameter'',
		''apm_parameter_value'',
		''cal_item'',
		''cr_item_child_rel'',
		''im_biz_object_member'',
		''im_component_plugin'',
		''im_dynfield_attribute'',
		''im_dynfield_widget'',
		''im_indicator'',
		''im_menu'',
		''im_report'',
		''notification_type'',
		''site_node'',
		''zzz''
	)

*/


