--  upgrade-3.5.9.9.9-4.0.0.8.0.sql

SELECT acs_log__debug('/packages/intranet-reporting-dashboard/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.8.0.sql','');


-- Project Status Histogram
--
SELECT im_component_plugin__new (
        null,                                   -- plugin_id
        'im_component_plugin',                  -- object_type
        now(),                                  -- creation_date
        null,                                   -- creation_user
        null,                                   -- creation_ip
        null,                                   -- context_id
        'Project Queue',                        -- plugin_name
        'intranet-reporting-dashboard',         -- package_name
        'right',                                -- location
        '/intranet-cost/index',                 -- page_url
        null,                                   -- view_name
        40,                                     -- sort_order
        'im_dashboard_active_projects_status_histogram',
        'lang::message::lookup "" intranet-reporting-dashboard.Project_Queue "Project Queue"'
);

