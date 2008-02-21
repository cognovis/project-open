-- /packages/intranet-helpdesk/sql/postgresql/intranet-helpdesk-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Helpdesk


SELECT acs_object_type__create_type (
	'im_ticket',			-- object_type
	'Ticket',			-- pretty_name
	'Ticket',			-- pretty_plural
	'im_project',			-- supertype
	'im_tickets',			-- table_name
	'ticket_id',			-- id_column
	'intranet-helpdesk',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_ticket__name'		-- name_method
);

insert into acs_object_type_tables VALUES ('im_ticket', 'im_tickets', 'ticket_id');

update acs_object_types set
        status_type_table = 'im_tickets',
        status_column = 'ticket_status_id',
        type_column = 'ticket_type_id'
where object_type = 'im_ticket';


create sequence im_ticket_seq;

create table im_tickets (
	ticket_id			integer
					constraint im_ticket_id_pk
					primary key
					constraint im_ticket_id_fk
					references im_projects,
	ticket_status_id		integer 
					constraint im_ticket_status_nn
					not null
					constraint im_ticket_status_fk
					references im_categories,
	ticket_type_id			integer
					constraint im_ticket_type_nn
					not null
					constraint im_ticket_type_fk
					references im_categories,
	ticket_prio_id			integer
					constraint im_ticket_prio_fk
					references persons,
	ticket_customer_contact_id	integer
					constraint im_ticket_customr_contact_fk
					references persons,
	ticket_assignee_id		integer
					constraint im_ticket_assignee_fk
					references persons,
	ticket_sla_id			integer
					constraint im_ticket_sla_fk
					references acs_objects,
	ticket_dept_id			integer
					constraint im_ticket_dept_fk
					references im_cost_centers,
	ticket_service_id		integer
					constraint im_ticket_service_fk
					references im_categories,
	ticket_hardware_id		integer
					constraint im_ticket_hardware_fk
					references acs_objects,
	ticket_application_id		integer
					constraint im_ticket_application_fk
					references acs_objects,
	ticket_queue_id			integer
					constraint im_ticket_queue_fk
					references im_categories,
	ticket_alarm_date		timestamptz,
	ticket_alarm_action		text,
	ticket_note			text
);


-----------------------------------------------------------
-- Permissions & Privileges
-----------------------------------------------------------

select acs_privilege__create_privilege('view_tickets_all','View all Conf Items','');
select acs_privilege__add_child('admin', 'view_tickets_all');

select acs_privilege__create_privilege('add_tickets','Add new Conf Items','');
select acs_privilege__add_child('admin', 'add_tickets');

select im_priv_create('view_tickets_all', 'P/O Admins');
select im_priv_create('view_tickets_all', 'Senior Managers');
select im_priv_create('view_tickets_all', 'Project Managers');
select im_priv_create('view_tickets_all', 'Employees');

select im_priv_create('add_tickets', 'P/O Admins');
select im_priv_create('add_tickets', 'Senior Managers');
select im_priv_create('add_tickets', 'Project Managers');
select im_priv_create('add_tickets', 'Employees');




-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_ticket__name(integer)
returns varchar as '
DECLARE
	p_ticket_id		alias for $1;
	v_name			varchar;
BEGIN
	select	project_name into v_name from im_projects
	where	project_id = p_ticket_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_ticket__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer,
	integer, integer 
) returns integer as '
DECLARE
	p_ticket_id		alias for $1;		-- ticket_id  default null
	p_object_type   	alias for $2;		-- object_type default ''im_ticket''
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_ticket_name		alias for $7;		-- ticket_name
	p_ticket_customer_id	alias for $8;
	p_ticket_type_id	alias for $9;		
	p_ticket_status_id	alias for $10;

	v_ticket_id		integer;
	v_ticket_nr		integer;
BEGIN
	select nextval(''im_ticket_seq'') into v_ticket_nr;

	v_ticket_id := im_project__new (
		p_ticket_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id

		p_ticket_name,
		v_ticket_nr::varchar,
		v_ticket_nr::varchar,
		null,			-- parent_id
		p_ticket_customer_id,
		p_ticket_type_id,
		p_ticket_status_id	
	);

	insert into im_tickets (
		ticket_id, ticket_status_id, ticket_type_id
	) values (
		v_ticket_id, p_ticket_status_id, p_ticket_type_id
	);

	return v_ticket_id;
END;' language 'plpgsql';


create or replace function im_ticket__delete(integer)
returns integer as '
DECLARE
	p_ticket_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete from im_tickets
	where	ticket_id = p_ticket_id;

	-- Finally delete the object iself
	PERFORM im_project__delete(p_ticket_id);

	return 0;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Type and Status
--
-- Create categories for Helpdesk type and status.
-- Status acutally is not use, so we just define "active"

-- Here are the ranges for the constants as defined in
-- /intranet-core/sql/common/intranet-categories.sql
--
-- Please contact support@project-open.com if you need to
-- reserve a range of constants for a new module.
--
-- 30000-39999  Intranet Helpdesk (10000)
--
-- 30000-30099  Intranet Ticket Status (100)
-- 30100-30199  Intranet Ticket Type (100)
-- 30200-30299  Intranet Ticket User Priority (100)
-- 30300-30399  Intranet Ticket Technical Priority (100)
-- 30400-30499	Intranet Service Catalog
-- 31000-31999	Intranet Ticket Class (1000)
-- 32000-32999	reserved (1000)
-- 33000-33999	reserved (1000)
-- 34000-34999	reserved (1000)
-- 35000-39999  reserved (5000)


-- new ticket type for helpdesk
im_category_new(101, 'Ticket', 'Intranet Project Type');




-- 30100-30199	Intranet Ticket Type
--
SELECT im_category_new(30102, 'Purchasing request', 'Intranet Ticket Type');
SELECT im_category_new(30104, 'Workplace move request', 'Intranet Ticket Type');
SELECT im_category_new(30106, 'Telephony request', 'Intranet Ticket Type');
SELECT im_category_new(30108, 'Project request', 'Intranet Ticket Type');
SELECT im_category_new(30110, 'Bug request', 'Intranet Ticket Type');
SELECT im_category_new(30112, 'Report request', 'Intranet Ticket Type');
SELECT im_category_new(30114, 'Permission request', 'Intranet Ticket Type');
SELECT im_category_new(30116, 'Feature request', 'Intranet Ticket Type');
SELECT im_category_new(30118, 'Training request', 'Intranet Ticket Type');



-- 30000-30099	Intranet Ticket Status
--
-- High-Level States
SELECT im_category_new(30000, 'Open', 'Intranet Ticket Status');
SELECT im_category_new(30001, 'Closed', 'Intranet Ticket Status');
-- Wtates
SELECT im_category_new(30010, 'In review', 'Intranet Ticket Status');
SELECT im_category_new(30011, 'Assigned', 'Intranet Ticket Status');
SELECT im_category_new(30012, 'Customer review', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30010, 30000);
SELECT im_category_hierarchy_new(30011, 30000);
SELECT im_category_hierarchy_new(30012, 30000);
-- Closed States
SELECT im_category_new(30090, 'Duplicate', 'Intranet Ticket Status');
SELECT im_category_new(30091, 'Invalid', 'Intranet Ticket Status');
SELECT im_category_new(30092, 'Outdated', 'Intranet Ticket Status');
SELECT im_category_new(30093, 'Rejected', 'Intranet Ticket Status');
SELECT im_category_new(30094, 'Won''t fix', 'Intranet Ticket Status');
SELECT im_category_new(30095, 'Can''t reproduce', 'Intranet Ticket Status');
SELECT im_category_new(30096, 'Resolved', 'Intranet Ticket Status');
SELECT im_category_new(30097, 'Deleted', 'Intranet Ticket Status');
SELECT im_category_new(30098, 'Canceled', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30090, 30001);
SELECT im_category_hierarchy_new(30091, 30001);
SELECT im_category_hierarchy_new(30092, 30001);
SELECT im_category_hierarchy_new(30093, 30001);
SELECT im_category_hierarchy_new(30094, 30001);
SELECT im_category_hierarchy_new(30095, 30001);
SELECT im_category_hierarchy_new(30096, 30001);
SELECT im_category_hierarchy_new(30097, 30001);
SELECT im_category_hierarchy_new(30098, 30001);


-- 30400-30499	Intranet Service Catalog
SELECT im_category_new(30400, 'End user support', 'Intranet Service Catalog');
SELECT im_category_new(30420, 'System administrator support', 'Intranet Service Catalog');
SELECT im_category_new(30410, 'Hosting service', 'Intranet Service Catalog');
SELECT im_category_new(30430, 'Software update service', 'Intranet Service Catalog');



-- 35000-35099	1st level of Intranet Ticket Class
SELECT im_category_new(31000, 'Broken system or configuration', 'Intranet Ticket Class');

	SELECT im_category_new(31001, 'Bug/error in application', 'Intranet Ticket Class');
	SELECT im_category_new(31002, 'Network access to application unavailable or slow', 'Intranet Ticket Class');
	SELECT im_category_new(31003, 'Performance issues with application', 'Intranet Ticket Class');
	SELECT im_category_new(31005, 'Browser issue: Information is rendered incorrectly', 'Intranet Ticket Class');
	SELECT im_category_new(31006, 'Report does not show expected data', 'Intranet Ticket Class');
	SELECT im_category_new(31008, 'Security issue', 'Intranet Ticket Class');
	SELECT im_category_new(31009, 'Issues with backup & recovery', 'Intranet Ticket Class');
	SELECT im_category_hierarchy_new(31001, 31000);
	SELECT im_category_hierarchy_new(31002, 31000);
	SELECT im_category_hierarchy_new(31003, 31000);
	SELECT im_category_hierarchy_new(31005, 31000);
	SELECT im_category_hierarchy_new(31006, 31000);
	SELECT im_category_hierarchy_new(31008, 31000);
	SELECT im_category_hierarchy_new(31009, 31000);

SELECT im_category_new(31100, 'Invalid data in system', 'Intranet Ticket Class');

	SELECT im_category_new(31101, 'Missing or bad master data', 'Intranet Ticket Class');
	SELECT im_category_hierarchy_new(31101, 31100);

SELECT im_category_new(31200, 'Lack of user competency, ability or knowledge', 'Intranet Ticket Class');

	SELECT im_category_new(31201, 'New user creation', 'Intranet Ticket Class');
	SELECT im_category_new(31202, 'Extension/reduction of user permissions', 'Intranet Ticket Class');
	SELECT im_category_new(31203, 'Training request', 'Intranet Ticket Class');
	SELECT im_category_new(31204, 'Incorrect or incomplete documentation', 'Intranet Ticket Class');
	SELECT im_category_new(31205, 'Issue to export data', 'Intranet Ticket Class');

SELECT im_category_new(31300, 'Requests for new/additional services', 'Intranet Ticket Class');

	SELECT im_category_new(31301, 'New feature request', 'Intranet Ticket Class');
	SELECT im_category_hierarchy_new(31301, 31300);




-- 30200-30299 - Intranet Ticket User Priority
SELECT im_category_new(30201, '1 - Highest', 'Intranet Ticket Priority');
SELECT im_category_new(30202, '2', 'Intranet Ticket Priority');
SELECT im_category_new(30203, '3', 'Intranet Ticket Priority');
SELECT im_category_new(30204, '4', 'Intranet Ticket Priority');
SELECT im_category_new(30205, '5', 'Intranet Ticket Priority');
SELECT im_category_new(30206, '6', 'Intranet Ticket Priority');
SELECT im_category_new(30207, '7', 'Intranet Ticket Priority');
SELECT im_category_new(30208, '8', 'Intranet Ticket Priority');
SELECT im_category_new(30209, '9 - Lowest', 'Intranet Ticket Priority');




-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_ticket_status as
select	category_id as ticket_status_id, category as ticket_status
from	im_categories
where	category_type = 'Intranet Ticket Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_ticket_types as
select	category_id as ticket_type_id, category as ticket_type
from	im_categories
where	category_type = 'Intranet Ticket Type'
	and (enabled_p is null or enabled_p = 't');



-----------------------------------------------------------
-- Component Plugin
--
-- Create a Helpdesk plugin for the ProjectViewPage.


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Ticket Discussion',		-- plugin_name
	'intranet-helpdesk',		-- package_name
	'bottom',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_forum_full_screen_component -object_id $ticket_id'	-- component_tcl
);


-----------------------------------------------------------
-- Menu for Helpdesk
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_companies from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_main_menu
	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-helpdesk'',	-- package_name
		''helpdesk'',		-- label
		''Helpdesk'',		-- name
		''/intranet-helpdesk/'',   -- url
		75,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

	return 0;
end;' language 'plpgsql';

-- Execute and drop the function
select inline_0 ();
drop function inline_0 ();





delete from im_views where view_id = 270;
delete from im_view_columns where view_id = 270;

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (270, 'ticket_list', 'view_tickets', 1400);


insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27000,20,0, 'Ok','<center>[im_ticket_on_track_bb $on_track_status_id]</center>');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27002,20,10, 'Per','[im_date_format_locale $percent_completed 2 1] %');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27005,20,20, 'Ticket nr','"<A HREF=/intranet/tickets/view?ticket_id=$ticket_id>$ticket_nr</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27010,20,30,'Ticket Name','"<A HREF=/intranet/tickets/view?ticket_id=$ticket_id>$ticket_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27015,20,40,'Client','"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27020,20,50,'Type','$ticket_type');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27025,20,60,'Ticket Manager','"<A HREF=/intranet/users/view?user_id=$ticket_lead_id>$lead_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27030,20,70,'Start Date','$start_date_formatted');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27035,20,80,'Delivery Date','$end_date_formatted');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(27040,20,90,'Status','$ticket_status');




-----------------------------------------------------------
-- DynFields
--


-- SELECT im_dynfield_widget__new (
-- 	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
-- 	'ticket_type', 'Ticket Type', 'Ticket Type',
-- 	10007, 'integer', 'im_category_tree', 'integer',
-- 	'{custom {category_type "Intranet Ticket Type"}}'
-- );
-- SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_status_id', 'Status', 'ticket_type', 'integer', 'f');
 
-- SELECT im_dynfield_widget__new (
-- 	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
-- 	'ticket_status', 'Ticket Status', 'Ticket Status',
-- 	10007, 'integer', 'im_category_tree', 'integer',
-- 	'{custom {category_type "Intranet Ticket Status"}}'
-- );
-- SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_type_id', 'Type', 'ticket_type', 'integer', 'f');


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_priority', 'Ticket Priority', 'Ticket Priority',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Ticket Priority"}}'
);
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_prio_id', 'Priority', 'ticket_priority', 'integer', 'f');


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'customer_contact', 'Customer Contact', 'Customer Contacts',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select u.user_id, im_name_from_user_id(u.user_id) from registered_users u, group_distinct_member_map gm where u.user_id = gm.member_id and gm.group_id = 461 order by lower(im_name_from_user_id(u.user_id)) }}}'
);
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_contact_id', 'Customer Contact', 'customer_contact', 'integer', 'f');


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_assignees', 'Ticket Assignees', 'Ticket Assignees',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select u.user_id, im_name_from_user_id(u.user_id) from registered_users u, group_distinct_member_map gm where u.user_id = gm.member_id and gm.group_id = 463 order by lower(im_name_from_user_id(u.user_id)) }}}'
);
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_assignee_id', 'Assignee', 'ticket_assignees', 'integer', 'f');



--	ticket_sla_id                   integer
--	ticket_dept_id                  integer
--	ticket_primary_class_id         integer
--	ticket_service_id               integer
--	ticket_hardware_id              integer
--	ticket_application_id           integer
--	ticket_queue_id                 integer
--	ticket_alarm_date               timestamptz,
--	ticket_alarm_action             text,
--	ticket_note                     text
