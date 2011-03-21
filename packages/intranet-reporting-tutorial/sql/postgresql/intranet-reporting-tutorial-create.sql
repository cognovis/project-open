-- /package/intranet-reporting-tutorial/sql/postgresql/intranet-reporting-tutorial-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.

-- Reporting Tutorial

---------------------------------------------------------
-- Reports
--
-- This data model supports the ]project-open[ reporting tool
-- to generate and store all type of reports.
--
-- Reports are defined in .tcl pages and associated with 
-- a menu item via the "label" of the menu item. 
-- This menu item determines the permissions of the report,
-- by showing the report's existence AND by a reverse
-- check from the report for its menu.


---------------------------------------------------------
-- Report Menus
--

--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_reporting_menu 	integer;
	v_count			integer;

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

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id into v_reporting_menu
    from im_menus where label=''reporting'';

    select count(*) into v_count
    from im_menus where label = ''reporting_tutorial'';
    IF v_count > 0 THEN return 0; END IF;

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'', -- package_name
	''reporting_tutorial'',		-- label
	''Reporting Tutorial'',		-- name
	''/intranet-reporting-tutorial/'', -- url
	250,				-- sort_order
	v_reporting_menu,		-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Tutorial Reports
--

create or replace function inline_0 ()
returns integer as '
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

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id into v_main_menu
    from im_menus where label=''reporting_tutorial'';

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'', -- package_name
	''reporting-tutorial-projects01'', -- label
	''Project Report 01'',		-- name
	''/intranet-reporting-tutorial/projects-01-commented'', -- url
	10,				-- sort_order
	v_main_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');


    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'', -- package_name
	''reporting-tutorial-projects02'', -- label
	''Project Report 02'',		-- name
	''/intranet-reporting-tutorial/projects-02'', -- url
	20,				-- sort_order
	v_main_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'', -- package_name
	''reporting-tutorial-projects03'', -- label
	''Project Report 03'',		-- name
	''/intranet-reporting-tutorial/projects-03'', -- url
	30,				-- sort_order
	v_main_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'', -- package_name
	''reporting-tutorial-projects04'',	-- label
	''Project Report 04'',		-- name
	''/intranet-reporting-tutorial/projects-04'', -- url
	40,				-- sort_order
	v_main_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'', -- package_name
	''reporting-tutorial-projects05'',	-- label
	''Project Report 05'',		-- name
	''/intranet-reporting-tutorial/projects-05'', -- url
	50,				-- sort_order
	v_main_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');



    v_menu := im_menu__new (
	null,				-- p_menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-reporting-tutorial'',	-- package_name
	''reporting-tutorial-forum01'',		-- label
	''Forum AdHoc Report 01'',	-- name
	''/intranet-reporting-tutorial/forum-adhoc-01'', -- url
	50,				-- sort_order
	v_main_menu,			-- parent_menu_id
	null				-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');



	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-reporting-tutorial'',	-- package_name
		''reporting-tutorial-transtasks01'',	-- label
		''Translation Tasks AdHoc Report 01'',	-- name
		''/intranet-reporting-tutorial/trans-tasks-adhoc-01'', -- url
		170,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');



    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



