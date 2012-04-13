-- /packages/intranet-rest/sql/postgresql/intranet-rest-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- REST
--
-- We need an "im_rest_object_type" object for every acs_object_type 
-- to define permissions per object type


-- Create a new object type.
-- This statement only creates an entry in acs_object_types with some
-- meta-information (table name, ... as specified below) about the new 
-- object. 
-- Please note that this is quite different from creating a new object
-- class in Java or other languages.

SELECT acs_object_type__create_type (
	'im_rest_object_type',			-- object_type - only lower case letters and "_"
	'REST Object Type',			-- pretty_name - Human readable name
	'REST Object Types',			-- pretty_plural - Human readable plural
	'acs_object',				-- supertype - "acs_object" is topmost object type.
	'im_rest_object_types',			-- table_name - where to store data for this object?
	'object_type_id',			-- id_column - where to store object_id in the table?
	'intranet-rest',			-- package_name - name of this package
	'f',					-- abstract_p - abstract class or not
	null,					-- type_extension_table
	'im_rest_object_type__name'		-- name_method - a PL/SQL procedure that
						-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_rest_object_type object.
update acs_object_types set
        status_type_table = 'im_rest_object_types',		-- which table contains the status_id field?
        status_column = 'object_type_status_id',		-- which column contains the status_id field?
        type_column = 'object_type_type_id'			-- which column contains the type_id field?
where object_type = 'im_rest_object_type';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_rest_object_type object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_rest_object_type', 'im_rest_object_types', 'object_type_id');



-- Generic URLs to link to an object of type "im_rest_object_type".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_rest_object_type','view','/intranet-rest/new?display_mode=display&object_type_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_rest_object_type','edit','/intranet-rest/new?display_mode=edit&object_type_id=');



-- This table stores one object per row. Links to super-type "acs_object" 
-- using the "object_type_id" field, which contains the same object_id as 
-- acs_objects.object_id.
create table im_rest_object_types (
				-- The object_id: references acs_objects.object_id.
				-- So we can lookup object metadata such as creation_date,
				-- object_type etc in acs_objects.
	object_type_id		integer
				constraint im_rest_object_type_id_pk
				primary key
				constraint im_rest_object_type_id_fk
				references acs_objects,

				-- Every ]po[ object should have a "status_id" to control
				-- its lifecycle. Status_id reference im_categories, where 
				-- you can define the list of stati for this object type.
	object_type_status_id	integer 
				constraint im_rest_object_type_status_nn
				not null
				constraint im_rest_object_type_status_fk
				references im_categories,
				-- Every ]po[ object should have a "type_id" to allow creating
				-- sub-types of the object. Type_id references im_categories
				-- where you can define the list of subtypes per object type.
	object_type_type_id	integer 
				constraint im_rest_object_type_type_nn
				not null
				constraint im_rest_object_type_type_fk
				references im_categories,
				-- This is the main content of a "object_type". Just a piece of text.
	object_type		varchar (1000)
				constraint im_rest_object_type_object_type_nn
				not null
				constraint im_rest_object_type_object_type_fk
				references acs_object_types
);

-- Speed up (frequent) queries to find all rest for a specific object.
create index im_rest_object_types_object_type_idx on im_rest_object_types(object_type);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint.
create unique index im_rest_object_object_type_idx on im_rest_object_types(object_type);




-----------------------------------------------------------
-- PL/SQL functions to Create and Delete rest and to get
-- the name of a specific object_type.
--
-- These functions represent constructor/destructor
-- functions for the OpenACS object system.
-- The double underscore ("__") represents the dot ("."),
-- which is not allowed in PostgreSQL.


-- Get the name for a specific object_type.
-- This function allows displaying object in generic contexts
-- such as the Full-Text Search engine or the Workflow.
--
-- Input is the object_type_id, output is a string with the name.
-- The function just pulls out the "object_type" text of the object_type
-- as the name. Not pretty, but we don't have any other data,
-- and every object needs this "__name" function.
create or replace function im_rest_object_type__name(integer)
returns varchar as '
DECLARE
	p_object_type_id		alias for $1;
	v_name				varchar;
BEGIN
	select	object_type
	into	v_name
	from	im_rest_object_types
	where	object_type_id = p_object_type_id;

	return v_name;
end;' language 'plpgsql';


-- Create a new object_type.
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a object_type with
-- the required fields of the im_rest table.
create or replace function im_rest_object_type__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer,
	integer 
) returns integer as '
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_object_type_id		alias for $1;		-- object_type_id  default null
	p_object_type   		alias for $2;		-- object_type default ''im_rest_object_type''
	p_creation_date 		alias for $3;		-- creation_date default now()
	p_creation_user 		alias for $4;		-- creation_user default null
	p_creation_ip   		alias for $5;		-- creation_ip default null
	p_context_id			alias for $6;		-- context_id default null

	-- Specific parameters with data to go into the im_rest_object_types table
	p_rest_object_type		alias for $7;		-- im_rest.note - contents
	p_object_type_status_id		alias for $8;		-- 
	p_object_type_type_id		alias for $9;		-- 

	-- This is a variable for the PL/SQL function
	v_object_type_id	integer;
BEGIN
	-- Create an acs_object as the super-type of the object_type.
	-- (Do you remember, im_rest_object_type is a subtype of acs_object?)
	-- acs_object__new returns the object_id of the new object.
	v_object_type_id := acs_object__new (
		p_object_type_id,		-- object_id - NULL to create a new id
		p_object_type,		-- object_type - "im_rest_object_type"
		p_creation_date,	-- creation_date - now()
		p_creation_user,	-- creation_user - Current user or "0" for guest
		p_creation_ip,		-- creation_ip - IP from ns_conn, or "0.0.0.0"
		p_context_id,		-- context_id - NULL, not used in ]po[
		''t''			-- security_inherit_p - not used in ]po[
	);
	
	-- Create an entry in the im_rest table with the same
	-- v_object_type_id from acs_objects.object_id
	insert into im_rest_object_types (
		object_type_id,
		object_type_status_id,
		object_type_type_id,
		object_type
	) values (
		v_object_type_id,
		coalesce(p_object_type_status_id, 43000),
		coalesce(p_object_type_type_id, 43100),
		p_rest_object_type
	);

	return v_object_type_id;
END;' language 'plpgsql';




-- Delete a object_type from the system.
-- Delete entries from both im_rest and acs_objects.
-- Deleting only from im_rest would lead to an invalid
-- entry in acs_objects, which is probably harmless, but innecessary.
create or replace function im_rest_object_type__delete(integer)
returns integer as '
DECLARE
	p_object_type_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_rest
	where	object_type_id = p_object_type_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_object_type_id);

	return 0;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for REST type and status.
-- Status acutally is not used by the application, 
-- so we just define "active" and "deleted".
-- Type contains information on how to format the data
-- in the im_rest.object_type field. For example, a "HTTP"
-- object_type is shown as a link.
--
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own modules.
--

-- 43000-43999	Reserved for Intranet REST
-- 43000-43099	Intranet REST Status
-- 43100-43199	Intranet REST Type

-- Status
SELECT im_category_new (43000, 'Active', 'Intranet REST Object Type Status');

-- Type
SELECT im_category_new (43100, 'Default', 'Intranet REST Object Type Type');



-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_rest_object_type_status as
select	category_id as object_type_status_id, category as object_type_status
from	im_categories
where	category_type = 'Intranet REST Object Type Status'
	and enabled_p = 't';

create or replace view im_rest_object_type_types as
select	category_id as object_type_type_id, category as object_type_type
from	im_categories
where	category_type = 'Intranet REST Object Type Type'
	and enabled_p = 't';



-----------------------------------------------------------
-- Menu for REST
--
-- Create a menu item in the main menu bar and set some default 
-- permissions for various groups who should be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;

BEGIN
	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_admin_menu
	from im_menus where label=''admin'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-rest'',	-- package_name
		''admin_rest'',		-- label
		''REST API'',		-- name
		''/intranet-rest/'',   -- url
		2200,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
-- Execute and then drop the function
select inline_0 ();
drop function inline_0 ();


update im_menus set menu_gif_small = 'arrow_right'
where label = 'admin_rest';





-----------------------------------------------------------
-- Create a new Report category for REST reports
--


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_reporting_menu		integer;

BEGIN
	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_reporting_menu
	from im_menus where label=''reporting'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-rest'',		-- package_name
		''reporting-rest'',		-- label
		''REST System Reports'',	-- name
		''/intranet-reporting/'',	-- url
		220,				-- sort_order
		v_reporting_menu,		-- parent_menu_id
		null				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
-- Execute and then drop the function
select inline_0 ();
drop function inline_0 ();




-- Create a report showing all projects into
-- which the %user_id% can log hours.
--
SELECT im_report_new (
	'REST My Timesheet Projects',					-- report_name
	'rest_my_timesheet_projects',					-- report_code
	'intranet-rest',						-- package_key
	100,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'select  child.*,
        tree_level(child.tree_sortkey)-1 as level,
        im_category_from_id(child.project_type_id) as project_type,
        im_category_from_id(child.project_status_id) as project_status
from
        im_projects parent,
        im_projects child,
        acs_rels r
where
        parent.parent_id is null and
        child.project_type_id not in (
		select 81 UNION select child_id from im_category_hierarchy where parent_id = 81
	) and
        child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
        r.object_id_one = parent.project_id and
        r.object_id_two = %user_id%
order by
        child.tree_sortkey
'
);

update im_reports 
set report_description = '
Returns the list of all projects to which the current user 
has the right to log hours. Currently, we are assuming the 
"permissive" hour logging model, so this report shows all 
parent projects where the user is a member, plus all of their 
child projects.
'
where report_code = 'rest_my_timesheet_projects';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'rest_my_timesheet_projects'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-- Create a report showing all hours logged by
-- the current user today.
--
SELECT im_report_new (
	'REST My Hours',						-- report_name
	'rest_my_hours',						-- report_code
	'intranet-rest',						-- package_key
	110,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'
select	h.*
from	im_hours h
where	h.user_id = %user_id% and
	h.day >= now()::date
'
);

update im_reports 
set report_description = '
Returns all hours logged today by the current user.
'
where report_code = 'rest_my_hours';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'rest_my_hours'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-- Create a report showing a category as a hierarchy.
--
SELECT im_report_new (
	'REST Category Type',						-- report_name
	'rest_category_type',						-- report_code
	'intranet-rest',						-- package_key
	120,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'
select	im_category_path_to_category(category_id) as tree_sortkey,
	c.*
from	im_categories c
where	(c.enabled_p is null OR c.enabled_p = ''t'') and
	category_type = %category_type%
order by tree_sortkey
'
);

update im_reports 
set report_description = '
Returns a category type ordered by tree_sortkey
'
where report_code = 'rest_category_type';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'rest_category_type'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





----------------------------------------------------------------------
-- Permission "Report"
----------------------------------------------------------------------

-- The report shows all permission associated with a specific object.
-- The report expects an "object_id" parameter.
--
SELECT im_report_new (
	'REST Object Permissions',					-- report_name
	'rest_object_permissions',					-- report_code
	'intranet-rest',						-- package_key
	110,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'
select	grantee_id, privilege
from	acs_permissions
where	object_id = %object_id%
'
);

update im_reports 
set report_description = '
Returns all permissions define for one object.
'
where report_code = 'rest_object_permissions';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'rest_object_permissions'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



----------------------------------------------------------------------
-- Group Membership Report
----------------------------------------------------------------------

-- Show all groups to which a specific user belongs.
-- By default shows the groups for the current user.
-- Expects a "user_id" parameter.
--
SELECT im_report_new (
	'REST Group Memberships',					-- report_name
	'rest_group_membership',					-- report_code
	'intranet-rest',						-- package_key
	120,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'
select	group_id
from	group_distinct_member_map
where	member_id = %object_id%
'
);

update im_reports 
set report_description = 'Returns all groups to which a user belongs.'
where report_code = 'rest_group_membership';

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'rest_group_membership'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);




SELECT im_report_new (
	'REST My Timesheet Projects and Hours',				-- report_name
	'rest_my_timesheet_projects_hours',				-- report_code
	'intranet-rest',						-- package_key
	110,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'select	child.project_id,
	child.parent_id,
	tree_level(child.tree_sortkey)-1 as level,
	child.project_name,
	child.project_nr,
	child.company_id,
	acs_object__name(child.company_id) as company_name,
	child.project_type_id,
	child.project_status_id,
	im_category_from_id(child.project_type_id) as project_type,
	im_category_from_id(child.project_status_id) as project_status,
	h.hours,
	h.note,
	h.material_id,
	acs_object__name(h.material_id) as material_name
from
	im_projects parent,
	im_projects child
	LEFT OUTER JOIN (
		select	*
		from	im_hours h
		where	h.user_id = %user_id% and
			h.day::date = ''%date%''::date
	) h ON (child.project_id = h.project_id),
	acs_rels r
where
	parent.parent_id is null and
	child.project_type_id not in (select * from im_sub_categories(81)) and
	child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
	r.object_id_one = parent.project_id and
	r.object_id_two = %user_id%
order by
	child.tree_sortkey
'
);


update im_reports
set report_description = '
Returns the list of all projects to which the current user
has the right to log hours, together with the list of hours
logged as of the specified %date% URL parameter.'
where report_code = 'rest_my_timesheet_projects_hours';

SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'rest_my_timesheet_projects_hours'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


