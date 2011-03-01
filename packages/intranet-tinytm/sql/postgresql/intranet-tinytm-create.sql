-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-create.sql
--
-- Copyright (c) 2008 ]project-open[
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- Please see the GNU General Public License for more details.
--
-- @author      frank.bergmann@project-open.com


-----------------------------------------------------------------------------------------------------
-- TinyTM
-----------------------------------------------------------------------------------------------------
--
-- This is the ]project-open[ main TinyTM installation script.
--
--
-- TinyTM is a small but powerful open-source translation memory.
-- Please see http://tinytm.sourceforge.net/ for details.
--
-- There are two modes of installing TinyTM:
--
--	1. "Standalone":
--	   After installing a PostgreSQL 8.1 or 8.2 database,
--	   you just execute this script. You will get a working
--	   TinyTM installation. However, there are no maintenance
--	   screens available to add and delete users, etc.
--	   So you need to use pgAdminIII in maintain data.
--
--	2. Integrated with ]project-open[
--	   ]project-open[ already brings the "infrastructure"
--	   to create and delete users, groups, memberships, etc.
--	   Also, TinyTM will soon be integrated with ]po[ in order
--	   to create an integrated translation workflow environment
--	   comparable to products from SDL/Trados and Across.
--
--
-- TinyTM consists of the following objects:
--
--	Users	- Physical persons that logon to TinyTM
--	Groups	- Groups of persons, including companies & depts.
--	Segment	- Translation segments
--	Tags	- Light-weight semantic markup
--


-- Create the data model (tables, views, ...)
\i tinytm-create-projectopen.sql

-- Create API (Application Programming Interface) procedures
\i tinytm-create-procedures.sql

-- Import some sample user
\i tinytm-create-demodata.sql




-----------------------------------------------------------------------------------------------------
-- Create a TinyTM menu
-----------------------------------------------------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
declare
	v_menu				integer;
	v_main_menu			integer;
	v_employees			integer;
	v_accounting			integer;
	v_senman			integer;
	v_companies			integer;
	v_freelancers			integer;
	v_proman			integer;
	v_admins			integer;
	v_reg_users			integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_companies from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	select menu_id into v_main_menu from im_menus where label=''main'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-tinytm'',		-- package_name
		''tinytm'',			-- label
		''TinyTM'',			-- name
		''/intranet-tinytm/'',		-- url
		14,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

