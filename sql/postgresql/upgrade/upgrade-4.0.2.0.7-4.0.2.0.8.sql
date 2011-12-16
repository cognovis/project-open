-- upgrade-4.0.2.0.7-4.0.2.0.8.sql

SELECT acs_log__debug('/packages/intranet-sla-management/sql/postgresql/upgrade/upgrade-4.0.2.0.7-4.0.2.0.8.sql','');



-----------------------------------------------------------
-- Menu for Resolution Time Report
--

SELECT im_menu__new (
	null,					-- p_menu_id
	'im_menu',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'intranet-sla-management',		-- package_name
	'helpdesk_sla_resolution_time',		-- label
	'Resolution Time',			-- name
	'/intranet-sla-management/reports/sla-resolution-time',	-- url
	50,					-- sort_order
	(select menu_id from im_menus where label = 'reporting-tickets'),
	null					-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'helpdesk_sla_resolution_time'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



-- Fix data type for float attribute
update acs_attributes set datatype = 'float' where attribute_name = 'ticket_resolution_time';

