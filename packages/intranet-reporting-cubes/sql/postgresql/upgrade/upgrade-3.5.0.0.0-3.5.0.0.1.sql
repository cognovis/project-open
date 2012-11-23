SELECT acs_log__debug('/packages/intranet-reporting-cubes/sql/postgresql/upgrade/upgrade-3.5.0.0.0-3.5.0.0.1.sql','');


select im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-reporting-cubes',			-- package_name
	'reporting-cubes-ticket',			-- label
	'Ticket Cube',					-- name
	'/intranet-reporting-cubes/ticket-cube?',	-- url
	220,						-- sort_order
	(select menu_id from im_menus where label = 'reporting-ticket'),
	null						-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'reporting-cubes-ticket'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);

