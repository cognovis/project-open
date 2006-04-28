--
-- upgrade-3.1.3-3.2.0.sql


-- Very ugly - we need to reverse the introduction
-- of timesheet-tasks in for logging hours. Now
-- timesheet-tasks are a subclass of im_project.

-- copy the timesheet_task column to projects 
-- and drop the column
-- update im_hours set project_id = timesheet_task_id;
-- alter table im_hours drop timesheet_task_id;


-- Recreate the indices. 
-- Got lost when removing the timesheet-task field
--
-- alter table im_hours add primary key (user_id, project_id, day);
-- create index im_hours_project_id_idx on im_hours(project_id);
-- create index im_hours_user_id_idx on im_hours(user_id);
-- create index im_hours_day_idx on im_hours(day);


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu		   integer;	v_parent_menu	   integer;
	-- Groups
	v_employees	   integer;	v_accounting	   integer;
	v_senman	   integer;	v_customers	   integer;
	v_freelancers      integer;	v_proman	   integer;
	v_admins	   integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id into v_parent_menu
    from im_menus where label=''main'';

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-timesheet2'',	-- package_name
	''timesheet2_timesheet'',	-- label
	''Timesheet'',			-- name
	''/intranet-timesheet2/hours/index'', -- url
	73,				-- sort_order
	v_parent_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-timesheet2'',	-- package_name
	''timesheet2_absences'',	-- label
	''Absences'',			-- name
	''/intranet-timesheet2/absences/index'', -- url
	74,				-- sort_order
	v_parent_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


