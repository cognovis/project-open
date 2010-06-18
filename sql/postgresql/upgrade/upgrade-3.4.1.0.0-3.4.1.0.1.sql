-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-reporting-dashboard/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');


----------------------------------------------------
-- Components
----------------------------------------------------

-- Project EVA
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	'0.0.0.0',				-- creation_ip
	null,					-- context_id
	'Earned Value',				-- plugin_name
	'intranet-reporting-dashboard',		-- package_name
	'right',				-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	200,					-- sort_order
	'im_dashboard_project_eva -project_id $project_id',
	'lang::message::lookup "" intranet-reporting-dashboard.Earned_Value "Earned Value"'
);

