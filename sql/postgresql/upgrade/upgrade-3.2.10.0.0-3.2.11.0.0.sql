-- upgrade-3.2.10.0.0-3.2.11.0.0.sql



----------------------------------------------------
-- Add tables (if not already there).

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

