-- upgrade-4.0.3.5.1-4.0.3.5.2.sql

SELECT acs_log__debug('/packages/intranet-filestorage/sql/postgresql/upgrade/upgrade-4.0.3.5.1-4.0.3.5.2.sql','');

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Conf Item Filestorage',		-- plugin_name
	'intranet-filestorage',			-- package_name
	'bottom',				-- location
	'/intranet-confdb/new',			-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_filestorage_conf_item_component $current_user_id $conf_item_id "" $return_url' -- component_tcl
);

