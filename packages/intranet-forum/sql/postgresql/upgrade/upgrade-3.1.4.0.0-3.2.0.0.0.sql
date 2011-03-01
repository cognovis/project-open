-- upgrade-3.1.4.0.0-3.2.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-forum/sql/postgresql/upgrade/upgrade-3.1.4.0.0-3.2.0.0.0.sql','');


-- Fix a HTML rendering issue in the component definition
--



create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_component_plugin_user_map'';
	if v_count = 0 then return 0; end if;

	DELETE from im_component_plugin_user_map;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


DELETE from im_component_plugins
WHERE plugin_name = 'Project Forum Component';

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Forum Component',	-- plugin_name
	'intranet-forum',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_forum_component -user_id $user_id -forum_object_id $project_id -current_page_url $current_url -return_url $return_url -forum_type "project" -export_var_list [list project_id forum_start_idx forum_order_by forum_how_many forum_view_name] -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -start_idx [im_opt_val forum_start_idx] -restrict_to_mine_p "f" -restrict_to_new_topics 0','im_forum_create_bar "<B><nobr>[_ intranet-forum.Forum_Items]</nobr></B>" $project_id $return_url');

