-- /packages/intranet-planning/sql/postgresql/intranet-planning-create.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Add new planning fields to im_project


alter table im_projects add column cost_bills_planned numeric(12,2);
alter table im_projects add column cost_expenses_planned numeric(12,2);


-----------------------------------------------------------
-- Planning
--
-- Assign a monthly or weekly number to an object and its 1st and 2nd dimension


-- Create a new object type.
-- This statement only creates an entry in acs_object_types with some
-- meta-information (table name, ... as specified below) about the new 
-- object. 
-- Please note that this is quite different from creating a new object
-- class in Java or other languages.

--SELECT acs_object_type__create_type (
--	'im_planning_item',			-- object_type - only lower case letters and "_"
--	'Planning Item',			-- pretty_name - Human readable name
--	'Planning Items',			-- pretty_plural - Human readable plural
--	'acs_object',				-- supertype - "acs_object" is topmost object type.
--	'im_planning_items',			-- table_name - where to store data for this object?
--	'item_id',				-- id_column - where to store object_id in the table?
--	'intranet-planning',			-- package_name - name of this package
--	'f',					-- abstract_p - abstract class or not
--	null,					-- type_extension_table
--	'im_planning_item__name'		-- name_method - a PL/SQL procedure that
--						-- returns the name of the object.
--);

-- Add additional meta information to allow DynFields to extend the im_planning_item object.
--update acs_object_types set
--        status_type_table = 'im_planning_items',	-- which table contains the status_id field?
--        status_column = 'item_status_id',		-- which column contains the status_id field?
--        type_column = 'item_type_id'			-- which column contains the type_id field?
--where object_type = 'im_planning_item';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_planning_item object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
--insert into acs_object_type_tables (object_type,table_name,id_column)
--values ('im_planning_item', 'im_planning_items', 'item_id');


-- Generic URLs to link to an object of type "im_planning_item".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
--insert into im_biz_object_urls (object_type, url_type, url) values (
--'im_planning_item','view','/intranet-planning/new?display_mode=display&item_id=');
--insert into im_biz_object_urls (object_type, url_type, url) values (
--'im_planning_item','edit','/intranet-planning/new?display_mode=edit&item_id=');




-- Sequence to create fake object_ids for im_planning_items
create sequence im_planning_items_seq;

-- This table stores one time line of items.
-- It is not an OpenACS object, so the item_id does not reference acs_objects.
---
create table im_planning_items (
			-- The (fake) object_id: does not yet reference acs_objects.
	item_id		integer default nextval('im_planning_items_seq')
			constraint im_planning_item_id_pk
			primary key,

			-- Field to allow attaching the item to a project, user or
			-- company. So object_id references acs_objects.object_id,
			-- the supertype of all object types.
	item_object_id	integer
			constraint im_planning_items_object_nn
			not null
			constraint im_planning_items_object_fk
			references acs_objects,
--			-- Type can be "Revenues" or "Costs"
--	item_type_id	integer 
--			constraint im_planning_item_type_nn
--			not null
--			constraint im_planning_item_type_fk
--			references im_categories,
--			-- Status of the planned row. May be "Active", "Approved"
--			-- or "Deleted". Could be controlled by a workflow.
--	item_status_id	integer 
--			constraint im_planning_item_status_nn
--			not null
--			constraint im_planning_item_status_fk
--			references im_categories,
			-- Project phase dimension
			-- for planning on project phases.
	item_project_phase_id integer
			constraint im_planning_items_project_phase_fk
			references im_projects,
			-- Project member dimension
			-- for planning per project member.
	item_project_member_id integer
			constraint im_planning_items_project_member_fk
			references parties,
			-- Only for planning hourly costs:
			-- Contains the hourly_cost of the resource in order
			-- to keep budgets from changing when changing the 
			-- im_employees.hourly_cost of a resource.
	item_project_member_hourly_cost numeric(12,3),
			-- Cost type dimension.
			-- Valid values include categories from "Intranet Cost Type"
			-- and "Intranet Expense Type" (as a sub-type for expenses)
	item_cost_type_id integer,
			-- Actual time dimension.
			-- The timestamptz indicates the start of the
			-- time range defined by item_date_type_id.
	item_date	timestamptz,
			-- Start of the time line for planning values.
			-- Should be set to the 1st day of week or month to plan.
	item_value	numeric(12,2),
			-- Note per line
	item_note	text
);

-- Speed up (frequent) queries to find all planning for a specific object.
create index im_planning_items_object_idx on im_planning_items(item_object_id);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint in order
-- to avoid creating duplicate entries during data import or if the user
-- performs a "double-click" on the "Create New Planning Item" button...
-- (This makes a lot of sense in practice. Otherwise there would be loads
-- of duplicated projects in the system and worse...)
create unique index im_planning_object_item_idx on im_planning_items(
	item_object_id,
	coalesce(item_project_phase_id,0), 
	coalesce(item_project_member_id,0),
	coalesce(item_cost_type_id,0),
	coalesce(item_date,'2000-01-01'::timestamptz)
);






-- Create a new planning item
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a item with
-- the required fields of the im_planning table.
create or replace function im_planning_item__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	integer, integer, integer,
	numeric, varchar,
	integer, integer, integer, timestamptz
) returns integer as $body$
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_item_id		alias for $1;		-- item_id  default null
	p_object_type   	alias for $2;		-- object_type default im_planning_item
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	-- Standard parameters
	p_item_object_id	alias for $7;		-- associated object (project, user, ...)
	p_item_type_id		alias for $8;		-- type (email, http, text comment, ...)
	p_item_status_id	alias for $9;		-- status ("active" or "deleted").

	-- Value parameters
	p_item_value		alias for $10;		-- the actual numeric value
	p_item_note		alias for $11;		-- A note per entry.

	-- Dimension parameter
	p_item_project_phase_id	alias for $12;
	p_item_project_member_id alias for $13;
	p_item_cost_type_id	alias for $14;
	p_item_date		alias for $15;

	v_item_id		integer;
BEGIN
	select	nextval('im_planning_items_seq')
	into	v_item_id from dual;

	-- Create an entry in the im_planning table with the same
	-- v_item_id from acs_objects.object_id
	insert into im_planning_items (
		item_id,
		item_object_id,
		item_project_phase_id,
		item_project_member_id,
		item_cost_type_id,
		item_date,
		item_value,
		item_note
	) values (
		v_item_id,
		p_item_object_id,
		p_item_project_phase_id,
		p_item_project_member_id,
		p_item_cost_type_id,
		p_item_date,
		p_item_value,
		p_item_note
	);

	-- Store the current hourly_rate with planning items.
	IF p_item_cost_type_id = 3736 AND p_item_project_member_id is not null THEN
		update im_planning_items
		set item_project_member_hourly_cost = (
			select hourly_cost
			from   im_employees
			where  employee_id = p_item_project_member_id
		    )
		where item_id = v_item_id;
	END IF;

	return 0;
END; $body$ language 'plpgsql';



-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for Planning type and status.
-- Status acutally is not used by the application, 
-- so we just define "active" and "deleted".
-- Type contains information on how to format the data
-- in the im_planning.note field. For example, a "HTTP"
-- note is shown as a link.
--
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own packages.
--
-- 73000-73999  Intranet Planning (1000)
-- 73000-73099  Intranet Planning Status (100)
-- 73100-73199  Intranet Planning Type (100)
-- 73200-73299  Intranet Planning Time Dimension (100)
-- 73200-73999  reserved (800)

-- Status
SELECT im_category_new (73000, 'Active', 'Intranet Planning Status');
SELECT im_category_new (73002, 'Deleted', 'Intranet Planning Status');

-- Type
SELECT im_category_new (73100, 'Revenues', 'Intranet Planning Type');
SELECT im_category_new (73102, 'Costs', 'Intranet Planning Type');

-- Time Dimension
SELECT im_category_new (73200, 'Quarter', 'Intranet Planning Time Dimension');
SELECT im_category_new (73202, 'Month', 'Intranet Planning Time Dimension');
SELECT im_category_new (73204, 'Week', 'Intranet Planning Time Dimension');
SELECT im_category_new (73206, 'Day', 'Intranet Planning Time Dimension');


-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_planning_item_status as
select	category_id as item_status_id, category as item_status
from	im_categories
where	category_type = 'Intranet Planning Status'
	and enabled_p = 't';

create or replace view im_planning_item_types as
select	category_id as item_type_id, category as item_type
from	im_categories
where	category_type = 'Intranet Planning Type'
	and enabled_p = 't';




-------------------------------------------------------------
-- Permissions and Privileges
--

-- A "privilege" is a kind of parameter that can be set per group
-- in the Admin -> Profiles page. This way you can define which
-- users can see planning.
-- In the default configuration below, only Employees have the
-- "privilege" to "view" planning.
-- The "acs_privilege__add_child" line below means that "view_planning_all"
-- is a sub-privilege of "admin". This way the SysAdmins always
-- have the right to view planning.

select acs_privilege__create_privilege('view_planning_all','View Planning All','View Planning All');
select acs_privilege__add_child('admin', 'view_planning_all');

-- Allow all employees to view planning. You can add new groups in 
-- the Admin -> Profiles page.
select im_priv_create('view_planning_all','Employees');


-----------------------------------------------------------
-- Plugin Components
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system. The plugin shows the list of planning that are
-- associated with the specific object.
-- This way we can add planning to projects, users companies etc.
-- with only a single TCL/ADP page.
--
-- You can add/modify these plugin definitions in the Admin ->
-- Plugin Components page

-- Create a Planning plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Financial Planning',	-- plugin_name
	'intranet-planning',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_planning_component -object_id $project_id'	-- component_tcl
);


-----------------------------------------------------------
-- Menu for Planning
--
-- Create a menu item in the main menu bar and set some default 
-- permissions for various groups who should be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_main_menu
	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_component_plugin'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-planning'',	-- package_name
		''planning'',		-- label
		''Planning'',		-- name
		''/intranet-planning/'',   -- url
		75,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	
	-- Grant some groups the read permission for the main "Planning" tab.
	-- These permissions are independent from the user`s permission to
	-- read the actual planning.
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

	return 0;
end;' language 'plpgsql';
-- Execute and then drop the function
select inline_0 ();
drop function inline_0 ();



-- Disable the top-level tab until there are some reasonable pages for it...
update im_menus
set enabled_p = 'f'
where label = 'planning';

