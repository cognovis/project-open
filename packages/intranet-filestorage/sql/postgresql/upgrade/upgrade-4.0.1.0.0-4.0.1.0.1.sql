-- upgrade-4.0.1.0.0-4.0.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-filestorage/sql/postgresql/upgrade/upgrade-4.0.1.0.0-4.0.1.0.1.sql','');

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Expense Bundle Filestorage',		-- plugin_name
	'intranet-filestorage',			-- package_name
	'bottom',				-- location
	'/intranet-expenses/bundle-new',	-- page_url
	null,					-- view_name
	30,					-- sort_order
	'im_filestorage_cost_component $user_id $bundle_id $bundle_name $return_url' -- component_tcl
);

