-- upgrade-3.3.1.0.0-3.3.1.1.0.sql

SELECT acs_log__debug('/packages/intranet-reporting-cubes/sql/postgresql/upgrade/upgrade-3.3.1.0.0-3.3.1.1.0.sql','');


---------------------------------------------------------
-- Price Cube
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
	from im_menus
	where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-cubes'',		-- package_name
		''reporting-cubes-price'',		-- label
		''Price Data-Warehouse Cube'',		-- name
		''/intranet-reporting-cubes/price-cube?'', -- url
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
-- Object Audit Cube
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
	from im_menus
	where label=''reporting-other'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-cubes'',		-- package_name
		''reporting-cube-object-audit'',	-- label
		''Object Creation Audit Cube'',		-- name
		''/intranet-reporting-cubes/object-audit-cube?'', -- url
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






----------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count                 integer;
BEGIN
        select	count(*) into v_count
        from	user_tab_columns
        where   lower(table_name) = ''im_reporting_cubes'';
        IF v_count > 0 THEN return 0; END IF;

	-- A cube is completely defined by the cube name
	-- (timesheet, finance, ...) and the top and left variables.
	create sequence im_reporting_cubes_seq;
	create table im_reporting_cubes (
		cube_id			integer
					constraint im_reporting_dw_cache_pk
					primary key,
	
		cube_name		varchar(1000) not null,
		cube_params		varchar(4000),
		cube_top_vars		varchar(4000),
		cube_left_vars		varchar(4000),
	
		-- How frequently should the cube be updated?
		cube_update_interval	interval default ''1 day'',
	
		-- Counter to determine usage frequency
		cube_usage_counter	integer default 0
	);


	-- Represents a mapping from cube to cube values.
	-- This cache should be cleaned up after 1 day to 1 month..
	create sequence im_reporting_cube_values_seq;
	create table im_reporting_cube_values (
		value_id		integer
					constraint im_reporting_cube_values_pk
					primary key,
	
		cube_id			integer
					constraint im_reporting_cube_values_cube_fk
					references im_reporting_cubes,
	
		-- When was this cube evaluated
		evaluation_date		timestamptz,
	
		-- TCL representation because of the high number of entries.
		value_top_scale		text,
		value_left_scale	text,
		value_hash_array	text
	);

        return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



-- ------------------------------------------------
-- Add a ? to the end of the reports to pass-on parameters
update im_menus set url = url || '?'
where url = '/intranet-reporting-cubes/timesheet-cube';




-- ------------------------------------------------
-- Return the Cost Center code

create or replace function im_dept_from_user_id(integer)
returns varchar as '
DECLARE
        v_user_id       alias for $1;
        v_dept          varchar;
BEGIN
        select  cost_center_code into v_dept
        from    im_employees e,
                im_cost_centers cc
        where   e.employee_id = v_user_id
                and e.department_id = cc.cost_center_id;

        return v_dept;
END;' language 'plpgsql';
select im_dept_from_user_id(624);




