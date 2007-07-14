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
-- Components
----------------------------------------------------


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




-- Project Status Histogram
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Home Project Queue',		-- plugin_name
	'intranet-reporting-dashboard',	-- package_name
	'left',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	110,				-- sort_order
	'im_dashboard_active_projects_status_histogram',
	'lang::message::lookup "" intranet-reporting-dashboard.Project_Queue "Project Queue"'
);




