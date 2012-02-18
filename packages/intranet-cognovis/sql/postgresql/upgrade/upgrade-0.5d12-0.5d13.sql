-- /packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d12-0.5d13.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d12-0.5d13.sql','');


-- Make all components visible to employees and p/o admins
CREATE OR REPLACE FUNCTION inline_0()
RETURNS integer AS '
DECLARE
	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;
BEGIN

	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	-- Project Base Data Cognovis
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Project Base Data Cognovis'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Home Task Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Home Task Component'' AND page_url = ''/intranet/index'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Task Member Cognovis
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Task Members Cognovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	-- Timesheet Task Project Information Cognovis
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Project Information Cognovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');





	-- Timesheet Task Resources
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Task Resources Cognovis'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Timesheet Task Forum Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Forum'' AND page_url = ''/intranet-timesheet2-tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- Timesheet Task Info Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Timesheet Task Info Component'' AND page_url = ''/intranet-cognovis/tasks/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- User Basic Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Basic Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- User Contact Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Contact Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- User Skin Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Skin Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- User Administration Information
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Admin Information'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	-- User Localization Compoenent
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Locale'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- User Portrait
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''User Portrait'' AND page_url = ''/intranet/users/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');
	
	
	-- Company Info
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Information'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	-- Company Projects
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Projects'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Company Members
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Employees'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	-- Company Contacts
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Company Contacts'' AND page_url = ''/intranet/companies/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

	
	
