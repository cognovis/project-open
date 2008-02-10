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
	'im_note',			-- object_type
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


create table im_tickets (
	ticket_id		integer
				constraint im_ticket_id_pk
				primary key
				constraint im_ticket_id_fk
				references im_projects,
	ticket_status_id	integer 
				constraint im_ticket_status_nn
				not null
				constraint im_ticket_status_fk
				references im_categories,
	ticket_type_id		integer 
				constraint im_ticket_type_nn
				not null
				constraint im_ticket_type_fk
				references im_categories,
	note			text
				constraint im_ticket_ticket_nn
				not null,
	object_id		integer
				constraint im_ticket_oid_nn
				not null
				constraint im_object_id_fk
				references acs_objects
);


-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_ticket__name(integer)
returns varchar as '
DECLARE
	p_ticket_id		alias for $1;
	v_name			varchar(2000);
BEGIN
	select	note
	into	v_name
	from	im_helpdesk
	where	ticket_id = p_ticket_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_ticket__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer,
	integer, integer 
) returns integer as '
DECLARE
	p_ticket_id	alias for $1;		-- ticket_id  default null
	p_object_type   alias for $2;		-- object_type default ''im_ticket''
	p_creation_date alias for $3;		-- creation_date default now()
	p_creation_user alias for $4;		-- creation_user default null
	p_creation_ip   alias for $5;		-- creation_ip default null
	p_context_id	alias for $6;		-- context_id default null

	p_note		alias for $7;		-- ticket_name
	p_object_id	alias for $8;		-- object_id
	p_ticket_type_id	alias for $9;		
	p_ticket_status_id alias for $10;

	v_ticket_id	integer;
BEGIN
	v_ticket_id := acs_object__new (
		p_ticket_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_helpdesk (
		ticket_id, note, object_id,
		ticket_type_id, ticket_status_id
	) values (
		v_ticket_id, p_note, p_object_id,
		p_ticket_type_id, p_ticket_status_id
	);

	return v_ticket_id;
END;' language 'plpgsql';


create or replace function im_ticket__delete(integer)
returns integer as '
DECLARE
	p_ticket_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete from im_helpdesk
	where	ticket_id = p_ticket_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_ticket_id);

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



-- 30400-30499	Intranet Service Catalog
SELECT im_category_new(30400, 'End user support', 'Intranet Service Catalog');
SELECT im_category_new(30420, 'System administrator support', 'Intranet Service Catalog');
SELECT im_category_new(30410, 'Hosting service', 'Intranet Service Catalog');
SELECT im_category_new(30420, 'Software update service', 'Intranet Service Catalog');



-- 35000-35099	1st level of Intranet Ticket Class
SELECT im_category_new(31000, 'Broken system or configuration', 'Intranet Ticket Class');

	SELECT im_category_new(31001, 'Bug/error in application', 'Intranet Ticket Class');
	SELECT im_category_new(31002, 'Network access to application unavailable or slow', 'Intranet Ticket Class');
	SELECT im_category_new(31003, 'Performance issues with application', 'Intranet Ticket Class');
	SELECT im_category_new(31004, 'Issues with backup & recovery', 'Intranet Ticket Class');
	SELECT im_category_new(31005, 'Browser issue: Information is rendered incorrectly', 'Intranet Ticket Class');
	SELECT im_category_new(31006, 'Report does not show expected data', 'Intranet Ticket Class');
	SELECT im_category_new(31007, 'Request for code update', 'Intranet Ticket Class');
	SELECT im_category_new(31008, 'Security issue', 'Intranet Ticket Class');
	SELECT im_category_hierarchynew(31001, 31000);
	SELECT im_category_hierarchynew(31002, 31000);
	SELECT im_category_hierarchynew(31003, 31000);
	SELECT im_category_hierarchynew(31004, 31000);
	SELECT im_category_hierarchynew(31005, 31000);
	SELECT im_category_hierarchynew(31006, 31000);
	SELECT im_category_hierarchynew(31007, 31000);
	SELECT im_category_hierarchynew(31008, 31000);

SELECT im_category_new(31100, 'Invalid data in system', 'Intranet Ticket Class');

	SELECT im_category_new(31101, 'Missing or bad master data', 'Intranet Ticket Class');
	SELECT im_category_new(31102, 'Report does not show expected data', 'Intranet Ticket Class');
	SELECT im_category_hierarchynew(31101, 31100);
	SELECT im_category_hierarchynew(31102, 31100);

SELECT im_category_new(31200, 'Lack of user competency, ability or knowledge', 'Intranet Ticket Class');

	SELECT im_category_new(31201, 'New user creation', 'Intranet Ticket Class');
	SELECT im_category_new(31202, 'Extension/reduction of user permissions', 'Intranet Ticket Class');
	SELECT im_category_new(31203, 'Training request', 'Intranet Ticket Class');
	SELECT im_category_new(31204, 'Incorrect or incomplete documentation', 'Intranet Ticket Class');
	SELECT im_category_new(31205, 'Issue to export data', 'Intranet Ticket Class');
	SELECT im_category_hierarchynew(31201, 31200);
	SELECT im_category_hierarchynew(31202, 31200);
	SELECT im_category_hierarchynew(31203, 31200);
	SELECT im_category_hierarchynew(31204, 31200);
	SELECT im_category_hierarchynew(31205, 31200);

SELECT im_category_new(31300, 'Requests for new/additional services', 'Intranet Ticket Class');

	SELECT im_category_new(31301, 'New feature request', 'Intranet Ticket Class');
	SELECT im_category_hierarchynew(31301, 31300);





insert into im_categories(category_id, category, category_type) 
values (11400, 'Active', 'Intranet Helpdesk Status');
insert into im_categories(category_id, category, category_type) 
values (11402, 'Deleted', 'Intranet Helpdesk Status');


insert into im_categories(category_id, category, category_type) 
values (11500, 'Address', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11502, 'Email', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11504, 'Http', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11506, 'Ftp', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11508, 'Phone', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11510, 'Fax', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11512, 'Mobile', 'Intranet Helpdesk Type');
insert into im_categories(category_id, category, category_type) 
values (11514, 'Other', 'Intranet Helpdesk Type');


-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_ticket_status as
select	category_id as ticket_status_id, category as ticket_status
from	im_categories
where	category_type = 'Intranet Helpdesk Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_ticket_types as
select	category_id as ticket_type_id, category as ticket_type
from	im_categories
where	category_type = 'Intranet Helpdesk Type'
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
	'Project Helpdesk',		-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_helpdesk_project_component -object_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-helpdesk.Project_Helpdesk "Project Helpdesk"'
where plugin_name = 'Project Helpdesk';


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Company Helpdesk',		-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_helpdesk_project_component -object_id $company_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-helpdesk.Company_Helpdesk "Company Helpdesk"'
where plugin_name = 'Company Helpdesk';



SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'User Helpdesk',			-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_helpdesk_project_component -object_id $user_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-helpdesk.User_Helpdesk "User Helpdesk"'
where plugin_name = 'User Helpdesk';




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

