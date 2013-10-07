-- upgrade-4.0.5.0.0-4.0.5.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.5.0.0-4.0.5.0.1.sql','');


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Ticket Component',	-- plugin_name - shown in menu
	'intranet-helpdesk',		-- package_name
	'left',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	20,				-- sort_order
	'im_helpdesk_project_component -project_id $project_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Project Ticket Component' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-----------------------------------------------------------
-- Home Personal Tickets
-----------------------------------------------------------

delete from im_view_columns where view_id = 273;
delete from im_views where view_id = 273;
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (273, 'ticket_project_list', 'view_tickets', 1400);

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27300,273,00, 'Prio','"$ticket_prio"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27310,273,10, 'Nr','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_nr</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27320,273,20,'Name','"<a href=/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id>$project_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27330,273,30,'Contact','"<a href=/intranet/users/view?user_id=$ticket_customer_contact_id>$ticket_customer_contact_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27340,273,40,'Assignee','"<a href=/intranet/users/view?user_id=$ticket_assignee_id>$ticket_assignee_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27380,273,80,'Type','$ticket_type');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27390,273,90,'Status','$ticket_status');



