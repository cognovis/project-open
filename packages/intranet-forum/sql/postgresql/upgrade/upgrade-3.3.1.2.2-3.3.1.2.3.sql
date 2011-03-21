-- upgrade-3.3.1.2.2-3.3.1.2.3.sql

SELECT acs_log__debug('/packages/intranet-forum/sql/postgresql/upgrade/upgrade-3.3.1.2.2-3.3.1.2.3.sql','');


-----------------------------------------------------------
-- Add a forum component to replace the deleted hardcoded forum

-- Show the forum component in user page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'User Forum Component',		-- plugin_name
	'intranet-forum',		-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	40,				-- sort_order
	'im_forum_component -user_id $user_id -forum_object_id $user_id -current_page_url $current_url -return_url $return_url -export_var_list [list company_id forum_start_idx forum_order_by forum_how_many forum_view_name ] -forum_type company -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -restrict_to_mine_p "f" -restrict_to_new_topics 0',
	'im_forum_create_bar "<B>[_ intranet-forum.Forum_Items]<B>" $user_id $return_url'
);

