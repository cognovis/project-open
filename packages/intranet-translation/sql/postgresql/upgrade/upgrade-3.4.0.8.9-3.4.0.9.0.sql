-- upgrade-3.4.0.8.9-3.4.0.9.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.8.9-3.4.0.9.0.sql','');

select im_component_plugin__new (
        null,                                   	-- plugin_id
        'acs_object',                           	-- object_type
        now(),                                  	-- creation_date
        null,                                   	-- creation_user
        null,                                   	-- creattion_ip
        null,                                   	-- context_id

        'Timesheet Task Component (AJAXed)',      		-- plugin_name
        'intranet-translation', 			-- package_name
        'top',        	                        	-- location
        '/intranet-translation/trans-tasks/task-list',  -- page_url
        null,                                   	-- view_name
        10,                                     	-- sort_order
        'im_translation_task_ajax_component'
);


