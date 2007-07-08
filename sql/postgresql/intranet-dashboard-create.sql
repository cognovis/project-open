-- /packages/intranet-hr/sql/oracle/intranet-hr-create.sql
--
-- ]project[ Dashboard Module
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com

----------------------------------------------------
-- Aggregated im_costs view

-- create or replace view im_costs_aggreg as
-- select	*,
-- 	CASE 
-- 	    WHEN cost_type_id in (3700, 3702) THEN 1
-- 	    WHEN cost_type_id in (3704, 3706, 3712, 3718) THEN -1
-- 	    ELSE 0
-- 	END as signum,
-- 	to_date(to_char(effective_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') + payment_days as due_date,
-- 	to_char(to_date(to_char(effective_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') + payment_days, 'YYYY-MM') as due_month
-- from	im_costs
-- where	cost_status_id not in (3812)	-- not in deleted
-- ;


----------------------------------------------------
-- A cube is completely defined by the cube name
-- (timesheet, finance, ...) and the top and left variables.

create sequence im_reporting_cubes_seq;
create table im_reporting_cubes (
	cube_id			integer
				constraint im_reporting_dw_cache_pk
				primary key,

	cube_name		varchar(1000) not null,
	cube_top_vars		varchar(4000),
	cube_left_vars		varchar(4000),

	-- How frequently should the cube be updated?
	cube_update_interval	interval default '1 day',

	-- Counter to determine usage frequency
	cube_usage_counter	integer default 0
);



----------------------------------------------------
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




----------------------------------------------------
-- Components


-- All Time Top Customers
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Home All-Time Top Customers',	-- plugin_name
	'intranet-reporting-dashboard',	-- package_name
	'left',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_dashboard_all_time_top_customers_component',
	'lang::message::lookup "" intranet-reporting-dashboard.All_Time_Top_Customers "All-Time Top Customers"'
);



-- All Time Top Customers
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Home All-Time Top Services',	-- plugin_name
	'intranet-reporting-dashboard',	-- package_name
	'left',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_dashboard_generic_component -component "generic" -left_vars "sub_project_type"',
	'lang::message::lookup "" intranet-reporting-dashboard.All_Time_Top_Services "All-Time Top Services"'
);


