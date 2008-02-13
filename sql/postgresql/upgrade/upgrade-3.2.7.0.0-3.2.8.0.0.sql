
create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count                 integer;
BEGIN
        select count(*) into v_count from im_component_plugins
        where  plugin_name = ''Bug List Component'';
        IF v_count > 0 THEN return 0; END IF;

	PERFORM im_component_plugin__new (
	        null,                           -- plugin_id
	        ''acs_object'',                   -- object_type
	        now(),                          -- creation_date
	        null,                           -- creation_user
	        null,                           -- creation_ip
	        null,                           -- context_id
	        ''Bug List Component'',		-- plugin_name
	        ''intranet-bug-tracker'',		-- package_name
	        ''left'',				-- location
	        ''/intranet/projects/view'',	-- page_url
	        null,                           -- view_name
	        22,                             -- sort_order
		''im_bug_tracker_list_component $project_id'',
		''lang::message::lookup "" intranet-bug-tracker.Bug_Tracker_Component "Bug Tracker Component"''
	);

        return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count                 integer;
BEGIN
        select count(*) into v_count
        from user_tab_columns
        where   lower(table_name) = ''bt_bugs''
                and lower(column_name) = ''bug_container_project_id'';
        IF v_count > 0 THEN return 0; END IF;

	alter table bt_bugs add bug_container_project_id integer references im_projects;

        return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


