-- /packages/intranet-sla-management/sql/postgresql/intranet-sla-management-create.sql
--
-- Copyright (c) 2003-2011 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- SLA-Management
--
-- SLAs are defined by a number of parameters per SLA including:
--	- Maximum response time per ticket type
--	- Maximum resolution time per ticket type
--	- Business hours
--	- Minimum availability of servers, services and other CIs
--

-- SLA parameters can be defined in various ways:
--	- As a DynField in general
--	- As a im_sla_parameter which includes dynamic columns
--	- As business hours in the im_sla_business_hours table
--	- You may add additional tables to specify service parameters

-- SLA parameters are checked using a number of reports and indicators
-- that will turn red if the parameters are exceeded. Every SLA parameter
-- will need a customer indicator for evaluation. This indicator will
-- take specific assumptions about how the "world" is modelled in ]po[.



-- Add a field to im_tickets to store a calculated "resolution time"
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
	v_attribute_id	integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_tickets' and lower(column_name) = 'ticket_resolution_time';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_tickets
	add ticket_resolution_time numeric(12,2);

	alter table im_tickets
	add ticket_resolution_time_dirty timestamptz;

	SELECT im_dynfield_attribute_new (
		'im_ticket', 'ticket_resolution_time', 'Resolution Time', 'numeric', 'integer', 'f', 9000, 'f', 'im_tickets'
	) INTO 	v_attribute_id;

	-- set permissions for ticket_resolution_time to "read only" for all types of tickets.
	update im_dynfield_type_attribute_map
	set display_mode = 'display'
	where attribute_id = v_attribute_id;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
	v_attribute_id	integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_tickets' and lower(column_name) = 'ticket_resolution_time_per_queue';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_tickets add ticket_resolution_time_per_queue numeric(12,2)[];

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();




-- Add a field to im_projects to store ticket priority map
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
	v_attribute_id	integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_projects' and lower(column_name) = 'sla_ticket_priority_map';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_projects
	add sla_ticket_priority_map text;

	-- Create a sequence for the map tuples
	create sequence im_ticket_priority_map_seq;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();




-------------------------------------------------------------------------------
-- SLA Parameter Object
-------------------------------------------------------------------------------

SELECT acs_object_type__create_type (
	'im_sla_parameter',		-- object_type - only lower case letters and "_"
	'SLA Parameter',		-- pretty_name - Human readable name
	'SLA Parameter',		-- pretty_plural - Human readable plural
	'acs_object',			-- supertype - "acs_object" is topmost object type.
	'im_sla_parameters',		-- table_name - where to store data for this object?
	'param_id',			-- id_column - where to store object_id in the table?
	'intranet-sla-management',	-- package_name - name of this package
	'f',				-- abstract_p - abstract class or not
	null,				-- type_extension_table
	'im_sla_parameter__name'	-- name_method - a PL/SQL procedure that
					-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_note object.
update acs_object_types set
        status_type_table = 'im_sla_management',		-- which table contains the status_id field?
        status_column = 'param_status_id',			-- which column contains the status_id field?
        type_column = 'param_type_id'				-- which column contains the type_id field?
where object_type = 'im_sla_parameter';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_sla_parameter object.
-- This way, developers can add "extension tables" to an object to
-- hold additional DynFields, without changing the program code.
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_sla_parameter', 'im_sla_parameters', 'param_id');



-- Generic URLs to link to an object of type "im_sla_parameter".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_sla_parameter','view','/intranet-sla-management/new?display_mode=display&param_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_sla_parameter','edit','/intranet-sla-management/new?display_mode=edit&param_id=');


create table im_sla_parameters (
				-- The object_id: references acs_objects.object_id.
				-- So we can lookup object metadata such as creation_date,
				-- object_type etc in acs_objects.
	param_id		integer
				constraint im_sla_parameter_id_pk
				primary key
				constraint im_sla_parameter_id_fk
				references acs_objects,
				-- Every ]po[ object should have a "status_id" to control
				-- its lifecycle. Status_id reference im_categories, where 
				-- you can define the list of stati for this object type.
	param_name		text
				constraint im_sla_parameter_name_nn
				not null,
	param_status_id		integer 
				constraint im_sla_parameter_status_nn
				not null
				constraint im_sla_parameter_status_fk
				references im_categories,
				-- Every ]po[ object should have a "type_id" to allow creating
				-- sub-types of the object. Type_id references im_categories
				-- where you can define the list of subtypes per object type.
	param_type_id		integer 
				constraint im_sla_parameter_type_nn
				not null
				constraint im_sla_parameter_type_fk
				references im_categories,
				-- This is the main content of a "note". Just a piece of text.
	param_sla_id		integer
				constraint im_sla_parameter_sla_nn
				not null
				constraint im_sla_parameter_sla_fk
				references im_projects,
				-- Note for parameter
	param_note		text,
				-- First default parameter: Type of ticket
				-- The name of the field should be identical to the name
				-- of the corresponding im_tickets field.
	ticket_type_id		integer
				constraint im_sla_parameter_ticket_type_fk
				references im_categories,
				-- First default value: Resolution time 
	max_resolution_hours	numeric(12,1)
	
	-- More parameters are added using DynFields
);


-- Speed up (frequent) queries to find all sla-management for a specific object.
create index im_sla_parameters_sla_idx on im_sla_parameters(param_sla_id);

-- Avoid duplicate entries.
-- Every ]po[ object should contain one such "unique" constraint in order
-- to avoid creating duplicate entries during data import or if the user
-- performs a "double-click" on the "Create New Note" button...
-- (This makes a lot of sense in practice. Otherwise there would be loads
-- of duplicated projects in the system and worse...)
create unique index im_sla_parameters_un_idx on im_sla_parameters(param_name, param_sla_id);




-----------------------------------------------------------
-- PL/SQL functions to Create and Delete sla-management and to get
-- the name of a specific note.
--
-- These functions represent constructor/destructor
-- functions for the OpenACS object system.
-- The double underscore ("__") represents the dot ("."),
-- which is not allowed in PostgreSQL.


-- Get the name for a specific note.
-- This function allows displaying object in generic contexts
-- such as the Full-Text Search engine or the Workflow.
--
-- Input is the param_id, output is a string with the name.
-- The function just pulls out the "note" text of the note
-- as the name. Not pretty, but we don't have any other data,
-- and every object needs this "__name" function.
create or replace function im_sla_parameter__name(integer)
returns varchar as '
DECLARE
	p_param_id		alias for $1;
	v_name			varchar;
BEGIN
	select	substring(param_name for 30)
	into	v_name
	from	im_sla_parameters
	where	param_id = p_param_id;

	return v_name;
end;' language 'plpgsql';


-- Create a new parameter.
-- The first 6 parameters are common for all ]po[ business objects
-- with metadata such as the creation_user etc. Context_id 
-- is always disabled (NULL) for ]po[ objects (inherit permissions
-- from a super object...).
-- The following parameters specify the content of a note with
-- the required fields of the im_sla_management table.
create or replace function im_sla_parameter__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer, integer,
	integer, varchar
) returns integer as '
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_param_id		alias for $1;		-- param_id  default null
	p_object_type   	alias for $2;		-- object_type default ''im_sla_parameter''
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	-- Specific parameters with data to go into the im_sla_management table
	p_param_name		alias for $7;		-- Unique name
	p_param_sla_id		alias for $8;		-- SLA for the parameter
	p_param_type_id		alias for $9;		-- type
	p_param_status_id	alias for $10;		-- status ("active" or "deleted").
	p_param_note		alias for $11;		-- name/comment for the parameter

	-- This is a variable for the PL/SQL function
	v_param_id	integer;
BEGIN
	-- Create an acs_object as the super-type of the note.
	-- (Do you remember, im_sla_parameter is a subtype of acs_object?)
	-- acs_object__new returns the object_id of the new object.
	v_param_id := acs_object__new (
		p_param_id,		-- object_id - NULL to create a new id
		p_object_type,		-- object_type - "im_sla_parameter"
		p_creation_date,	-- creation_date - now()
		p_creation_user,	-- creation_user - Current user or "0" for guest
		p_creation_ip,		-- creation_ip - IP from ns_conn, or "0.0.0.0"
		p_context_id,		-- context_id - NULL, not used in ]po[
		''t''			-- security_inherit_p - not used in ]po[
	);
	
	-- Create an entry in the im_sla_management table with the same
	-- v_param_id from acs_objects.object_id
	insert into im_sla_parameters (
		param_id, param_name, param_sla_id,
		param_type_id, param_status_id
	) values (
		v_param_id, p_param_name, p_param_sla_id,
		p_param_type_id, p_param_status_id
	);

	return v_param_id;
END;' language 'plpgsql';


-- Delete a note from the system.
-- Delete entries from both im_sla_management and acs_objects.
-- Deleting only from im_sla_management would lead to an invalid
-- entry in acs_objects, which is probably harmless, but innecessary.
create or replace function im_sla_parameter__delete(integer)
returns integer as '
DECLARE
	p_param_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_sla_parameters
	where	param_id = p_param_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_param_id);

	return 0;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Categories for Type and Status
--
-- Create categories for SLA-Management type and status.
-- Status acutally is not used by the application, 
-- so we just define "active" and "deleted".
-- Type contains information on how to format the data
-- in the im_sla_management.note field. For example, a "HTTP"
-- note is shown as a link.
--
-- The categoriy_ids for status and type are used as a
-- global unique constants and defined in 
-- /packages/intranet-core/sql/common/intranet-categories.sql.
-- Please send an email to support@project-open.com with
-- the subject line "Category Range Request" in order to
-- request a range of constants for your own packages.
--
-- 72000-72999  Intranet SLA Management (1000)
-- 72000-72099	SLA Parameter Status (100)
-- 72100-72299	SLA Parameter Type (200)
-- 72300-72999	reserved (700)

-- Status
SELECT im_category_new (72000, 'Active', 'Intranet SLA Parameter Status');
SELECT im_category_new (72002, 'Deleted', 'Intranet SLA Parameter Status');

-- Type
SELECT im_category_new (72100, 'Default', 'Intranet SLA Parameter Type');



-- Create a new indicator section.
select im_category_new (15250, 'SLA Management', 'Intranet Indicator Section');



-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_sla_parameter_status as
select	category_id as param_status_id, category as param_status
from	im_categories
where	category_type = 'Intranet SLA Parameter Status'
	and enabled_p = 't';

create or replace view im_sla_parameter_types as
select	category_id as param_type_id, category as param_type
from	im_categories
where	category_type = 'Intranet SLA Parameter Type'
	and enabled_p = 't';


-------------------------------------------------------------
-- Permissions and Privileges
--

-- A "privilege" is a kind of parameter that can be set per group
-- in the Admin -> Profiles page. This way you can define which
-- users can see sla-management.
-- In the default configuration below, only Employees have the
-- "privilege" to "view" sla-management.
-- The "acs_privilege__add_child" line below means that "view_sla-management"
-- is a sub-privilege of "admin". This way the SysAdmins always
-- have the right to view sla-management.

select acs_privilege__create_privilege('edit_sla_parameters_all','Edit all SLA Parameters','Edit all SLA Parameters');
select acs_privilege__add_child('admin', 'edit_sla_parameters_all');

-- Allow all employees to view sla-management. You can add new groups in 
-- the Admin -> Profiles page.
select im_priv_create('edit_sla_parameters_all','Employees');




-- --------------------------------------------------------
-- Param - Indicator Relationship
--
-- This relationship connects params with indicators validating the param

create table im_sla_param_indicator_rels (
	rel_id			integer
				constraint im_sla_param_indicator_rels_rel_fk
				references acs_rels (rel_id)
				constraint im_sla_param_indicator_rels_rel_pk
				primary key,
	sort_order		integer
);

select acs_rel_type__create_type (
	'im_sla_param_indicator_rel',	-- relationship (object) name
	'Param Project Rel',		-- pretty name
	'Param Project Rels',		-- pretty plural
	'relationship',			-- supertype
	'im_sla_param_indicator_rels',	-- table_name
	'rel_id',			-- id_column
	'intranet-sla-management-rel',	-- package_name
	'im_sla_parameter',		-- object_type_one
	'member',			-- role_one
	0,				-- min_n_rels_one
	null,				-- max_n_rels_one
	'im_indicator',			-- object_type_two
	'member',			-- role_two
	0,				-- min_n_rels_two
	null				-- max_n_rels_two
);


create or replace function im_sla_param_indicator_rel__new (
integer, varchar, integer, integer, integer, integer, varchar, integer)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_sla_param_indicator_rel
	p_param_id		alias for $3;
	p_indicator_id		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
	p_sort_order		alias for $8;

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_param_id,
		p_indicator_id,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_sla_param_indicator_rels (
		rel_id, sort_order
	) values (
		v_rel_id, p_sort_order
	);

	return v_rel_id;
end;' language 'plpgsql';


create or replace function im_sla_param_indicator_rel__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_sla_param_indicator_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_sla_param_indicator_rel__delete (integer, integer)
returns integer as '
DECLARE
	p_param_id	alias for $1;
		p_indicator_id	alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id into v_rel_id
	from	acs_rels
	where	object_id_one = p_param_id
		and object_id_two = p_indicator_id;

	PERFORM im_sla_param_indicator_rel__delete(v_rel_id);
	return 0;
end;' language 'plpgsql';



-- --------------------------------------------------------
-- Service Hours per SLA Project
--
-- This table stores {start end} tuples for every weekday and SLA.
-- Example:
-- 0 (Sun)	""
-- 1 (Mon)	"{09:00 18:00}"
-- 2 (Tue)	"{09:00 18:00}"
-- 3 (Wed)	"{09:00 12:00} {14:00 20:00}"
-- 4 (Thu)	"{09:00 18:00}"
-- 5 (Fri)	"{09:00 18:00}"
-- 6 (Sat)	"{09:00 12:00}"


create table im_sla_service_hours (
	sla_id			integer
				constraint im_sla_service_hours_sla_nn
				not null
				constraint im_sla_service_hours_sla_fk
				references im_projects,
	-- Day of Week. 0=Su, 1=Mo, 6=Sa
	dow			integer
				constraint im_sla_service_hours_dow_ck
				check(dow in (0, 1, 2, 3, 4, 5, 6)),
	-- List of tuples "{09:00 12:00} {14:00 20:00}" of HH24 hours with preceeding "0"
	service_hours		text,
	
	primary key (sla_id, dow)
);




-----------------------------------------------------------
-- DynFields
--
-- Setup the statically created "ticket_type_id" field as a DynField.

--		p_object_type		alias for $1;
--		p_column_name		alias for $2;
--		p_pretty_name		alias for $3;
--		p_widget_name		alias for $4;
--		p_datatype		alias for $5;
--		p_required_p		alias for $6;
--		p_pos_y			alias for $7;
--		p_also_hard_coded_p	alias for $8;
--		p_table_name		alias for $9;

SELECT im_dynfield_attribute_new (
	'im_sla_parameter', 'ticket_type_id', 'Ticket Type', 'ticket_type', 'integer', 'f', 30, 'f', 'im_sla_parameters'
);



SELECT im_dynfield_attribute_new (
	'im_sla_parameter', 'max_resolution_hours', 'Max Resolution Hours', 'numeric', 'integer', 'f', 900, 'f', 'im_sla_parameters'
);



-----------------------------------------------------------
-- Plugin Components
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system. The plugin shows the list of sla-management that are
-- associated with the specific object.
-- This way we can add sla-management to projects, users companies etc.
-- with only a single TCL/ADP page.
--
-- You can add/modify these plugin definitions in the Admin ->
-- Plugin Components page



-- Create a SLA-Management plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'SLA Parameters',		-- plugin_name
	'intranet-sla-management',	-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_sla_parameter_component -object_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-sla-management.SLA_Parameters "SLA Parameters"'
where plugin_name = 'SLA Parameters';


-- Show a list of associated objects in the SLAParameterViewPage
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'SLA Parameter Related Objects',	-- plugin_name
	'intranet-sla-management',	-- package_name
	'right',			-- location
	'/intranet-sla-management/new',	-- page_url
	null,				-- view_name
	50,				-- sort_order
	'im_biz_object_related_objects_component -object_id $param_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-sla-management.SLA_Parameter_Related_Objects "SLA Parameter Related Objects"'
where plugin_name = 'SLA Parameter Related Objects';


---------------------------------------------------------
-- Show indicators per SLA and parameter
--

select im_component_plugin__new (
		null,					-- plugin_id
		'im_component_plugin',			-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creattion_ip
		null,					-- context_id
	
		'SLA Indicators',			-- plugin_name
		'intranet-sla-management',		-- package_name
		'right',				-- location
		'/intranet/projects/view',		-- page_url
		null,					-- view_name
		60,					-- sort_order
		'im_sla_parameter_list_component -project_id $project_id',	-- TCL command
		'lang::message::lookup {} intranet-sla-management.SLA_Indicators {SLA Indicators}'
);

select im_grant_permission (
	(select plugin_id from im_component_plugins where plugin_name = 'SLA Indicators'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


select im_component_plugin__new (
		null,					-- plugin_id
		'im_component_plugin',			-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creattion_ip
		null,					-- context_id
	
		'Indicators',				-- plugin_name
		'intranet-sla-management',		-- package_name
		'right',				-- location
		'/intranet-sla-management/new',		-- page_url
		null,					-- view_name
		60,					-- sort_order
		'im_sla_parameter_list_component -param_id $param_id',	-- TCL command
		'lang::message::lookup {} intranet-sla-management.Indicators {Indicators}'
);

select im_grant_permission (
	(select plugin_id from im_component_plugins where plugin_name = 'Indicators' and package_name = 'intranet-sla-management'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



-- Show the working hours for the 7 days of the week
select im_component_plugin__new (
		null,					-- plugin_id
		'im_component_plugin',			-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creattion_ip
		null,					-- context_id
		'SLA Service Hours',			-- plugin_name
		'intranet-sla-management',		-- package_name
		'right',				-- location
		'/intranet/projects/view',		-- page_url
		null,					-- view_name
		80,					-- sort_order
		'im_sla_service_hours_component -project_id $project_id',	-- TCL command
		'lang::message::lookup {} intranet-sla-management.SLA_Service_Hours {SLA Service Hours}'
);

select im_grant_permission (
	(select plugin_id from im_component_plugins where plugin_name = 'SLA Service Hours'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);






-- Show the ticket_type x ticket_severity -> ticket_priority map
select im_component_plugin__new (
		null,					-- plugin_id
		'im_component_plugin',			-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creattion_ip
		null,					-- context_id
		'SLA Ticket Priority',			-- plugin_name
		'intranet-sla-management',		-- package_name
		'right',				-- location
		'/intranet/projects/view',		-- page_url
		null,					-- view_name
		90,					-- sort_order
		'im_ticket_priority_map_component -project_id $project_id',	-- TCL command
		'lang::message::lookup {} intranet-sla-management.SLA_Ticket_Prio {SLA Ticket Priority}'
);

select im_grant_permission (
	(select plugin_id from im_component_plugins where plugin_name = 'SLA Ticket Priority'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-- Show resolution time per ticket type within a SLA
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Resolution Time per Ticket Type',	-- plugin_name
	'intranet-sla-management',		-- package_name
	'right',				-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	140,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 200 \
-name "Resolution Time per Ticket Type" \
-object_id $project_id \
-restrict_to_object_type_id [im_project_type_sla] \
-sql "
		select	im_category_from_id(t.ticket_type_id) as ticket_type,
			coalesce(avg(t.ticket_resolution_time), 0)
		from	im_tickets t, im_projects p
		where	t.ticket_id = p.project_id and
			p.parent_id = %project_id%
		group by ticket_type_id
		order by ticket_type
"',
	'lang::message::lookup "" intranet-sla-management.Resolution_Time_per_Ticket_Type "Resolution Time per Ticket Type"'
);


SELECT acs_permission__grant_permission(
        (select plugin_id 
	from im_component_plugins 
	where plugin_name = 'Resolution Time per Ticket Type' and package_name = 'intranet-sla-management'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



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


-----------------------------------------------------------
-- Menu for SLA-Management
--
-- Create a menu item in the main menu bar and set some default 
-- permissions for various groups who should be able to see the menu.

-- Dont create an extra menu...

-- create or replace function inline_0 ()
-- returns integer as '
-- declare
-- 	-- Menu IDs
-- 	v_menu			integer;
-- 	v_main_menu		integer;
-- 	v_employees		integer;
-- 
-- BEGIN
-- 	-- Get some group IDs
-- 	select group_id into v_employees from groups where group_name = ''Employees'';
-- 
-- 	-- Determine the main menu. "Label" is used to
-- 	-- identify menus.
-- 	select menu_id into v_main_menu from im_menus where label=''main'';
-- 
-- 	-- Create the menu.
-- 	v_menu := im_menu__new (
-- 		null,				-- p_menu_id
-- 		''im_menu'',			-- object_type
-- 		now(),				-- creation_date
-- 		null,				-- creation_user
-- 		null,				-- creation_ip
-- 		null,				-- context_id
-- 		''intranet-sla-management'',	-- package_name
-- 		''sla-management'',		-- label
-- 		''SLAs'',			-- name
-- 		''/intranet-sla-management/'',	-- url
-- 		85,				-- sort_order
-- 		v_main_menu,			-- parent_menu_id
-- 		null				-- p_visible_tcl
-- 	);
-- 
-- 	-- Grant some groups the read permission for the main "SLA-Management" tab.
-- 	-- These permissions are independent from the user`s permission to
-- 	-- read the actual sla-management.
-- 	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
-- 
-- 	return 0;
-- end;' language 'plpgsql';
-- -- Execute and then drop the function
-- select inline_0 ();
-- drop function inline_0 ();

