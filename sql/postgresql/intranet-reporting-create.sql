-- /package/intranet-reporting/sql/postgresql/intranet-reporting-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Invoices module for Project/Open
--
-- Defines:
--	im_reports		Report biz object container
--

---------------------------------------------------------
-- Reports
--
-- This data model supports the ]project-open[ reporting tool
-- to generate and store all type of reports.
--
-- There are two types of reports:
--	Reports defined in .tcl pages and associated with 
--	a menu item via the "label" of the menu item. 
-- and
--	Reports defined in im_reports
--
-- The permissions for both types of reports are determined
-- by the associated menu item.


-----------------------------------------------------------
-- Reports
--
-- Table for user-defined reports. Types:
--	- SQL Report - Simply show the result of an SQL statement via im_ad_hoc_query
--	- ... (more types of reports possibly in the future).


SELECT acs_object_type__create_type (
	'im_report',			-- object_type
	'Report',			-- pretty_name
	'Reports',			-- pretty_plural
	'acs_object',			-- supertype
	'im_reports',			-- table_name
	'report_id',			-- id_column
	'im_reports',			-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_report__name'		-- name_method
);


create table im_reports (
	report_id		integer
				constraint im_report_id_pk
				primary key
				constraint im_report_id_fk
				references acs_objects,
	report_name		varchar(1000),
	report_status_id	integer 
				constraint im_report_status_nn
				not null
				constraint im_report_status_fk
				references im_categories,
	report_type_id		integer 
				constraint im_report_type_nn
				not null
				constraint im_report_type_fk
				references im_categories,
	report_menu_id		integer
				constraint im_report_menu_id_fk
				references im_menus,
	report_sql		text
				constraint im_report_report_nn
				not null
);



-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_report__name(integer)
returns varchar as '
DECLARE
	p_report_id		alias for $1;
	v_name			varchar(2000);
BEGIN
	select	report_name
	into	v_name
	from	im_reports
	where	report_id = p_report_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_report__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, integer, integer, integer, text
) returns integer as '
DECLARE
	p_report_id		alias for $1;		-- report_id  default null
	p_object_type   	alias for $2;		-- object_type default ''im_report''
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_report_name		alias for $7;		-- report_name
	p_report_type_id	alias for $9;		
	p_report_status_id	alias for $10;
	p_report_menu_id	alias for $11;
	p_report_sql		alias for $12;

	v_report_id	integer;
BEGIN
	v_report_id := acs_object__new (
		p_report_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_reports (
		report_id, report_name,
		report_type_id, report_status_id,
		report_menu_id, report_sql
	) values (
		v_report_id, v_report_name,
		v_report_type_id, v_report_status_id,
		v_report_menu_id, v_report_sql
	);

	return v_report_id;
END;' language 'plpgsql';


create or replace function im_report__delete(integer)
returns integer as '
DECLARE
	p_report_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete from im_reports
	where	report_id = p_report_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_report_id);

	return 0;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Type and Status
--
-- Create categories for Reports type and status.
-- Status acutally is not use, so we just define "active"

-- Here are the ranges for the constants as defined in
-- /intranet-core/sql/common/intranet-categories.sql
--
-- Please contact support@project-open.com if you need to
-- reserve a range of constants for a new module.
--
-- 15000-15099  Intranet Report Status
-- 15100-15199  Intranet Report Type
-- 15200-15999	Reserved for Reporting


insert into im_categories(category_id, category, category_type) 
values (15000, 'Active', 'Intranet Report Status');
insert into im_categories(category_id, category, category_type) 
values (15002, 'Deleted', 'Intranet Report Status');


insert into im_categories(category_id, category, category_type) 
values (15100, 'Simple SQL Report', 'Intranet Report Type');


-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_report_status as
select	category_id as report_status_id, category as report_status
from	im_categories
where	category_type = 'Intranet Report Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_report_types as
select	category_id as report_type_id, category as report_type
from	im_categories
where	category_type = 'Intranet Report Type'
	and (enabled_p is null or enabled_p = 't');






---------------------------------------------------------
-- Report Menus
--

--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;
	v_reporting_menu 	integer;

	-- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_customers             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
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
    where label=''main'';

    v_reporting_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting'',          -- label
        ''Reporting'',          -- name
        ''/intranet-reporting/'', -- url
        150,                    -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_reporting_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_reporting_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_reporting_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_reporting_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_reporting_menu, v_employees, ''read'');

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-finance'', -- label
        ''Finance'',          -- name
        ''/intranet-reporting/'', -- url
        50,                     -- sort_order
        v_reporting_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');



    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-timesheet'', -- label
        ''Timesheet'',          -- name
        ''/intranet-reporting/'', -- url
        100,                     -- sort_order
        v_reporting_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-sales'', -- label
        ''Sales'',          -- name
        ''/intranet-reporting/'', -- url
        150,                     -- sort_order
        v_reporting_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');



    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-forum'',    -- label
        ''Forum'',              -- name
        ''/intranet-reporting/'', -- url
        200,                    -- sort_order
        v_reporting_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-other'', -- label
        ''Other'',          -- name
        ''/intranet-reporting/'', -- url
        250,                     -- sort_order
        v_reporting_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');


    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Timesheet Reports
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;

	-- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_customers             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
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
    where label=''reporting-timesheet'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-timesheet-productivity'',          -- label
        ''Timesheet Productivity'',          -- name
        ''/intranet-reporting/timesheet-productivity?'', -- url
        50,                    -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-timesheet-customer-project'', -- label
        ''Timesheet Customers and Projects'',          -- name
        ''/intranet-reporting/timesheet-customer-project?'', -- url
        100,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------
-- Users-Contacts
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
	where label=''reporting-other'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting'',		-- package_name
		''reporting-user-contacts'', -- label
		''Users & Contact Information'', -- name
		''/intranet-reporting/user-contacts?'', -- url
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
-- Timesheet Finance
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
	where label=''reporting-timesheet'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting'',		-- package_name
		''reporting-timesheet-finance'', -- label
		''Timesheet Project Hierarchy & Finance'', -- name
		''/intranet-reporting/timesheet-finance?'', -- url
		5,					-- sort_order
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


