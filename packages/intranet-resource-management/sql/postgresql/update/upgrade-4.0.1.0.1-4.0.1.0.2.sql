-- upgrade-4.0.1.0.1-4.0.1.0.2.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.1.0.1-4.0.1.0.2.sql','');

SELECT im_menu__new (
        null,                                           -- p_menu_id
        'im_menu',                                      -- object_type
        now(),                                          -- creation_date
        null,                                           -- creation_user
        null,                                           -- creation_ip
        null,                                           -- context_id
        'intranet-resource-management',                 -- package_name
        'resource_planning-planned-hours',                   -- label
        'Resource Planning based on Planned Hours',         -- name
        '/intranet-resource-management/resources-planning-planned-hours', -- url
        0,                                              -- sort_order
        (select menu_id from im_menus where label = 'reporting-pm'),
        null                                            -- p_visible_tcl
);
