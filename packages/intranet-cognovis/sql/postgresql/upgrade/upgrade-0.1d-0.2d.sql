-- upgrade-0.1d-0.2d.sql

SELECT acs_log__debug('packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.1d-0.2d.sql','');

CREATE OR REPLAC FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE 
	row	record;
BEGIN
	FOR row IN
		SELECT plugin_id FROM im_component_plugins 
		WHERE page_url = ''/intranet/users/view''
	LOOP
		PERFORM im_component_plugin__delete(row.plugin_id);
	END LOOP;


	RETURN 0;
END;' language 'plpgsql';
select inline_0 ();
DROP FUNCTION inline_0 ();

-- User Components

-- User Basic Info Component
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Basic Information', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_user_basic_info_component $user_id $return_url');

-- User Contact Infor Component
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Contact Information', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_user_contact_info_component $user_id $return_url');

-- User Skin Component
-- SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Skin Information', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_user_skin_info_component $user_id $return_url');

SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Skin Information', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_skin_select_html $user_id $return_url');

-- User Administration Component
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Admin Information', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_user_admin_info_component $user_id $return_url');

-- User Localization Component
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Locale', 'intranet-core', 'left', '/intranet/users/view', null, 0, 'im_user_localization_component $user_id $return_url');

-- User Portrait Component
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Portrait', 'intranet-core', 'right', '/intranet/users/view', null, 0, 'im_portrait_component $user_id_from_search $return_url $read $write $admin');

-- User Portrait Component
--SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'User Notes', 'intranet-notes', 'right', '/intranet/users/view', null, 0, 'im_notes_component -object_id $user_id');





-- Company Components

-- Company Info
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Company Information', 'intranet-core', 'left', '/intranet/companies/view', null, 0, 'im_company_info_component $company_id $return_url');

-- Company Projects
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Company Projects', 'intranet-core', 'right', '/intranet/companies/view', null, 0, 'im_company_projects_component $company_id $return_url');


-- Company Members
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Company Employees', 'intranet-core', 'right', '/intranet/companies/view', null, 0, 'im_company_employees_component $company_id $return_url');

-- Company Contacts
SELECT im_component_plugin__new (null, 'acs_object', now(), null, null, null, 'Company Contacts', 'intranet-core', 'right', '/intranet/companies/view', null, 0, 'im_company_contacts_component $company_id $return_url');