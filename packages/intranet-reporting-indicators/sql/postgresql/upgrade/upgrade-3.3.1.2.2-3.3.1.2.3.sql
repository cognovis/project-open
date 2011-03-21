-- upgrade-3.3.1.2.2-3.3.1.2.3.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.3.1.2.2-3.3.1.2.3.sql','');

\i upgrade-3.0.0.0.first.sql


select im_component_plugin__new (
		null,					-- plugin_id
		'im_menu',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creattion_ip
		null,					-- context_id
	
		'Home Indicator Component',		-- plugin_name
		'intranet-reporting-indicators',	-- package_name
		'right',				-- location
		'/intranet/index',			-- page_url
		null,					-- view_name
		50,					-- sort_order
		'im_indicator_home_page_component',
		'lang::message::lookup {} intranet-reporting-indicators.Home_Indicator_Component {Home Indicator Component}'
);

select im_grant_permission (
	(select plugin_id from im_component_plugins where plugin_name = 'Home Indicator Component'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

