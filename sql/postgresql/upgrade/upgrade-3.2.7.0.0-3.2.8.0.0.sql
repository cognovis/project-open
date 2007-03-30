
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Bug List Component',		-- plugin_name
        'intranet-bug-tracker',		-- package_name
        'left',				-- location
        '/intranet/projects/view',	-- page_url
        null,                           -- view_name
        22,                             -- sort_order
	'im_bug_tracker_list_component $project_id',
	'lang::message::lookup "" intranet-bug-tracker.Bug_Tracker_Component "Bug Tracker Component"'
);


