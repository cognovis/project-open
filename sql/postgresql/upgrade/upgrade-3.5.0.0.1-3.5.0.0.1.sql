-- upgrade-3.5.0.0.1-3.5.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.5.0.0.1-3.5.0.0.1.sql','');


-----------------------------------------------------------
-- "Tickets" Section for reports
--

SELECT im_menu__new (
	null,				-- p_menu_id
	'im_menu',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'intranet-helpdesk',		-- package_name
	'reporting-tickets',		-- label
	'Tickets',			-- name
	'/intranet-helpdesk/index',	-- url
	100,				-- sort_order
	(select menu_id from im_menus where label = 'reporting'),
	null				-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'reporting-tickets'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

