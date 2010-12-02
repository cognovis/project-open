SELECT acs_log__debug('/packages/intranet-simple-survey/sql/postgresql/upgrade/upgrade-3.5.0.0.0-3.5.0.0.1.sql','');


select im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-simple-survey',			-- package_name
	'reporting-simple-survey',			-- label
	'Simple Surveys',				-- name
	'/intranet-simple-survey/index?',		-- url
	270,						-- sort_order
	(select menu_id from im_menus where label = 'reporting'),
	null						-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'reporting-simple-survey'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


update im_menus
set parent_menu_id = (select menu_id from im_menus where label = 'reporting-simple-survey')
where label like '%survsimp%';

