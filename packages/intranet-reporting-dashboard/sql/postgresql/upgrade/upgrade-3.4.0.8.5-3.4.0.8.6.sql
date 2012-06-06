--  upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-reporting-dashboard/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');


----------------------------------------------------
-- Components
----------------------------------------------------


-- All Time Top Customers
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Home All-Time Top Customers',		-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet/index',			-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_dashboard_all_time_top_customers_component',
	'lang::message::lookup "" intranet-reporting-dashboard.All_Time_Top_Customers "All-Time Top Customers"'
);



-- Project Status Histogram
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',				-- object_type
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


-- Tickets Histograms
--

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',				-- object_type
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
	'im_component_plugin',				-- object_type
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
	'im_component_plugin',				-- object_type
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


