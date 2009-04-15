--
-- packages/intranet-dynfield/sql/postgresql/intranet-dynfield-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @author Frank Bergmann frank.bergmann@project-open.com
-- @author Juanjo Ruiz juanjoruizx@yahoo.es
-- @creation-date 2005-01-04
--
--


alter table acs_object_types add column status_category_type varchar(50);
alter table acs_object_types add column type_category_type varchar(50);

update acs_object_types set type_category_type = 'Intranet Absence Type' where object_type = 'im_user_absence';
update acs_object_types set type_category_type = 'Intranet Company Type' where object_type = 'im_company';
update acs_object_types set type_category_type = 'Intranet Cost Center Type' where object_type = 'im_cost_center';
update acs_object_types set type_category_type = 'Intranet Cost Type' where object_type = 'im_cost';
update acs_object_types set type_category_type = 'Intranet Expense Type' where object_type = 'im_expense';
update acs_object_types set type_category_type = 'Intranet Freelance RFQ Type' where object_type = 'im_freelance_rfq';
update acs_object_types set type_category_type = 'Intranet Investment Type' where object_type = 'im_investment';
update acs_object_types set type_category_type = 'Intranet Cost Type' where object_type = 'im_invoice';
update acs_object_types set type_category_type = 'Intranet Material Type' where object_type = 'im_material';
update acs_object_types set type_category_type = 'Intranet Office Type' where object_type = 'im_office';
update acs_object_types set type_category_type = 'Intranet Payment Type' where object_type = 'im_payment';
update acs_object_types set type_category_type = 'Intranet Project Type' where object_type = 'im_project';
update acs_object_types set type_category_type = 'Intranet Report Type' where object_type = 'im_report';
update acs_object_types set type_category_type = 'Intranet Timesheet2 Conf Type' where object_type = 'im_timesheet_conf_object';
update acs_object_types set type_category_type = 'Intranet Timesheet Task Type' where object_type = 'im_timesheet_task';
update acs_object_types set type_category_type = 'Intranet Topic Type' where object_type = 'im_forum_topic';
update acs_object_types set type_category_type = 'Intranet User Type' where object_type = 'person';


-- 22000-22999 Intranet User Type
SELECT im_category_new(22000, 'Registered Users', 'Intranet User Type');
SELECT im_category_new(22010, 'The Public', 'Intranet User Type');
SELECT im_category_new(22020, 'P/O Admins', 'Intranet User Type');
SELECT im_category_new(22030, 'Customers', 'Intranet User Type');
SELECT im_category_new(22040, 'Employees', 'Intranet User Type');
SELECT im_category_new(22050, 'Freelancers', 'Intranet User Type');
SELECT im_category_new(22060, 'Project Managers', 'Intranet User Type');
SELECT im_category_new(22070, 'Senior Managers', 'Intranet User Type');
SELECT im_category_new(22080, 'Accounting', 'Intranet User Type');
SELECT im_category_new(22090, 'Sales', 'Intranet User Type');
SELECT im_category_new(22100, 'HR Managers', 'Intranet User Type');
SELECT im_category_new(22110, 'Freelance Managers', 'Intranet User Type');



create table im_dynfield_type_attribute_map (
	attribute_id		integer
				constraint im_dynfield_type_attr_map_attr_fk
				references acs_objects,
	object_type_id		integer
				constraint im_dynfield_type_attr_map_otype_nn
				not null
				constraint im_dynfield_type_attr_map_otype_fk
				references im_categories,
	display_mode		varchar(10)
				constraint im_dynfield_type_attr_map_dmode_nn
				not null
				constraint im_dynfield_type_attr_map_dmode_ck
				check (display_mode in ('edit', 'display', 'none')),
	help_text		text,
	unique (attribute_id, object_type_id)
);


-- ------------------------------------------------------------------
-- AMS Compatibility
-- ------------------------------------------------------------------

-- AMS Compatibility view
create or replace view ams_lists as
select 
	c.category_id as list_id, 
	'contacts'::varchar as package_key, 
	aot.object_type, 
	c.category as list_name, 
	c.category as pretty_name, 
	''::varchar as description, 
	'text/plain'::varchar as description_mime_type 
from 
	acs_object_types aot, 
	im_categories c 
where 
	aot.type_category_type is not null 
	and aot.type_category_type = c.category_type;

-- AMS Compatibility view
create or replace view ams_list_attribute_map as
select
	tam.object_type_id as list_id,
	da.acs_attribute_id as attribute_id,
	0::integer as sort_order,
	false::boolean as required_p,
	''::varchar as section_heading,
	''::varchar as html_options
from
	im_dynfield_type_attribute_map tam,
	im_dynfield_attributes da
where
	tam.attribute_id = da.attribute_id;



-- ------------------------------------------------------------------
-- Widgets
-- ------------------------------------------------------------------

select acs_object_type__create_type (
	'im_dynfield_widget',		-- object_type
	'Dynfield Widget',		-- pretty_name
	'Dynfield Widgets',		-- pretty_plural
	'acs_object',			-- supertype
	'im_dynfield_widgets',		-- table_name
	'widget_id',			-- id_column
	'intranet-dynfield',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_dynfield_widget__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_dynfield_widget', 'im_dynfield_widgets', 'widget_id');

create table im_dynfield_widgets (
	widget_id		integer
				constraint im_dynfield_widgets_fk
				references acs_objects
				constraint im_dynfield_widgets_pk
				primary key,
	widget_name		text
				constraint im_dynfield_widgets_name_nn
				not null
				constraint im_dynfield_widgets_name_un
				unique,
	pretty_name		text
				constraint im_dynfield_widgets_pretty_n_nn 
				not null,
	pretty_plural		text
				constraint im_dynfield_widgets_pretty_pl_nn 
				not null,
	storage_type_id		integer
				constraint im_dynfield_widgets_stor_typ_nn 
				not null
				constraint contact_widgets_stor_typ_fk 
				references im_categories,
	acs_datatype		varchar(50)
				constraint im_dynfield_widgets_acs_typ_nn 
				not null
				constraint im_dynfield_widgets_acs_typ_fk 
				references acs_datatypes(datatype),
	widget			varchar(20) 
				constraint im_dynfield_widgets_widget_nn 
				not null,
	sql_datatype		text
				constraint im_dynfield_widgets_datatype_nn 
				not null,
	parameters		text,
				-- Name of a PlPg/SQL function to convert a 
				-- reference (integer, timestamptz) into a
				-- printable value. Example: im_name_from_user_id,
				-- im_cost_center_name_from_id
	deref_plpgsql_function	text default 'im_name_from_id'
);



-- ------------------------------------------------------------------
-- Attributes
-- ------------------------------------------------------------------


select acs_object_type__create_type (
	'im_dynfield_attribute',
	'Dynfield Attribute',
	'Dynfield Attributes',
	'acs_object',
	'im_dynfield_attributes',
	'attribute_id',
	'im_dynfield_attribute',
	'f',
	null,
	'im_dynfield_attribute__name'
);


create table im_dynfield_attributes (
	attribute_id		integer
				constraint im_dynfield_attr_attr_id_fk 
				references acs_objects
				constraint im_dynfield_attr_attr_id_pk 
				primary key,
	acs_attribute_id	integer
				constraint im_dynfield_attr_attribute_id_fk 
				references acs_attributes
				constraint im_dynfield_attr_attribute_id_nn 
				not null,
	widget_name		text
				constraint im_dynfield_attr_widget_name_fk 
				references im_dynfield_widgets(widget_name)
				constraint im_dynfield_attr_widget_name_nn 
				not null,
	-- Determines if the database column should be deleted
	-- when the im_dynfield_attribute is deleted.
	-- => Delete only if the attribute didn't already_existed_p.
	already_existed_p	char default 't'
				constraint im_dynfield_attr_existed_nn 
				not null,	
	deprecated_p		char default 'f'
				constraint im_dynfield_attr_deprecated_nn 
				not null,
				-- Should the field be included in intranet-search-pg?
	include_in_search_p	char(1) default 'f'
				constraint im_dynfield_attributes_search_ch
				check (include_in_search_p in ('t','f')),
	also_hard_coded_p	char(1) default 'f'
				constraint im_dynfield_attributes_also_hard_coded_ch
				check (also_hard_coded_p in ('t','f'))
);

-- Make acs_attribute unique, so that no two dynfield_attributes can reference the same acs_attrib.
alter table im_dynfield_attributes add constraint
im_dynfield_attributes_acs_attribute_un UNIQUE (acs_attribute_id);


create table im_dynfield_type_attribute_map (
	attribute_id		integer
				constraint im_dynfield_type_attr_map_attr_fk
				references acs_objects,
	object_type_id		integer 
				constraint im_dynfield_type_attr_map_otype_nn
				not null
				constraint im_dynfield_type_attr_map_otype_fk
				references im_categories,
	display_mode		varchar(10)
				constraint im_dynfield_type_attr_map_dmode_nn
				not null
				constraint im_dynfield_type_attr_map_dmode_ck
				check (display_mode in ('edit', 'display', 'none')),
	unique (attribute_id, object_type_id)
);

comment on table im_dynfield_type_attribute_map is '
This map allows us to specify whether a DynField attribute should
appear in a Edit/NewPage of an object, and whether it should appear
in edit or display mode.
The table maps the objects type_id (such as project_type_id, company_type_id
etc.) to the "display_mode" for the DynField attribute.
The display mode is "edit" if there is no entry in this map table.
';


-- ------------------------------------------------------------------
-- dynfield_attr_multi_value
-- ------------------------------------------------------------------

-- Allows to store multi-value widget values that dont fit in the
-- objects table such as a multiple select box.

create table im_dynfield_attr_multi_value (
	attribute_id 		integer not null
				constraint flex_attr_multi_val_attr_id_fk
				references im_dynfield_attributes,
	object_id		integer not null
				constraint flex_attr_multi_val_obj_id_fk 
				references acs_objects,
	value			text,
	sort_order		integer				
);


-- ToDo: Add indices



-- ------------------------------------------------------------------
-- dynfield_cat_multi_value
-- ------------------------------------------------------------------

-- Allows to store multi-value category values that dont fit in the
-- objects table such as a multiple select box or category based checkbox

create table im_dynfield_cat_multi_value (
	attribute_id		integer not null
				constraint cat_multi_val_attr_id_fk
				references im_dynfield_attributes,
	object_id		 integer not null
				constraint cat_multi_val_obj_id_fk
				references acs_objects,
	category_id		integer not null
				constraint cat_multi_val_cat_id_fk
				references im_categories
);



-- ------------------------------------------------------------------
-- Layout
-- ------------------------------------------------------------------


create table im_dynfield_layout_pages (
	page_url		text
				constraint im_dynfield_layout_page_nn
				not null,
	object_type		varchar(100)
				constraint im_dynfield_ly_page_object_nn
				not null
				constraint im_dynfield_ly_page_object_fk
				references acs_object_types,
	layout_type		varchar(15)
				constraint im_dynfield_layout_type_nn
				not null
				constraint im_dynfield_layout_type_ck
				check (layout_type in ('absolute', 'relative',
					'table', 'div_absolute', 'div_relative', 'adp')),
	table_height		integer,
	table_width		integer,
	adp_file		text,
	default_p		char(1) default 'f'
				constraint im_dynfield_layout_default_nn
				not null
				constraint im_dynfield_layout_default_ck
				check (default_p in ( 't','f' ))
);

alter table im_dynfield_layout_pages add 
  constraint im_dynfield_layout_pages_pk primary key (page_url, object_type)
;


create table im_dynfield_layout (
	attribute_id		integer
				constraint im_dynfield_layout_attribute_nn
				not null
				constraint im_dynfield_layout_attribute_fk
				references im_dynfield_attributes,
	page_url		text,
	object_type		varchar(100)
				constraint im_dynfield_layout_object_type_nn
				not null,
	-- Pos + size is interpreted according to layout type.
	-- Default is a table layout with col/row and colspan/rowspan.
	pos_x			integer,
	pos_y			integer,
	size_x			integer,
	size_y			integer,
	-- How to display the label? "no_label" is useful for combined
	-- fields (currency_code field of a monetary amount), "plain"
	-- just shows the label in the column before the widget.
	label_style		varchar(15) default 'table'
				constraint im_dynfield_label_style_nn
				not null
				constraint im_dynfield_label_style_ck
				check (label_style in ('plain', 'table', 'div_absolute', 'div_relative', 'div', 'adp')),
	div_class		text,
	sort_key		integer
);

alter table im_dynfield_layout 
add constraint im_dynfield_layout_pk 
primary key (attribute_id, page_url, object_type);


-- Skip the foreign key meanwhile so that we dont have to add the 
-- page_layout for the beginning. By default, a "table" layout will
-- be used.
--
-- alter table im_dynfield_layout add
--   constraint im_dynfield_layout_fk foreign key (page_url, object_type) 
--   references im_dynfield_layout_pages(page_url, object_type)
-- ;






-- ------------------------------------------------------------------
-- Next Generation Layout
-- NOT used yet!
-- ------------------------------------------------------------------

select acs_object_type__create_type (
	'im_dynfield_page',		-- object_type
	'Dynfield Page',		-- pretty_name
	'Dynfield Pages',		-- pretty_plural
	'acs_object',			-- supertype
	'im_dynfield_pages',		-- table_name
	'page_id',			-- id_column
	'intranet-dynfield',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_dynfield_page__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_dynfield_page', 'im_dynfield_pages', 'page_id');


create table im_dynfield_pages (
	page_id			integer
				constraint im_dynfield_pages_pk
				primary key,
	object_type		varchar(100)
				constraint im_dynfield_ly_page_object_nn 
				not null
				constraint im_dynfield_ly_page_object_fk
				references acs_object_types,
	page_status_id		integer
				constraint im_dynfield_pages_status_fk
				references im_categories,
	page_type_id		integer
				constraint im_dynfield_pages_type_fk
				references im_categories,

	page_url		varchar(1000)
				constraint im_dynfield_pages_nn
				not null,
	workflow_key		varchar(100)
				constraint im_dynfield_pages_workflow_key_fk
				references wf_workflows,
	transition_key		varchar(100)
				constraint im_dynfield_pages_transition_key_fk
				references wf_transitions,

	layout_type		varchar(15)
				constraint im_dynfield_layout_type_nn
				not null
				constraint im_dynfield_layout_type_ck
				check (layout_type in ('absolute', 'relative',
				'table', 'div_absolute', 'div_relative', 'adp')),
	table_height		integer,
	table_width		integer,
	adp_file		varchar(400),
	default_p		char(1) default 'f'
				constraint im_dynfield_layout_default_nn
				not null
				constraint im_dynfield_layout_default_ck
				check (default_p in ( 't','f' ))
);

alter table im_dynfield_pages add constraint
im_dynfield_layout_pages_un UNIQUE (object_type, page_url, workflow_key, transition_key);



select acs_object_type__create_type (
	'im_dynfield_page_attribute',		-- object_type
	'Dynfield Page Attribute',		-- pretty_name
	'Dynfield Page Attributes',		-- pretty_plural
	'acs_object',				-- supertype
	'im_dynfield_page_attributes',		-- table_name
	'attribute_id',				-- id_column
	'intranet-dynfield',			-- package_name
	'f',					-- abstract_p
	null,					-- type_extension_table
	'im_dynfield_page_attribute__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_dynfield_page_attribute', 'im_dynfield_page_attributes', 'attribute_id');

create table im_dynfield_page_fields (
	field_id		integer
				constraint im_dynfield_page_fields_pk
				primary key,
	page_id			integer
				constraint im_dynfield_page_attributes_page_nn
				not null
				constraint im_dynfield_page_attributes_page_fk
				references im_dynfield_pages,
	attribute_id		integer
				constraint im_dynfield_page_attributes_nn
				not null
				constraint im_dynfield_page_attributes_fk
				references im_dynfield_attributes,

	field_status_id		integer
				constraint im_dynfield_fields_status_fk
				references im_categories,
	field_type_id		integer
				constraint im_dynfield_fields_type_fk
				references im_categories,

	-- Pos + size is interpreted according to layout type.
	-- Default is a table layout with col/row and colspan/rowspan.
	pos_x			integer,
	pos_y			integer,
	size_x			integer,
	size_y			integer,

	-- How to display the label? "no_label" is useful for combined
	-- fields (currency_code field of a monetary amount), "plain"
	-- just shows the label in the column before the widget.
	label_style		varchar(15) default 'table'
				constraint im_dynfield_label_style_nn
				not null
				constraint im_dynfield_label_style_ck
				check (label_style in ('table', 'div_absolute', 'div_relative', 'div', 'adp')),
	div_class		varchar(400),
	sort_key		integer
);




---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Core to render the 
-- forum components in the Home, Users, Projects and Company pages.
--
-- The TCL code in the "component_tcl" field is executed
-- via "im_component_bay" in an "uplevel" statemente, exactly
-- as if it would be written inside the .adp <%= ... %> tag.
-- I know that's relatively dirty, but TCL doesn't provide
-- another way of "late binding of component" ...


-- Setup the "Dynfield" main menu entry

create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select menu_id into v_admin_menu from im_menus where label=''admin'';

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-dynfield'',  -- package_name
		''dynfield_admin'',	-- label
		''DynField'',		-- name
		''/intranet-dynfield/'',-- url
		750,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_otype',				-- label
	'Object Types',					-- name
	'/intranet-dynfield/object-types',		-- url
	10,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_permission',				-- label
	'Permissions',					-- name
	'/intranet-dynfield/permissions',		-- url
	20,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_widgets',				-- label
	'Widgets',					-- name
	'/intranet-dynfield/widgets',			-- url
	100,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_widget_examples',			-- label
	'Widget Examples',				-- name
	'/intranet-dynfield/widget-examples',		-- url
	110,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_doc',					-- label
	'Documentation',				-- name
	'/doc/intranet-dynfield/',			-- url
	900,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);



----------------------------------------------------------
-- Object Types

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_absences',				-- label
	'Absence',						-- name
	'/intranet-dynfield/object-type?object_type=im_user_absence', -- url
	100,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_companies',				-- label
	'Company',						-- name
	'/intranet-dynfield/object-type?object_type=im_company', -- url
	110,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_expenses',				-- label
	'Expense',						-- name
	'/intranet-dynfield/object-type?object_type=im_expense', -- url
	120,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_freelance_rfqs',			-- label
	'Freelance RFQ',					-- name
	'/intranet-dynfield/object-type?object_type=im_freelance_rfq', -- url
	130,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);
SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_freelance_rfq_answers',			-- label
	'Freelance RFQ Answer',					-- name
	'/intranet-dynfield/object-type?object_type=im_freelance_rfq_answer', -- url
	140,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_offices',				-- label
	'Offices',						-- name
	'/intranet-dynfield/object-type?object_type=im_office', -- url
	150,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_persons',				-- label
	'Persons',						-- name
	'/intranet-dynfield/object-type?object_type=person', -- url
	160,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_projects',				-- label
	'Projects',						-- name
	'/intranet-dynfield/object-type?object_type=im_project', -- url
	170,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);



---------------------------------------------------------
-- Setup DynField Widgets Data
---------------------------------------------------------

create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar, 
	varchar, varchar
) returns integer as '
DECLARE
	p_widget_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_widget_name		alias for $7;
	p_pretty_name		alias for $8;
	p_pretty_plural		alias for $9;
	p_storage_type_id	alias for $10;
	p_acs_datatype		alias for $11;
	p_widget		alias for $12;
	p_sql_datatype		alias for $13;
	p_parameters		alias for $14;

	v_widget_id		integer;
BEGIN
	select widget_id into v_widget_id from im_dynfield_widgets
	where widget_name = p_widget_name;
	if v_widget_id is not null then return v_widget_id; end if;

	v_widget_id := acs_object__new (
		p_widget_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_widgets (
		widget_id, widget_name, pretty_name, pretty_plural,
		storage_type_id, acs_datatype, widget, sql_datatype, parameters
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters
	);
	return v_widget_id;
end;' language 'plpgsql';


create or replace function im_dynfield_widget__del (integer) returns integer as '
DECLARE
	p_widget_id		alias for $1;
BEGIN
	-- Erase the im_dynfield_widgets item associated with the id
	delete from im_dynfield_widgets
	where widget_id = p_widget_id;

	-- Erase all the privileges
	delete from acs_permissions
	where object_id = p_widget_id;

	PERFORM acs_object__del(v_widget_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_dynfield_widget__name (integer) returns varchar as '
DECLARE
	p_widget_id		alias for $1;
	v_name			varchar;
BEGIN
	select	widget_name
	into	v_name
	from	im_dynfield_widgets
	where	widget_id = p_widget_id;

	return v_name;
end;' language 'plpgsql';


-- ------------------------------------------------------------------
-- Package
-- ------------------------------------------------------------------


create or replace function im_dynfield_attribute__new_only_dynfield (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, varchar, char(1), char(1)
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_acs_attribute_id	alias for $7;
	p_widget_name		alias for $8;
	p_deprecated_p		alias for $9;
	p_already_existed_p	alias for $10;

	v_attribute_id		integer;
BEGIN
	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, p_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);
	return v_attribute_id;
end;' language 'plpgsql';


create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char, char
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_attribute_object_type	alias for $7;
	p_attribute_name	alias for $8;
	p_min_n_values		alias for $9;
	p_max_n_values		alias for $10;
	p_default_value		alias for $11;

	p_datatype		alias for $12;
	p_pretty_name		alias for $13;
	p_pretty_plural		alias for $14;
	p_widget_name		alias for $15;
	p_deprecated_p		alias for $16;
	p_already_existed_p	alias for $17;
	p_table_name		alias for $18;

	v_acs_attribute_id	integer;
	v_attribute_id		integer;
BEGIN
	select attribute_id into v_acs_attribute_id from acs_attributes
	where object_type = p_attribute_object_type and attribute_name = p_attribute_name;

	IF v_acs_attribute_id is null THEN
		v_acs_attribute_id := acs_attribute__create_attribute (
		p_attribute_object_type,
		p_attribute_name,
		p_datatype,
		p_pretty_name,
		p_pretty_plural,
		p_table_name,		-- table_name
		null,			-- column_name
		p_default_value,
		p_min_n_values,
		p_max_n_values,
		null,			-- sort order
		''type_specific'',	-- storage
		''f''			-- static_p
		);
	END IF;

	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, v_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);

	-- By default show the field for all object types
	insert into im_dynfield_type_attribute_map (attribute_id, object_type_id, display_mode)
	select	ida.attribute_id,
		c.category_id,
		''edit''
	from	im_dynfield_attributes ida,
		acs_attributes aa,
		acs_object_types aot,
		im_categories c
	where	ida.acs_attribute_id = aa.attribute_id and
		aa.object_type = aot.object_type and
		aot.type_category_type = c.category_type and
		aot.object_type = p_attribute_object_type and
		aa.attribute_name = p_attribute_name;

	return v_attribute_id;
end;' language 'plpgsql';

-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1), integer, char(1),varchar
) RETURNS integer as '
DECLARE
	p_object_type		alias for $1;
	p_column_name		alias for $2;
	p_pretty_name		alias for $3;
	p_widget_name		alias for $4;
	p_datatype		alias for $5;
	p_required_p		alias for $6;
	p_pos_y			alias for $7;
	p_also_hard_coded_p	alias for $8;
	p_table_name	 	alias for $9;

	v_dynfield_id		integer;
	v_widget_id		integer;
	v_type_category		varchar;
	row			RECORD;
	v_count			integer;
	v_min_n_value		integer;
BEGIN
	select	widget_id into v_widget_id from im_dynfield_widgets
	where	widget_name = p_widget_name;
	IF v_widget_id is null THEN return 1; END IF;

	select	count(*) from im_dynfield_attributes into v_count
	where	acs_attribute_id in (
			select	attribute_id 
			from	acs_attributes 
			where	attribute_name = p_column_name and
				object_type = p_object_type
		);
	IF v_count > 0 THEN return 1; END IF;

	v_min_n_value := 0;
	IF p_required_p = ''t'' THEN  v_min_n_value := 1; END IF;

	v_dynfield_id := im_dynfield_attribute__new (
		null, ''im_dynfield_attribute'', now(), 0, ''0.0.0.0'', null,
		p_object_type, p_column_name, v_min_n_value, 1, null,
		p_datatype, p_pretty_name, p_pretty_name, p_widget_name,
		''f'', ''f'', p_table_name
	);

	update im_dynfield_attributes set also_hard_coded_p = p_also_hard_coded_p
	where attribute_id = v_dynfield_id;

	insert into im_dynfield_layout (
		attribute_id, page_url, pos_y, label_style
	) values (
		v_dynfield_id, ''default'', p_pos_y, ''table''
	);

	-- set all im_dynfield_type_attribute_map to "edit"
	select type_category_type into v_type_category from acs_object_types
	where object_type = p_object_type;
	FOR row IN
		select	category_id
		from	im_categories
		where	category_type = v_type_category
	LOOP
		select	count(*) into v_count from im_dynfield_type_attribute_map
		where	object_type_id = row.category_id and attribute_id = v_dynfield_id;
		IF 0 = v_count THEN
			insert into im_dynfield_type_attribute_map (
				attribute_id, object_type_id, display_mode
			) values (
				v_dynfield_id, row.category_id, ''edit''
			);
		END IF;
	END LOOP;

	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Employees''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Employees''), ''write'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Customers''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Customers''), ''write'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Freelancers''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Freelancers''), ''write'');

	RETURN v_dynfield_id;
END;' language 'plpgsql';

-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1), integer, char(1)
) RETURNS integer as '
DECLARE
	p_object_type		alias for $1;
	p_column_name		alias for $2;
	p_pretty_name		alias for $3;
	p_widget_name		alias for $4;
	p_datatype		alias for $5;
	p_required_p		alias for $6;
	p_pos_y			alias for $7;
	p_also_hard_coded_p	alias for $8;

	v_table_name		varchar;
BEGIN
	select table_name into v_table_name
	from acs_object_types where object_type = p_object_type;

	RETURN im_dynfield_attribute_new($1,$2,$3,$4,$5,$6,null,''f'',v_table_name);
END;' language 'plpgsql';

-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1)
) RETURNS integer as '
BEGIN
	RETURN im_dynfield_attribute_new($1,$2,$3,$4,$5,$6,null,''f'');
END;' language 'plpgsql';




-- Delete a single attribute (if we know its ID...)
create or replace function im_dynfield_attribute__del (integer) returns integer as '
DECLARE
	p_attribute_id		alias for $1;

	v_acs_attribute_id	integer;
	v_acs_attribute_name	varchar;
	v_object_type		varchar;
BEGIN
	-- get the acs_attribute_id and object_type
	select
		fa.acs_attribute_id, 
		aa.object_type,
		aa.attribute_name
	into 
		v_acs_attribute_id, 
		v_object_type,
		v_acs_attribute_name
	from
		im_dynfield_attributes fa,
		acs_attributes aa
	where
		aa.attribute_id = fa.acs_attribute_id
		and fa.attribute_id = p_attribute_id;

	-- Erase the im_dynfield_attributes item associated with the id
	delete from im_dynfield_layout
	where attribute_id = p_attribute_id;

	-- Erase values for the im_dynfield_attribute item associated with the id
	delete from im_dynfield_attr_multi_value
	where attribute_id = p_attribute_id;

	delete from im_dynfield_attributes
	where attribute_id = p_attribute_id;

	PERFORM acs_attribute__drop_attribute(v_object_type, v_acs_attribute_name);
	return 0;
end;' language 'plpgsql';


create or replace function im_dynfield_attribute__name (integer) returns varchar as '
DECLARE
	p_attribute_id		alias for $1;
	v_name			varchar;
	v_acs_attribute_id	integer;
BEGIN
	-- get the acs_attribute_id
	select	acs_attribute_id
	into	v_acs_attribute_id
	from	im_dynfield_attributes
	where	attribute_id = p_attribute_id;

	select  attribute_name
	into	v_name
	from	acs_attributes
	where   attribute_id = v_acs_attribute_id;

	return v_name;
end;' language 'plpgsql';


-- return a string coma separated with multimap values
create or replace function im_dynfield_multimap_val_to_str (integer, integer, varchar) 
returns varchar as '
DECLARE
	p_attr_id		alias for $1;
	p_obj_id		alias for $2;
	p_widget_type		alias for $3;

	v_ret_string		varchar;
	v_value			im_dynfield_attr_multi_value.value%TYPE;
	v_cat_name		varchar;
	row			RECORD;
BEGIN
	v_ret_string := null;
	FOR row IN
		SELECT	v_value
		FROM	im_dynfield_attr_multi_value
		WHERE	attribute_id = p_attr_id
			AND object_id = p_obj_id
			AND value is not null
	LOOP 
		if v_ret_string is not null then 
			v_ret_string := v_ret_string || '', '';
		end if; 
	
		if widget_type = ''category_tree'' then
			select category.name(row.v_value) into v_cat_name from dual;
			v_ret_string := v_ret_string || v_cat_name;
		else
			v_ret_string := v_ret_string || row.v_value;
		end if;
	END LOOP;
		
	return v_ret_string;
end;' language 'plpgsql';


-- ------------------------------------------------------------------
-- Storage Type Population
-- ------------------------------------------------------------------

-- 10000-10999  Intranet DynField


SELECT im_category_new ('10001', 'time', 'Intranet DynField Storage Type');
SELECT im_category_new ('10003', 'date', 'Intranet DynField Storage Type');
SELECT im_category_new ('10005', 'multimap', 'Intranet DynField Storage Type');
SELECT im_category_new ('10007', 'value', 'Intranet DynField Storage Type');
SELECT im_category_new ('10009', 'value_with_mime_type', 'Intranet DynField Storage Type');


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'date',			-- widget_name
	'#intranet-dynfield.Date#',	-- pretty_name
	'#intranet-dynfield.Date#',	-- pretty_plural
	10001,			-- storage_type_id
	'date',			-- acs_datatype
	'date',			-- widget
	'date',			-- sql_datatype
	'{help}'		-- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'gender_select',	-- widget_name
	'#intranet-dynfield.Gender_Select#',	-- pretty_name
	'#intranet-dynfield.Gender_Select#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'select',		-- widget
	'string',		-- sql_datatype
	'{options {{Male m} {Female f}}}' -- parameters
);



select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'integer',		-- widget_name
	'#intranet-dynfield.Integer#',	-- pretty_name
	'#intranet-dynfield.Integer#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'text',			-- widget
	'integer',		-- sql_datatype
	'{html {size 6 maxlength 100}}' -- parameters
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'textbox_small',	-- widget_name
	'#intranet-dynfield.Textbox# #intranet-dynfield.Small#',	-- pretty_name
	'#intranet-dynfield.Textboxes# #intranet-dynfield.Small#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'text',			-- widget
	'text',			-- sql_datatype
	'{html {size 18 maxlength 30}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'textbox_medium',	-- widget_name
	'#intranet-dynfield.Textbox# #intranet-dynfield.Medium#',	-- pretty_name
	'#intranet-dynfield.Textboxes# #intranet-dynfield.Medium#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'text',			-- widget
	'text',			-- sql_datatype
	'{html {size 30 maxlength 100}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'textbox_large',	-- widget_name
	'#intranet-dynfield.Textbox# #intranet-dynfield.Large#',	-- pretty_name
	'#intranet-dynfield.Textboxes# #intranet-dynfield.Large#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'text',			-- widget
	'text',			-- sql_datatype
	'{html {size 50 maxlength 400}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'textarea_small',	-- widget_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'textarea',		-- widget
	'text',			-- sql_datatype
	'{html {cols 60 rows 4} validate {check_area}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'textarea_small_nospell',	-- widget_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'textarea',		-- widget
	'text',			-- sql_datatype
	'{html {cols 60 rows 4} {nospell}}' -- parameters
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'checkbox',		-- widget_name
	'#intranet-dynfield.Checkbox#',	-- pretty_name
	'#intranet-dynfield.Checkboxes#',	-- pretty_plural
	10007,			-- storage_type_id
	'boolean',		-- acs_datatype
	'checkbox',		-- widget
	'char(1)',		-- sql_datatype
	'{options {{"" t}}}'	-- parameters
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'category_company_type',	-- widget_name
	'#intranet-core.Company_Type#',	-- pretty_name
	'#intranet-core.Company_Types#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{custom {category_type "Intranet Company Type"}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'category_company_status',	-- widget_name
	'#intranet-core.Company_Status#',	-- pretty_name
	'#intranet-core.Company_Statuss#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{custom {category_type "Intranet Company Status"}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'category_office_type',	-- widget_name
	'#intranet-core.Office_Type#',	-- pretty_name
	'#intranet-core.Office_Types#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{custom {category_type "Intranet Office Type"}}' -- parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',   -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'category_office_status',	-- widget_name
	'#intranet-core.Office_Status#',	-- pretty_name
	'#intranet-core.Office_Statuss#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{custom {category_type "Intranet Office Status"}}' -- parameters
);

select im_dynfield_widget__new (
	null,				-- widget_id
	'im_dynfield_widget',   	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'category_invoice_template',	-- widget_name
	'#intranet-core.Template#',	-- pretty_name
	'#intranet-core.Template#',	-- pretty_plural
	10007,				-- storage_type_id
	'integer',			-- acs_datatype
	'im_category_tree',		-- widget
	'integer',			-- sql_datatype
	'{custom {category_type "Intranet Cost Template"}}' -- parameters
);

select im_dynfield_widget__new (
	null,				-- widget_id
	'im_dynfield_widget',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'cost_centers',			-- widget_name
	'#intranet-core.Cost_Center#',	-- pretty_name
	'#intranet-core.Cost_Centers#', -- pretty_plural
	10007,				-- storage_type_id
	'integer',			-- acs_datatype
	'im_cost_center_tree',		-- widget
	'integer',			-- sql_datatype
	'{custom {start_cc_id ""} {department_only_p 0} {include_empty_p 1} {translate_p 0}}'
);

select im_dynfield_widget__new (
	null,				-- widget_id
	'im_dynfield_widget',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'departments',			-- widget_name
	'#intranet-core.Departments#',	-- pretty_name
	'#intranet-core.Departments#',	-- pretty_plural
	10007,				-- storage_type_id
	'integer',			-- acs_datatype
	'im_cost_center_tree',		-- widget
	'integer',			-- sql_datatype
	'{custom {start_cc_id ""} {department_only_p 1} {include_empty_p 1} {translate_p 0}}'
);

select im_dynfield_widget__new(
	NULL,
	'im_dynfield_widget',
	NULL,
	NULL,
	NULL,
	NULL,
	'biz_object_member_type',
	'#intranet-core.Biz_Object_Role#',
	'#intranet-core.Biz_Object_Role#',
	10007,
	'integer',
	'im_category_tree',
	'integer',
	'{{custom {category_type "Intranet Biz Object Role"}}}'
);


SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
	
		'currencies',		-- widget_name
		'#intranet-core.Currency#',	-- pretty_name
		'#intranet-core.Currencies#',	-- pretty_plural
		10007,			-- storage_type_id
		'string',		-- acs_datatype
		'generic_sql',		-- widget
		'char(3)',		-- sql_datatype
		'{custom {sql {select iso, iso from currency_codes where supported_p = ''t''}}}'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
	
		'category_payment_method',		-- widget_name
		'#intranet-core.Payment_Method#',	-- pretty_name
		'#intranet-core.Payment_Methods#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'im_category_tree',	-- widget
		'integer',		-- sql_datatype
		'{custom {category_type "Intranet Invoice Payment Method"}}' -- parameters
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
	
		'customers_active',		-- widget_name
		'#intranet-core.Customers#',	-- pretty_name
		'#intranet-core.Customers',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_sql',	-- widget
		'integer',		-- sql_datatype
		'{custom {sql {
select
	c.company_id,
	c.company_name
from
	im_companies c
where
	c.company_type_id in (select 57 union select child_id from im_category_hierarchy where parent_id = 57)
	and c.company_status_id in (select 46 union select child_id from im_category_hierarchy where parent_id = 46)
order by
	c.company_name
		}}}'
);



select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'category_office_status',			-- widget_name
	'#intranet-core.Office_Status#',	-- pretty_name
	'#intranet-core.Office_Status#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Office Status"}}}'			-- Parameters
);

	
select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'category_office_type',			-- widget_name
	'#intranet-core.Office_Type#',	-- pretty_name
	'#intranet-core.Office_Type#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Office Type"}}}'			-- Parameters
);




select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'category_company_status',			-- widget_name
	'#intranet-core.Company_Status#',	-- pretty_name
	'#intranet-core.Company_Status#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Company Status"}}}'			-- Parameters
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'annual_revenue',			-- widget_name
	'#intranet-core.Annual_Revenue#',	-- pretty_name
	'#intranet-core.Annual_Revenue#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Annual Revenue"}}}'			-- Parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
 	'country_codes',			-- widget_name
	'#intranet-core.Country#',	-- pretty_name
	'#intranet-core.Country#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'generic_sql',	-- widget
	'char(3)',		-- sql_datatype
	'{{custom {sql "select iso,country_name from country_codes order by country_name"}}}'			-- Parameters
);

update im_dynfield_widgets set deref_plpgsql_function = 'im_country_from_code' where widget_name =  'country_codes';




-------------------------------------------------------------
-- Define some DynFields
--

--	im_dynfield_attribute_new:
--	p_object_type		alias for $1;
--	p_column_name		alias for $2;
--	p_pretty_name		alias for $3;
--	p_widget_name		alias for $4;
--	p_datatype		alias for $5;
--	p_required_p		alias for $6;
--	p_pos_y			alias for $7;
--	p_also_hard_coded_p     alias for $8;

-- Add dynfields for persons
SELECT im_dynfield_attribute_new ('person','first_names','First Names', 'textbox_large','string','t',10,'f');
SELECT im_dynfield_attribute_new ('person','last_name','Last Names', 'textbox_large','string','t',20,'f');
SELECT im_dynfield_attribute_new ('party','email','Email', 'textbox_large','string','t',30,'f');


-- Add dynfields for companies
SELECT im_dynfield_attribute_new ('im_company','company_name','Name', 'textbox_large','string','t',10,'t');
SELECT im_dynfield_attribute_new ('im_company','company_path','Path', 'textbox_large','string','t',20,'t');
SELECT im_dynfield_attribute_new ('im_company','company_status_id','Status','category_company_status','integer','t',30,'t');
SELECT im_dynfield_attribute_new ('im_company','company_type_id','Type','category_company_type','integer','t',40,'t');
SELECT im_dynfield_attribute_new ('im_company','referral_source','Referral','textbox_large','string','f',50,'t');
SELECT im_dynfield_attribute_new ('im_company','vat_number','VAT Number','textbox_small','string','f',60,'t');
SELECT im_dynfield_attribute_new ('im_company','default_vat','Default VAT','integer','string','f',100,'t');
SELECT im_dynfield_attribute_new ('im_company','default_tax','Default TAX','integer','string','f',110,'t');
SELECT im_dynfield_attribute_new ('im_company','note','Note', 'textarea_small','string','t',990,'t');

SELECT im_dynfield_attribute_new ('im_office','office_name','Office Name', 'textbox_large','string','t',10,'t');
SELECT im_dynfield_attribute_new ('im_office','office_path','Office Path', 'textbox_large','string','t',20,'t');
SELECT im_dynfield_attribute_new ('im_office','office_status_id','Office Status', 'category_office_status','integer','t',30,'t');
SELECT im_dynfield_attribute_new ('im_office','office_type_id','Office Type', 'category_office_type','integer','t',40,'t');
SELECT im_dynfield_attribute_new ('im_office','phone','Phone', 'textbox_medium','string','f',100,'t');
SELECT im_dynfield_attribute_new ('im_office','fax','Fax', 'textbox_medium','string','f',110,'t');
SELECT im_dynfield_attribute_new ('im_office','address_line1','Address 1', 'textbox_medium','string','f',120,'t');
SELECT im_dynfield_attribute_new ('im_office','address_line2','Address 2', 'textbox_medium','string','f',130,'t');
SELECT im_dynfield_attribute_new ('im_office','address_city','City', 'textbox_medium','string','f',140,'t');
SELECT im_dynfield_attribute_new ('im_office','address_postal_code','ZIP', 'textbox_short','string','f',150,'t');
SELECT im_dynfield_attribute_new ('im_office','address_country_code','Country', 'country','string','f',160,'t');





-------------------------------------------------------------
-- DynField Fields
--

create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	
	v_attrib_pretty		varchar;
	v_object_name		varchar;
	v_table_name		varchar;
	v_acs_attrib_id		integer;	
	v_attrib_id		integer;
	v_count			integer;
begin
	v_attrib_name := ''default_vat'';
	v_attrib_pretty := ''Default VAT'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		''integer'',
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''textbox_small'', ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty	varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_invoice_template_id'';
	v_attrib_pretty := ''Default Invoice Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, v_widget_name, ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id		integer;	
	v_attrib_id		integer;
	v_count			integer;
begin
	v_attrib_name := ''default_payment_method_id'';
	v_attrib_pretty := ''Default Payment Method'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_payment_method'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, v_widget_name, ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty		varchar;
	v_object_name	varchar;	v_table_name		varchar;
	v_widget_name	varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;
	v_attrib_id	integer;
	v_count		integer;
begin
	v_attrib_name := ''default_payment_days'';
	v_attrib_pretty := ''Default Payment Days'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''textbox_small'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, v_widget_name, ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty	varchar;
	v_object_name	varchar;	v_table_name	varchar;
	v_widget_name	varchar;	v_data_type	varchar;

	v_acs_attrib_id	integer;
	v_attrib_id	integer;
	v_count		integer;
begin
	v_attrib_name := ''default_bill_template_id'';
	v_attrib_pretty := ''Default Bill Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, v_widget_name, ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty	varchar;
	v_object_name	varchar;	v_table_name	varchar;
	v_widget_name	varchar;	v_data_type	varchar;

	v_acs_attrib_id	integer;
	v_attrib_id	integer;
	v_count		integer;
begin
	v_attrib_name := ''default_po_template_id'';
	v_attrib_pretty := ''Default Purchase Order Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty	varchar;
	v_object_name	varchar;	v_table_name	varchar;
	v_widget_name	varchar;	v_data_type	varchar;

	v_acs_attrib_id	integer;
	v_attrib_id	integer;
	v_count		integer;
begin
	v_attrib_name := ''default_delnote_template_id'';
	v_attrib_pretty := ''Default Delivery Note Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_table			varchar;
	v_object		varchar;

	v_acs_attrib_id		integer;
	v_attrib_id		integer;
	v_count			integer;
begin
	v_attrib_name := ''company_project_nr'';
	v_attrib_pretty := ''Customer Project Nr'';
	v_object := ''im_project'';
	v_table := ''im_projects'';

	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_project'' and table_name = ''im_projects'';
	IF v_count = 0 THEN
		insert into acs_object_type_tables (object_type, table_name, id_column)
		values (''im_project'', ''im_projects'', ''project_id'');
	END IF;

	select	count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_projects'' and lower(column_name) = ''company_project_nr'';
	IF v_count = 0 THEN
		alter table im_projects add company_project_nr varchar(50);
	END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object,
		v_attrib_name,
		''string'',
		v_attrib_pretty,
		v_attrib_pretty,
		v_table,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''textbox_medium'', ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;
	v_attrib_pretty		varchar;
	v_table			varchar;
	v_object		varchar;

	v_acs_attrib_id		integer;
	v_attrib_id		integer;
	v_count			integer;
begin
	v_attrib_name := ''final_company'';
	v_attrib_pretty := ''Final Customer'';
	v_object := ''im_project'';
	v_table := ''im_projects'';

	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_projects'' and lower(column_name) = ''final_company'';
	IF v_count = 0 THEN
		alter table im_projects add final_company varchar(200);
	END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object,
		v_attrib_name,
		''string'',
		v_attrib_pretty,
		v_attrib_pretty,
		v_table,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''textbox_medium'', ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-------------------------------------------------------------
-- Make all DynField "required" that are required by the DB
-- Should be executed at the very end of this dynfield-create.sql file
-------------------------------------------------------------




-- return a string coma separated with multimap values
create or replace function inline_0()
returns varchar as '
DECLARE
	row			RECORD;
BEGIN
	FOR row IN
		select
			ida.attribute_id
		from
			acs_attributes aa, 
			im_dynfield_attributes ida, 
			pg_catalog.pg_attribute pga, 
			pg_catalog.pg_class pgc
		where
			aa.attribute_id = ida.acs_attribute_id and 
			pgc.relname = aa.table_name and 
			pga.attname = attribute_name and
			pga.attrelid = pgc.oid and 
			pga.attnotnull = ''t''
	LOOP
		update im_dynfield_type_attribute_map 
			set required_p = ''t'' 
		where attribute_id = row.attribute_id;
		
		update acs_attributes 
			set min_n_values = 1 
		where attribute_id in (
			select acs_attribute_id 
			from im_dynfield_attributes 
			where attribute_id = row.attribute_id
			);

	END LOOP;
		
	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



    
