-- /packages/intranet-riskmanagement/sql/postgresql/intranet-riskmanagement-create.sql
--
-- Copyright (c) 2003-2011 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Risks
--
-- Risks is a simple object that can be added to a project.

-- Create a new object type.
--
SELECT acs_object_type__create_type (
	'im_risk',			-- object_type - only lower case letters and "_"
	'Risk',				-- pretty_name - Human readable name
	'Risks',			-- pretty_plural - Human readable plural
	'acs_object',			-- supertype - "acs_object" is topmost object type.
	'im_risks',			-- table_name - where to store data for this object?
	'risk_id',			-- id_column - where to store object_id in the table?
	'intranet-riskmanagement',	-- package_name - name of this package
	'f',				-- abstract_p - abstract class or not
	null,				-- type_extension_table
	'im_risk__name'			-- name_method - a PL/SQL procedure that
					-- returns the name of the object.
);

-- Add additional meta information to allow DynFields to extend the im_risk object.
update acs_object_types set
	status_type_table = 'im_risks',		-- which table contains the status_id field?
	status_column = 'risk_status_id',	-- which column contains the status_id field?
	type_column = 'risk_type_id'		-- which column contains the type_id field?
where object_type = 'im_risk';

-- Tell the metadata system where to find the type of risks.
update acs_object_types set type_category_type = 'Intranet Risk Type' where object_type = 'im_risk';

-- Object Type Tables contain the lists of all tables (except for
-- acs_objects...) that contain information about an im_risk object.
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_risk', 'im_risks', 'risk_id');


-- Generic URLs to link to an object of type "im_risk".
-- These URLs are used by the Full-Text Search Engine and the Workflow
-- to show links to the object type.
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_risk','view','/intranet-riskmanagement/new?display_mode=display&risk_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_risk','edit','/intranet-riskmanagement/new?display_mode=edit&risk_id=');


-- This table stores one object per row. Links to super-type "acs_object" 
-- using the "risk_id" field, which contains the same object_id as 
-- acs_objects.object_id.
create table im_risks (
				-- The object_id: references acs_objects.object_id.
				-- So we can lookup object metadata such as creation_date,
				-- object_type etc in acs_objects.
	risk_id			integer
				constraint im_risk_id_pk
				primary key
				constraint im_risk_id_fk
				references acs_objects,
				-- Every risk should be associated with exactly one project.
	risk_project_id		integer
				constraint im_risk_project_nn
				not null
				constraint im_risk_project_fk
				references im_projects,
				-- Every ]po[ object should have a "status_id" to control
				-- its lifecycle. Status_id reference im_categories, where 
				-- you can define the list of stati for this object type.
	risk_status_id		integer 
				constraint im_risk_status_nn
				not null
				constraint im_risk_status_fk
				references im_categories,
				-- Every ]po[ object should have a "type_id" to allow creating
				-- sub-types of the object. Type_id references im_categories
				-- where you can define the list of subtypes per object type.
	risk_type_id		integer 
				constraint im_risk_type_nn
				not null
				constraint im_risk_type_fk
				references im_categories,
				-- This is the main content of a "risk". Just a piece of text.
	risk_name		text
				constraint im_risk_risk_nn
				not null,
				-- Probablility of the risk in percent
	risk_probability_percent numeric(12,1) default 0.0
				constraint im_risk_probability_ck
				check(risk_probability_percent >= 0.0 AND risk_probability_percent <= 100.0),
				-- financial impact measured in default currency
	risk_impact		numeric(12,1) default 0.0,
				-- Long description of a risk.
	risk_description	text
);


-- Speed up (frequent) queries to find all risks for a specific object.
create index im_risks_project_idx on im_risks(risk_project_id);

-- Don't allow two risks with the same name in the same project.
create unique index im_risks_project_un on im_risks(risk_project_id, risk_name);



-----------------------------------------------------------
-- Standard Dynfields for Risks
-----------------------------------------------------------

SELECT im_dynfield_attribute_new ('im_risk', 'risk_probability_percent', 'Probability (%)', 'numeric', 'float', 'f');
SELECT im_dynfield_attribute_new ('im_risk', 'risk_impact', 'Impact (default currency)', 'numeric', 'float', 'f');

-----------------------------------------------------------
-- PL/SQL functions to Create and Delete risks and to get
-- the name of a specific risk.
--
create or replace function im_risk__name(integer)
returns varchar as $body$
DECLARE
	p_risk_id		alias for $1;
	v_name			varchar;
BEGIN
	select	substring(risk_name)
	into	v_name from im_risks
	where	risk_id = p_risk_id;

	return v_name;
end; $body$ language 'plpgsql';


-- Create a new risk.
create or replace function im_risk__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	integer, integer, integer, varchar
) returns integer as $body$
DECLARE
	-- Default 6 parameters that go into the acs_objects table
	p_risk_id		alias for $1;		-- risk_id  default null
	p_object_type   	alias for $2;		-- object_type default im_risk
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	-- Specific parameters with data to go into the im_risks table
	-- Only those fields that are hard-coded and "not null"
	p_risk_project_id	alias for $7;		-- project container
	p_risk_status_id	alias for $8;		-- "active" or "inactive" or for WF stages
	p_risk_type_id		alias for $9;		-- user defined type of risk. Determines WF.
	p_risk_name		alias for $10;		-- Unique name of risk per project

	-- This is a variable for the PL/SQL function
	v_risk_id	integer;
BEGIN
	-- Create an acs_object as the super-type of the risk.
	-- (Do you remember, im_risk is a subtype of acs_object?)
	-- acs_object__new returns the object_id of the new object.
	v_risk_id := acs_object__new (
		p_risk_id,		-- object_id - NULL to create a new id
		p_object_type,		-- object_type - "im_risk"
		p_creation_date,	-- creation_date - now()
		p_creation_user,	-- creation_user - Current user or "0" for guest
		p_creation_ip,		-- creation_ip - IP from ns_conn, or "0.0.0.0"
		p_context_id,		-- context_id - NULL, not used in ]po[
		't'			-- security_inherit_p - not used in ]po[
	);
	
	-- Create an entry in the im_risks table with the same
	-- v_risk_id from acs_objects.object_id
	insert into im_risks (
		risk_id, risk_project_id,
		risk_status_id, risk_type_id,
		risk_name
	) values (
		v_risk_id, p_risk_project_id,
		p_risk_status_id, p_risk_type_id,
		p_risk_name
	);

	return v_risk_id;
END;$body$ language 'plpgsql';


-- Delete a risk from the system.
create or replace function im_risk__delete(integer)
returns integer as $body$
DECLARE
	p_risk_id	alias for $1;
BEGIN
	-- Delete any data related to the object
	delete	from im_risks
	where	risk_id = p_risk_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_risk_id);

	return 0;
end;$body$ language 'plpgsql';




-----------------------------------------------------------
-- Categories for Type and Status
--
-- 75000-75999  Intranet Risk Management (1000)
-- 75000-75099  Intranet Risk Status (100)
-- 75100-75199  Intranet Risk Type (100)
-- 75200-75299	Intranet Risk Action (100)

-- Status
SELECT im_category_new (75000, 'Active', 'Intranet Risk Status');
SELECT im_category_new (75002, 'Deleted', 'Intranet Risk Status');

-- Type
SELECT im_category_new (75100, 'Default', 'Intranet Risk Type');

-- Action
SELECT im_category_new (75210, 'Delete', 'Intranet Risk Action');


-----------------------------------------------------------
-- Create views for shortcut
--
-- These views are optional.

create or replace view im_risk_status as
select	category_id as risk_status_id, category as risk_status
from	im_categories
where	category_type = 'Intranet Risks Status'
	and enabled_p = 't';

create or replace view im_risk_types as
select	category_id as risk_type_id, category as risk_type
from	im_categories
where	category_type = 'Intranet Risks Type'
	and enabled_p = 't';



-----------------------------------------------------------
-- Plugin Components
--

-- List of Risks per project
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Risks',		-- plugin_name
	'intranet-riskmanagement',	-- package_name
	'left',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	30,				-- sort_order
	'im_risk_project_component -project_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-riskmanagement.Project_Risks "Project Risks"'
where plugin_name = 'Project Risks';



-----------------------------------------------------------
-- Risk View Columns
-----------------------------------------------------------

-- 210-219              Riskmanagement

delete from im_view_columns where view_id = 210;
delete from im_views where view_id = 210;
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (210, 'im_risk_list_short', 'view_risks', 1400);


-- Add a "select all" checkbox to select all risks in the list
delete from im_view_columns where column_id = 21099;
insert into im_view_columns (
        column_id, view_id, sort_order,
	column_name,
	column_render_tcl,
        visible_for
) values (
        21000, 210, 0,
        '<input type=checkbox name=_dummy onclick="acs_ListCheckAll(''risk'',this.checked)">',
        '"<input type=checkbox name=risk_id.$risk_id id=risk.$risk_id>"',
        ''
);

delete from im_view_columns where column_id = 21010;
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(21010, 210, 10, 'Name', '"<a href=[export_vars -base "/intranet-riskmanagement/new" {{form_mode display} risk_id return_url}]>$risk_name</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(21030,210,30,'Type','$risk_type');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(21040,210,40,'Status','$risk_status');


insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(21070,210,70,'Impact','$risk_impact');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(21080,210,80,'Percent','$risk_probability_percent');

