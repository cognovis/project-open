-- /packages/intranet-fs/sql/postgresql/upgrade/upgrade-4.0.0.0.2-4.0.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-fs/sql/postgresql/upgrade/upgrade-4.0.0.0.2-4.0.1.0.0.sql','');

SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Intranet Ticket FS Component',        -- plugin_name
        'intranet-fs',                  -- package_name
        'right',                        -- location
        '/intranet-cognovis/tickets/view',      -- page_url
        null,                           -- view_name
        10,                             -- sort_order
        'im_fs_component -user_id $user_id -project_id $ticket_id -return_url $return_url',
	'lang::message::lookup "" intranet-fs.Ticket_Filestorage "Ticket Filestorage"'
);


-- Make the component readable for employees and poadmins
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;

BEGIN
	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Intranet Ticket FS Component'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Intranet Task FS Component',        -- plugin_name
        'intranet-fs',                  -- package_name
        'right',                        -- location
        '/intranet-cognovis/tasks/view',      -- page_url
        null,                           -- view_name
        10,                             -- sort_order
        'im_fs_component -user_id $user_id -project_id $task_id -return_url $return_url',
	'lang::message::lookup "" intranet-fs.Task_Filestorage "Task Filestorage"'
);


-- Make the component readable for employees and poadmins
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;

BEGIN
	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';

	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Intranet Task FS Component'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	
	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


