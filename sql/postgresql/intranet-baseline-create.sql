-- /packages/intranet-baseline/sql/postgresql/intranet-baseline-create.sql
--
-- Copyright (c) 2010 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>




-----------------------------------------------------------
-- Baselines
--
-- Represents a version of a project tree.
-- Baselines are represented as business objects in order to allow
-- workflows to be started around them.


SELECT acs_object_type__create_type (
	'im_baseline',			-- object_type - only lower case letters and "_"
	'Baseline',			-- pretty_name - Human readable name
	'Baselines',			-- pretty_plural - Human readable plural
	'acs_object',			-- supertype - "acs_object" is topmost object type.
	'im_baselines',			-- table_name - where to store data for this object?
	'baseline_id',			-- id_column - where to store object_id in the table?
	'intranet-baselines',		-- package_name - name of this package
	'f',				-- abstract_p - abstract class or not
	null,				-- type_extension_table
	'im_baseline__name'		-- name_method - a PL/SQL procedure that
					-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_baseline object.
update acs_object_types set
        status_type_table = 'im_baselines',		-- which table contains the status_id field?
        status_column = 'baseline_status_id',		-- which column contains the status_id field?
        type_column = 'baseline_type_id'		-- which column contains the type_id field?
where object_type = 'im_baseline';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_baseline object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
insert into acs_object_type_tables (object_type, table_name, id_column)
values ('im_baseline', 'im_baselines', 'baseline_id');



-- Generic URLs to link to an object of type "im_baseline".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_baseline','view','/intranet-baselines/new?display_mode=display&baseline_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_baseline','edit','/intranet-baselines/new?display_mode=edit&baseline_id=');



-- This table stores one object per row. Links to super-type "acs_object" 
-- using the "baseline_id" field, which contains the same object_id as 
-- acs_objects.object_id.
create table im_baselines (
				-- The object_id: references acs_objects.object_id.
				-- So we can lookup object metadata such as creation_date,
				-- object_type etc in acs_objects.
	baseline_id		integer
				constraint im_baseline_id_pk
				primary key
				constraint im_baseline_id_fk
				references acs_objects,
				-- This is the main content of a "baseline". Just a piece of text.
	baseline_name		text
				constraint im_baseline_baseline_name_nn
				not null,
				-- To which main project does the baseline belong?
	baseline_project_id	integer
				constraint im_baseline_project_fk
				references im_projects
				constraint im_baseline_project_nn
				not null,
				-- Every ]po[ object should have a "status_id" to control
				-- its lifecycle. Status_id reference im_categories, where 
				-- you can define the list of stati for this object type.
	baseline_status_id	integer 
				constraint im_baseline_status_nn
				not null
				constraint im_baseline_status_fk
				references im_categories,
				-- Every ]po[ object should have a "type_id" to allow creating
				-- sub-types of the object. Type_id references im_categories
				-- where you can define the list of subtypes per object type.
	baseline_type_id	integer 
				constraint im_baseline_type_nn
				not null
				constraint im_baseline_type_fk
				references im_categories
);

-- Speed up (frequent) queries to find all baselines for a specific object.
create index im_baselines_project_idx on im_baselines(baseline_project_id);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint in order
-- to avoid creating duplicate entries during data import or if the user
-- performs a "double-click" on the "Create New Baseline" button...
-- (This makes a lot of sense in practice. Otherwise there would be loads
-- of duplicated projects in the system and worse...)
create unique index im_baselines_object_baseline_idx on im_baselines(baseline_project_id, baseline_name);



-----------------------------------------------------------
-- Add a baseline_id field to im_projects_audit.
-- 
alter table im_projects_audit
add baseline_id integer
constraint im_projects_audit_baseline_fk
references im_baselines;

-- Speedup lookup for baselines
create index im_projects_audit_baselines_idx on im_projects_audit(baseline_id);



-----------------------------------------------------------
-- PL/SQL functions to Create and Delete baselines and to get
-- the name of a specific baseline.
--
-- These functions represent constructor/destructor
-- functions for the OpenACS object system.
-- The double underscore ("__") represents the dot ("."),
-- which is not allowed in PostgreSQL.


-- Get the name for a specific baseline.
-- This function allows displaying object in generic contexts
-- such as the Full-Text Search engine or the Workflow.
--
-- Input is the baseline_id, output is a string with the name.
-- The function just pulls out the "baseline" text of the baseline
-- as the name. Not pretty, but we don't have any other data,
-- and every object needs this "__name" function.
create or replace function im_baseline__name(integer)
returns varchar as '
DECLARE
	p_baseline_id		alias for $1;
	v_name			varchar;
BEGIN
	select	substring(baseline_name for 30)
	into	v_name
	from	im_baselines
	where	baseline_id = p_baseline_id;

	return v_name;
end;' language 'plpgsql';


-- Create a new baseline.
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a baseline with
-- the required fields of the im_baselines table.
create or replace function im_baseline__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer,
	integer, integer 
) returns integer as '
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_baseline_id		alias for $1;		-- baseline_id  default null
	p_object_type   	alias for $2;		-- object_type default ''im_baseline''
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	-- Specific parameters with data to go into the im_baselines table
	p_baseline_name		alias for $7;		-- im_baselines.baseline_name
	p_baseline_project_id	alias for $8;		-- associated object (project, user, ...)
	p_baseline_type_id	alias for $9;		-- type (email, http, text comment, ...)
	p_baseline_status_id	alias for $10;		-- status ("active" or "deleted").

	-- This is a variable for the PL/SQL function
	v_baseline_id	integer;
BEGIN
	-- Create an acs_object as the super-type of the baseline.
	-- acs_object__new returns the object_id of the new object.
	v_baseline_id := acs_object__new (
		p_baseline_id,		-- object_id - NULL to create a new id
		p_object_type,		-- object_type - "im_baseline"
		p_creation_date,	-- creation_date - now()
		p_creation_user,	-- creation_user - Current user or "0" for guest
		p_creation_ip,		-- creation_ip - IP from ns_conn, or "0.0.0.0"
		p_context_id,		-- context_id - NULL, not used in ]po[
		''t''			-- security_inherit_p - not used in ]po[
	);
	
	-- Create an entry in the im_baselines table with the same
	-- v_baseline_id from acs_objects.object_id
	insert into im_baselines (
		baseline_id, baseline_name, baseline_project_id,
		baseline_type_id, baseline_status_id
	) values (
		v_baseline_id, p_baseline_name, p_baseline_project_id,
		p_baseline_type_id, p_baseline_status_id
	);

	return v_baseline_id;
END;' language 'plpgsql';


-- Delete a baseline from the system.
-- Delete entries from both im_baselines and acs_objects.
-- Deleting only from im_baselines would lead to an invalid
-- entry in acs_objects, which is probably harmless, but innecessary.
create or replace function im_baseline__delete(integer)
returns integer as '
DECLARE
	p_baseline_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_baselines
	where	baseline_id = p_baseline_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_baseline_id);

	return 0;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for Baselines type and status.
-- Status represents workflow states, plus "deleted".
-- Type isn't currently used, so it only contains "default".
--
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own packages.
--
-- 71000-71999  Intranet Baseline (1000)
-- 71000-71099	Intranet Baseline Status
-- 71100-71199  Intranet Baseline Type
-- 71200-71999	reserved for future extensions

-- Status
SELECT im_category_new (71000, 'Active', 'Intranet Baseline Status');
SELECT im_category_new (71002, 'Deleted', 'Intranet Baseline Status');
SELECT im_category_new (71004, 'Requested', 'Intranet Baseline Status');
SELECT im_category_new (71006, 'Rejected', 'Intranet Baseline Status');

-- Type
SELECT im_category_new (71110, 'Project Proposal', 'Intranet Baseline Type');
SELECT im_category_new (71120, 'Budget Approved', 'Intranet Baseline Type');
SELECT im_category_new (71130, 'Detailed Planning', 'Intranet Baseline Type');
SELECT im_category_new (71140, 'Project Start', 'Intranet Baseline Type');
SELECT im_category_new (71150, 'Project Revision', 'Intranet Baseline Type');
SELECT im_category_new (71170, 'Customer Delivery', 'Intranet Baseline Type');
SELECT im_category_new (71190, 'Project Wrapup', 'Intranet Baseline Type');


-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_baseline_states as
select	category_id as baseline_status_id, category as baseline_status
from	im_categories
where	category_type = 'Intranet Baseline Status'
	and enabled_p = 't';

create or replace view im_baseline_types as
select	category_id as baseline_type_id, category as baseline_type
from	im_categories
where	category_type = 'Intranet Baseline Type'
	and enabled_p = 't';




-------------------------------------------------------------
-- Permissions and Privileges
--

-- A "privilege" is a kind of parameter that can be set per group
-- in the Admin -> Profiles page. This way you can define which
-- users can see baselines.
-- In the default configuration below, only Employees have the
-- "privilege" to "view" baselines.
-- The "acs_privilege__add_child" line below means that "view_baselines"
-- is a sub-privilege of "admin". This way the SysAdmins always
-- have the right to view baselines.

-- Who has the right to add new baselines?
-- Project members may view baselines anyway.
select acs_privilege__create_privilege('add_baselines','Add Baselines','Add Baselines');
select acs_privilege__add_child('admin', 'add_baselines');
select im_priv_create('add_baselines','Employees');

select acs_privilege__create_privilege('del_baselines','Del Baselines','Del Baselines');
select acs_privilege__add_child('admin', 'del_baselines');
select im_priv_create('del_baselines','Employees');


-----------------------------------------------------------
-- Plugin Components
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system. The plugin shows the list of baselines that are
-- associated with the specific object.
-- This way we can add baselines to projects, users companies etc.
-- with only a single TCL/ADP page.
--
-- You can add/modify these plugin definitions in the Admin ->
-- Plugin Components page



-- Create a Baselines plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Baselines',		-- plugin_name
	'intranet-baselines',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	-90,				-- sort_order
	'im_baseline_component -project_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-baselines.Project_Baselines "Project Baselines"'
where plugin_name = 'Project Baselines';


