-- /packages/intranet-reporting-dashboard/sql/oracle/intranet-reporting-dashboard-create.sql
--
-- ]project[ Dashboard Module
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com


---------------------------------------------------------
-- Dashboard page
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
	where label=''main'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-dashboard'',	-- package_name
		''dashboard'',				-- label
		''Dashboard'',				-- name
		''/intranet-reporting-dashboard/index'', -- url
		151,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



----------------------------------------------------
-- Components
----------------------------------------------------


-- All Time Top Customers
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Home All-Time Top Customers',		-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'left',					-- location
	'/intranet/index',			-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_dashboard_all_time_top_customers_component',
	'lang::message::lookup "" intranet-reporting-dashboard.All_Time_Top_Customers "All-Time Top Customers"'
);



-- All Time Top Customers
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Home All-Time Top Services',		-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'left',					-- location
	'/intranet/index',			-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_dashboard_generic_component -component "generic" -left_vars "sub_project_type"',
	'lang::message::lookup "" intranet-reporting-dashboard.All_Time_Top_Services "All-Time Top Services"'
);




-- Project Status Histogram
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Home Project Queue',			-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'left',					-- location
	'/intranet/index',			-- page_url
	null,					-- view_name
	110,					-- sort_order
	'im_dashboard_active_projects_status_histogram',
	'lang::message::lookup "" intranet-reporting-dashboard.Project_Queue "Project Queue"'
);


-- Project Status Histogram
--
SELECT im_component_plugin__new (
        null,                                   -- plugin_id
        'im_component_plugin',                  -- object_type
        now(),                                  -- creation_date
        null,                                   -- creation_user
        null,                                   -- creation_ip
        null,                                   -- context_id
        'Project Queue',                        -- plugin_name
        'intranet-reporting-dashboard',         -- package_name
        'right',                                -- location
        '/intranet-cost/index',                 -- page_url
        null,                                   -- view_name
        40,                                     -- sort_order
        'im_dashboard_active_projects_status_histogram',
        'lang::message::lookup "" intranet-reporting-dashboard.Project_Queue "Project Queue"'
);


-- Tickets Histograms
--

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Ticket Status',			-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet-helpdesk/index',		-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 200 -name "Ticket per Ticket Status" -sql "
		select	im_category_from_id(ticket_status_id) as ticket_status,
		        count(*) as cnt
		from	im_tickets t
		where	t.ticket_status_id not in (select * from im_sub_categories(30097))
		group by ticket_status_id
		order by ticket_status
	"',
	'lang::message::lookup "" intranet-reporting-dashboard.Tickets_per_Ticket_Status "Status"'
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Ticket Type',				-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet-helpdesk/index',		-- page_url
	null,					-- view_name
	120,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 200 -name "Ticket per Ticket Type" -sql "
		select	im_category_from_id(ticket_type_id) as ticket_type,
		        count(*) as cnt
		from	im_tickets t
		where	t.ticket_status_id in (select * from im_sub_categories(30000))
		group by ticket_type_id
		order by ticket_type
	"',
	'lang::message::lookup "" intranet-reporting-dashboard.Tickets_per_Ticket_Type "Ticket Type"'
);



SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Ticket Owner',				-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet-helpdesk/index',		-- page_url
	null,					-- view_name
	140,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 200 -name "Tickets per Ticket Owner" -sql "
		select	im_name_from_user_id(creation_user) as creation_user_name,
		        count(*) as cnt
		from	im_tickets t,
			acs_objects o
		where	t.ticket_id = o.object_id and
			t.ticket_status_id not in (select * from im_sub_categories(30097))
		group by creation_user
		order by creation_user_name
	"',
	'lang::message::lookup "" intranet-reporting-dashboard.Tickets_per_Ticket_Owner "Owner"'
);



-- Project Histograms
--

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Projects by Status',			-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 200 -sql "
		select	im_category_from_id(p.project_status_id) as project_status,
		        count(*) as cnt
		from	im_projects p
		where	p.project_status_id not in (select * from im_sub_categories(81))
		group by project_status_id
		order by project_status
	"',
	'lang::message::lookup "" intranet-reporting-dashboard.Sales_Pipeline "Sales Pipeline"'
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Pre-Sales Queue',			-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 200 -sql "
		select	im_category_from_id(p.project_status_id) as project_status,
		        sum(coalesce(presales_probability,project_budget,0) * coalesce(presales_value,0)) as value
		from	im_projects p
		where	p.project_status_id not in (select * from im_sub_categories(81))
		group by project_status_id
		order by project_status
	"',
	'lang::message::lookup "" intranet-reporting-dashboard.Sales_Pipeline "Sales<br>Pipeline"'
);

