-- /package/intranet-reporting-finance/sql/postgresql/intranet-reporting-finance-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
--
-- Financial Invoices for ]po[


-- Delete old menu entries 
delete from im_menus
where	package_name = 'intranet-reporting'
	and label like 'reporting-finance-%';


---------------------------------------------------------
-- Finance Report Menus
--

--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_reporting_menu 	integer;

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

	select menu_id
	into v_reporting_menu
	from im_menus
	where label=''reporting'';

	v_reporting_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'',		-- package_name
		''reporting-finance'',			-- label
		''Reporting Finance'',			-- name
		''/intranet-reporting-finance/'',	-- url
		50,					-- sort_order
		v_reporting_menu,			-- parent_menu_id
		null					-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Finance - Monthly Summary
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
	from im_menus where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'',		-- package_name
		''reporting-finance-monthly-summary'',	-- label
		''Finance Monthly Summary'',		-- name
		''/intranet-reporting-finance/finance-monthly-summary'', -- url
		20,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Finance - Quotes and POs
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

	select menu_id
	into v_main_menu
	from im_menus
	where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'', -- package_name
		''reporting-finance-documents-projects'', -- label
		''Finance Documents and their Projects'', -- name
		''/intranet-reporting-finance/finance-documents-projects'', -- url
		30,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'', -- package_name
		''reporting-finance-payment-balance'',	-- label
		''Finance Payment Balance'',		-- name
		''/intranet-reporting-finance/finance-payment-balance'', -- url
		40,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

--	v_menu := im_menu__new (
--		null,					-- p_menu_id
--		''acs_object'',				-- object_type
--		now(),					-- creation_date
--		null,					-- creation_user
--		null,					-- creation_ip
--		null,					-- context_id
--		''intranet-reporting-finance'',		-- package_name
--		''reporting-finance-revenues'',		-- label
--		''Finance Revenues'',			-- name
--		''/intranet-reporting-finance/finance-revenues'', -- url
--		50,					-- sort_order
--		v_main_menu,				-- parent_menu_id
--		null					-- p_visible_tcl
--	);
--
--	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
--	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
--	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();







---------------------------------------------------------
-- Finance - Projects and its Financial Documents
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

	select menu_id
	into v_main_menu
	from im_menus
	where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'',		-- package_name
		''reporting-finance-projects-documents'', -- label
		''Finance Projects and their Documents'', -- name
		''/intranet-reporting-finance/finance-projects-documents'', -- url
		50,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------
-- Finance - Income Statement
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
	from im_menus where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,						-- p_menu_id
		''acs_object'',					-- object_type
		now(),						-- creation_date
		null,						-- creation_user
		null,						-- creation_ip
		null,						-- context_id
		''intranet-reporting-finance'', 		-- package_name
		''reporting-finance-income-statement'',		-- label
		''Finance Income Statement'',			-- name
		''/intranet-reporting-finance/finance-income-statement'', -- url
		60,						-- sort_order
		v_main_menu,					-- parent_menu_id
		null						-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



---------------------------------------------------------
-- Finance - Expenses
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
	from im_menus where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'',		-- package_name
		''reporting-finance-expenses'',		-- label
		''Finance Expenses'',			-- name
		''/intranet-reporting-finance/finance-expenses'', -- url
		70,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



---------------------------------------------------------
-- Finance - Income Statement
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
	v_freelancers	   integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;

	v_count			integer;
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
    from im_menus where label=''reporting-finance'';

    select menu_id into v_count from im_menus
    where label = ''reporting-finance-income-statement'';
    IF v_count != 0 THEN return 0; END IF;

    v_menu := im_menu__new (
	null,						-- p_menu_id
	''acs_object'',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	''intranet-reporting-finance'',			-- package_name
	''reporting-finance-income-statement'',		-- label
	''Finance Income Statement'',   		-- name
	''/intranet-reporting-finance/finance-income-statement'', -- url
	60,						-- sort_order
	v_main_menu,					-- parent_menu_id
	null						-- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



---------------------------------------------------------
-- Finance - Expenses
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

	v_count			integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id into v_main_menu from im_menus
    where label=''reporting-finance'';

    select menu_id into v_count from im_menus
    where label = ''reporting-finance-expenses'';
    IF v_count != 0 THEN return 0; END IF;

    v_menu := im_menu__new (
	null,					-- p_menu_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''intranet-reporting-finance'',		-- package_name
	''reporting-finance-expenses'',		-- label
	''Finance Expenses'',    		-- name
	''/intranet-reporting-finance/finance-expenses'', -- url
	70,					-- sort_order
	v_main_menu,				-- parent_menu_id
	null					-- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------
-- Finance - Payments
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

	v_count			integer;
BEGIN

    return 0;

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id
    into v_main_menu
    from im_menus
    where label=''reporting-finance'';

    select count(*) into v_count from im_menus 
    where label=''reporting-finance-payments'';
    if v_count = 1 then return 0; end if;

    v_menu := im_menu__new (
	null,					-- p_menu_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''intranet-reporting-finance'',		-- package_name
	''reporting-finance-payments'',		-- label
	''Finance Payments'',			-- name
	''/intranet-reporting-finance/finance-payments'', -- url
	60,					-- sort_order
	v_main_menu,				-- parent_menu_id
	null					-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------
-- Finance - Projects and its Financial Documents
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

	v_count			integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	select menu_id into v_main_menu from im_menus
	where label=''reporting-finance'';

	select count(*) into v_count from im_menus where label=''reporting-finance-projects-documents'';
	if v_count = 1 then return 0; end if;

	v_menu := im_menu__new (
		null,		-- p_menu_id
		''acs_object'',	-- object_type
		now(),		-- creation_date
		null,		-- creation_user
		null,		-- creation_ip
		null,		-- context_id
		''intranet-reporting'', -- package_name
		''reporting-finance-projects-documents'',	-- label
		''Finance Projects & Documents'',	-- name
		''/intranet-reporting/finance-projects-documents'', -- url
		50,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();







---------------------------------------------------------
-- Finance - Project's Providers
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
        v_main_menu             integer;

        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_customers             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
        v_reg_users             integer;

        v_count                 integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';

    select menu_id into v_main_menu from im_menus where label=''reporting-finance'';

    select count(*) into v_count from im_menus where label=''reporting-finance-projects-providers'';
    if v_count = 1 then return 0; end if;

    v_menu := im_menu__new (
        null,                                           -- p_menu_id
        ''acs_object'',                                 -- object_type
        now(),                                          -- creation_date
        null,                                           -- creation_user
        null,                                           -- creation_ip
        null,                                           -- context_id
        ''intranet-reporting-finance'',                 -- package_name
        ''reporting-finance-projects-providers'',       -- label
        ''Finance Project Providers'',                  -- name
        ''/intranet-reporting-finance/finance-projects-providers'', -- url
        70,                                             -- sort_order
        v_main_menu,                                    -- parent_menu_id
        null                                            -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
	v_senman		integer;
	v_accounting		integer;
	v_count			integer;
begin
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';

	select count(*) into v_count
	from im_menus where label = ''reporting-finance-expenses-cube'';
	IF v_count > 0 THEN return 0; END IF;

	select menu_id into v_admin_menu from im_menus where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-reporting-finance'',	-- package_name
		''reporting-finance-expenses-cube'',	-- label
		''Finance Expenses Cube'',		-- name
		''/intranet-reporting-finance/finance-expenses-cube?'', -- url
		130,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
	v_senman		integer;
	v_accounting		integer;
	v_count			integer;
begin
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';

	select count(*) into v_count
	from im_menus where label = ''reporting-finance-costs-monthly'';
	IF v_count > 0 THEN return 0; END IF;

	select menu_id into v_admin_menu from im_menus where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-finance'',		-- package_name
		''reporting-finance-costs-monthly'',	-- label
		''Finance Provider Costs per Month'',		-- name
		''/intranet-reporting-finance/finance-costs-monthly?'', -- url
		140,					-- sort_order
		v_admin_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();




