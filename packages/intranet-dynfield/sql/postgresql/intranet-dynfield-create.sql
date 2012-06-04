--
-- packages/intranet-dynfield/sql/postgresql/intranet-dynfield-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @author Frank Bergmann frank.bergmann@project-open.com
-- @author Juanjo Ruiz juanjoruizx@yahoo.es
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2005-01-04
--
--


alter table acs_object_types add column status_category_type varchar(50);
alter table acs_object_types add column type_category_type varchar(50);

comment on column acs_object_types.status_column is 'Defines the column in the status_type_table which stores the category_id for the STATUS of an object of this object_type.';
comment on column acs_object_types.type_column is 'Defines the column in the status_type_table which stores the category_id for the TYPE of an object of this object_type.';
comment on column acs_object_types.status_type_table is 'Defines the table which stores the STATUS and TYPE of the object_type. Defaults to the table_namee of the object_type';
comment on column acs_object_types.type_category_type is 'Defines the category_type from im_categories which contains the options for the TYPE of the object';
comment on column acs_object_types.object_type_gif is 'Image for the object_type';



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
				references im_dynfield_attributes(attribute_id) on delete cascade,
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

comment on table im_dynfield_type_attribute_map is 'This table defines under which conditions an attribute is to be rendered. The condition is determined by the object_type_id, which is a category_id. This category_id is of the category_type which is defined as ''type_category_type'' for the object_type of the attribute. The object_type ''im_projects'' has a type_category_type in acs_object_types of ''Intranet Project Type'' which is the category_type (in im_categories) that contains all the category_ids which can be used to define conditions in the way of object_type_id.';
comment on column im_dynfield_type_attribute_map.attribute_id is 'This is the dynfield_id from im_dynfield_attributes which identifies the attribute. It is NOT an attribute_id from acs_attributes.';
comment on column im_dynfield_type_attribute_map.object_type_id is 'This is the conditions identifier. This identifier is object specific, so if we take Projects as an example again, the condition is defined by the object''s type_id. In the case of Projects, this is stored in im_projects.project_type_id (see acs_object_types.type_column for more). When an object (e.g. Project) is displayed, the system takes the project_type_id and looks up in type_attribute_map how the attributes for the object_type ''im_project'' are to be treated.';
comment on column im_dynfield_type_attribute_map.display_mode is 'The display mode defining the mode in which the attribute is to be displayed. ''edit'' means, it can be both displayed (attribute & value) and edited in a form. ''display'' means that it will displayed when showing the object, but it will not be included in a form. ''none'' means it will neither show up when displaying the object nor when editing a form for this object. This is in addition to the individual permissions you can give on the dynfield_id, so if Freelancers don''t have permission to view attribute, then it does not matter what the display_mode says, they won''t see it';
comment on column im_dynfield_type_attribute_map.help_text is 'This is the help_text for this attribute. Though usually it is the same for all object_type_ids (and this is how it is saved with im_dynfield::attribute::add) it is possible to make it differ depending on the TYPE (category_id) of the object';
comment on column im_dynfield_type_attribute_map.section_heading is 'This allows the grouping of attributes under a common heading. See ad_form sections for more details.';
comment on column im_dynfield_type_attribute_map.default_value is 'This is the default value for this attribute. Though usually it is the same for all object_type_ids (and this is how it is saved with im_dynfield::attribute::add) it is possible to make it differ depending on the TYPE (category_id) of the object';
comment on column im_dynfield_type_attribute_map.required_p is 'This marks, if the attribute is a required attribute in this condition. This is useful e.g. in Projects where depending on the project_type you want an attribute to be filled out, but for other project types it is not necessary.';





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


CREATE OR REPLACE VIEW ams_attributes as
	select	aa.*,
		da.attribute_id as dynfield_attribute_id,
		da.acs_attribute_id,
		da.widget_name as widget,
		da.already_existed_p,
		da.deprecated_p
	from
		acs_attributes aa
		LEFT JOIN im_dynfield_attributes da ON (aa.attribute_id = da.acs_attribute_id)
;



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

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_dynfield_attribute', 'im_dynfield_attributes', 'attribute_id');

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


comment on table im_dynfield_attributes is 'Contains additional information for an acs_attribute like the widget to be used. The other attributes are mainly for backwards compatibility. Note that dynfield_attributes are acs_objects in contrast to acs_attributes which are NOT acs_objects (see acs_attributes for this)';
comment on column im_dynfield_attributes.attribute_id is 'This column should be called dynfield_id. It is the internal dynfield_id (an object_id) is referenced by the other tables in dynfields to provide the connection between the acs_attribute_id and the display logic of the dynfield';
comment on column im_dynfield_attributes.acs_attribute_id is 'This references the attribute_id from acs_attributes. It is used to connect an acs_attribute with the display_logic';





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
	object_id		integer not null
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
	label_style		varchar(15) default 'plain'
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


comment on table im_dynfield_layout is 'This table is used for providing positioning (layout) information of an attribute when being displayed.';
comment on column im_dynfield_layout.attribute_id is 'This is the dynfield_id which references im_dynfield_attributes.';
comment on column im_dynfield_layout.page_url is 'The page_url is the identified which groups the attributes together on a single page. The idea is that you can have a different layout of the attributes depending e.g. if you display the form (which would be displayed like a normal ad_form, where you just need the pos_y to define the order of attributes) and a page to display the attribute values, which could be a table with two columns where you would define which attribute will be displayed on what column in the table (using pos_y). The ''default'' page_url is the standard being used when no other page_url is specified.';
comment on column im_dynfield_layout.pos_x is 'pos_x defines in which column in a table layout you will find the attribute rendered.';
comment on column im_dynfield_layout.pos_y is 'pos_y could also be labelled ''sort_order'', but defines the row coordinate in a table layout where the attribute is rendered. By default im_dynfields supports only one_column which is why the entry form at attribute-new.tcl provides a possibility to enter pos_y for sorting';
comment on column im_dynfield_layout.label_style is ' the style in which the label (attribute_name) is presented in conjunction with the attribute''s value / form_widget. Default is ''table'' which means the label is in column 1 and the value / form_widget is in column 2. Most pages in ]project-open[ don''t bother looking at im_dynfield_layout and just use a normal ''table'' layout. This is changing with the advent of ExtJS driven Forms.';
comment on column im_dynfield_layout.div_class is 'This is the class information which you can pass onto the renderer to override the the standard CSS for this widget. Not in use in any ]project-open[ application as of beginning of 2011';
comment on column im_dynfield_layout.sort_key is 'This is the sorting key for attributes which have a multiple choice widget like combo_box (select) or radio/ checkboxes. This allows you to differentiate if you would like to sort by value or by name. Not in use, all applications default to sort by name as of 2011';





-- Skip the foreign key meanwhile so that we dont have to add the 
-- page_layout for the beginning. By default, a "table" layout will
-- be used.
--
-- alter table im_dynfield_layout add
-- constraint im_dynfield_layout_fk foreign key (page_url, object_type) 
-- references im_dynfield_layout_pages(page_url, object_type)
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






-- ------------------------------------------------------------------
-- Make sure there are acs_object_type_table entries for all objects
-- ------------------------------------------------------------------

create or replace function im_insert_acs_object_type_tables (varchar, varchar, varchar) 
returns integer as $body$
DECLARE
	p_object_type		alias for $1;
	p_table_name		alias for $2;
	p_id_column		alias for $3;

	v_count			integer;
BEGIN
	-- Check for duplicates
	select	count(*) into v_count
	from	acs_object_type_tables
	where	object_type = p_object_type and
		table_name = p_table_name;
	IF v_count > 0 THEN return 1; END IF;

	-- Make sure the object_type exists
	select	count(*) into v_count
	from	acs_object_types
	where	object_type = p_object_type;
	IF v_count = 0 THEN return 2; END IF;

	insert into acs_object_type_tables (object_type, table_name, id_column)
	values (p_object_type, p_table_name, p_id_column);

	return 0;
end;$body$ language 'plpgsql';


SELECT im_insert_acs_object_type_tables('acs_activity','acs_activities','activity_id');
SELECT im_insert_acs_object_type_tables('acs_event','acs_events','event_id');
SELECT im_insert_acs_object_type_tables('authority','auth_authorities','authority_id');
SELECT im_insert_acs_object_type_tables('bt_bug','bt_bugs','bug_id');
SELECT im_insert_acs_object_type_tables('bt_bug_revision','bt_bug_revisions','bug_revision_id');
SELECT im_insert_acs_object_type_tables('bt_patch','bt_patches','patch_id');
SELECT im_insert_acs_object_type_tables('cal_item','cal_items','cal_item_id');
SELECT im_insert_acs_object_type_tables('calendar','calendars','calendar_id');
SELECT im_insert_acs_object_type_tables('group','groups','group_id');

SELECT im_insert_acs_object_type_tables('im_biz_object','im_biz_objects','object_id');
SELECT im_insert_acs_object_type_tables('im_biz_object_member','im_biz_object_members','rel_id');
SELECT im_insert_acs_object_type_tables('im_company','im_companies','company_id');
SELECT im_insert_acs_object_type_tables('im_company_employee_rel','im_company_employee_rel','employee_rel_id');
SELECT im_insert_acs_object_type_tables('im_component_plugin','im_component_plugins','plugin_id');
SELECT im_insert_acs_object_type_tables('im_conf_item','im_conf_items','conf_item_id');
SELECT im_insert_acs_object_type_tables('im_cost','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_cost_center','im_cost_centers','cost_center_id');
SELECT im_insert_acs_object_type_tables('im_dynfield_attribute','im_dynfield_attributes','attribute_id');
SELECT im_insert_acs_object_type_tables('im_dynfield_widget','im_dynfield_widgets','widget_id');
SELECT im_insert_acs_object_type_tables('im_expense','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_expense','im_expenses','expense_id');
SELECT im_insert_acs_object_type_tables('im_expense_bundle','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_expense_bundle','im_expense_bundles','bundle_id');
SELECT im_insert_acs_object_type_tables('im_forum_topic','im_forum_topics','topic_id');
SELECT im_insert_acs_object_type_tables('im_freelance_rfq','im_freelance_rfqs','rfq_id');
SELECT im_insert_acs_object_type_tables('im_freelance_rfq_answer','im_freelance_rfq_answers','answer_id');
SELECT im_insert_acs_object_type_tables('im_fs_file','im_fs_files','file_id');
SELECT im_insert_acs_object_type_tables('im_gantt_project','im_gantt_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_gantt_project','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_indicator','im_indicators','indicator_id');
SELECT im_insert_acs_object_type_tables('im_indicator','im_reports','report_id');
SELECT im_insert_acs_object_type_tables('im_investment','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_investment','im_investments','investment_id');
SELECT im_insert_acs_object_type_tables('im_investment','im_repeating_costs','rep_cost_id');
SELECT im_insert_acs_object_type_tables('im_invoice','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_invoice','im_invoices','invoice_id');
SELECT im_insert_acs_object_type_tables('im_material','im_materials','material_id');
SELECT im_insert_acs_object_type_tables('im_menu','im_menus','menu_id');
SELECT im_insert_acs_object_type_tables('im_note','im_notes','note_id');
SELECT im_insert_acs_object_type_tables('im_office','im_offices','office_id');
SELECT im_insert_acs_object_type_tables('im_project','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_release_item','im_release_items','rel_id');
SELECT im_insert_acs_object_type_tables('im_repeating_cost','im_repeating_costs','rep_cost_id');
SELECT im_insert_acs_object_type_tables('im_repeating_cost','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_report','im_reports','report_id');
SELECT im_insert_acs_object_type_tables('im_rest_object_type','im_rest_object_types','object_type_id');
SELECT im_insert_acs_object_type_tables('im_ticket','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_ticket','im_tickets','ticket_id');
SELECT im_insert_acs_object_type_tables('im_ticket_queue','im_ticket_queue_ext','group_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_invoice','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_invoice','im_invoices','invoice_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_task','im_timesheet_tasks','task_id');
SELECT im_insert_acs_object_type_tables('im_timesheet_task','im_projects','project_id');
SELECT im_insert_acs_object_type_tables('im_trans_invoice','im_costs','cost_id');
SELECT im_insert_acs_object_type_tables('im_trans_invoice','im_invoices','invoice_id');
SELECT im_insert_acs_object_type_tables('im_trans_task','im_trans_tasks','task_id');
SELECT im_insert_acs_object_type_tables('im_user_absence','im_user_absences','absence_id');

SELECT im_insert_acs_object_type_tables('person','im_employees','employee_id');
SELECT im_insert_acs_object_type_tables('person','parties','party_id');
SELECT im_insert_acs_object_type_tables('person','persons','person_id');
SELECT im_insert_acs_object_type_tables('person','users_contact','user_id');

SELECT im_insert_acs_object_type_tables('relationship','acs_rels','rel_id');






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
		''intranet-dynfield'',	-- package_name
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
	'dynfield_otype_conf_item',				-- label
	'Conf Item',						-- name
	'/intranet-dynfield/object-type?object_type=im_conf_item', -- url
	112,							-- sort_order
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
	'dynfield_otype_expense_bundles',			-- label
	'Expense Bundle',					-- name
	'/intranet-dynfield/object-type?object_type=im_expense_bundle', -- url
	122,							-- sort_order
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
	'RFQ',							-- name
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
	'RFQ Answer',						-- name
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
	'dynfield_otype_invoice',				-- label
	'Invoice',						-- name
	'/intranet-dynfield/object-type?object_type=im_invoice', -- url
	142,							-- sort_order
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
	'dynfield_otype_note',					-- label
	'Note',							-- name
	'/intranet-dynfield/object-type?object_type=im_note',	-- url
	144,							-- sort_order
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
	'Office',						-- name
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
	'Person',						-- name
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
	'Project',						-- name
	'/intranet-dynfield/object-type?object_type=im_project', -- url
	170,							-- sort_order
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
	'dynfield_otype_risk',					-- label
	'Risk',							-- name
	'/intranet-dynfield/object-type?object_type=im_risk',	-- url
	175,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'dynfield_otype_risk'),
	(select group_id from groups where group_name='Employees'), 
	'read'
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_ticket',				-- label
	'Ticket',						-- name
	'/intranet-dynfield/object-type?object_type=im_ticket',	-- url
	180,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,								-- p_menu_id
	'im_menu',							-- object_type
	now(),								-- creation_date
	null,								-- creation_user
	null,								-- creation_ip
	null,								-- context_id
	'intranet-dynfield',						-- package_name
	'dynfield_otype_material',					-- label
	'Material',							-- name
	'/intranet-dynfield/object-type?object_type=im_material',	-- url
	143,								-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null								-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_timesheet_task',			-- label
	'Timesheet Task',					-- name
	'/intranet-dynfield/object-type?object_type=im_timesheet_task',	-- url
	190,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);



update im_menus set name = 'Absence' where name = 'Absences' and package_name = 'intranet-dynfield';
update im_menus set name = 'Company' where name = 'Companies' and package_name = 'intranet-dynfield';
update im_menus set name = 'Conf Item' where name = 'Conf Items' and package_name = 'intranet-dynfield';
update im_menus set name = 'Expense' where name = 'Expenses' and package_name = 'intranet-dynfield';
update im_menus set name = 'Expense Bundle' where name = 'Expense Bundles' and package_name = 'intranet-dynfield';
update im_menus set name = 'RFQ' where name = 'Freelance RFQ' and package_name = 'intranet-dynfield';
update im_menus set name = 'RFQ Answer' where name = 'Freelance RFQ Answer' and package_name = 'intranet-dynfield';
update im_menus set name = 'Invoice' where name = 'Invoices' and package_name = 'intranet-dynfield';
update im_menus set name = 'Note' where name = 'Notes' and package_name = 'intranet-dynfield';
update im_menus set name = 'Office' where name = 'Offices' and package_name = 'intranet-dynfield';
update im_menus set name = 'Person' where name = 'Persons' and package_name = 'intranet-dynfield';
update im_menus set name = 'Project' where name = 'Projects' and package_name = 'intranet-dynfield';
update im_menus set name = 'Ticket' where name = 'Tickets' and package_name = 'intranet-dynfield';






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




create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar,
	varchar, varchar, varchar
) returns integer as '
DECLARE
	p_widget_id			alias for $1;
	p_object_type			alias for $2;
	p_creation_date			alias for $3;
	p_creation_user			alias for $4;
	p_creation_ip			alias for $5;
	p_context_id			alias for $6;

	p_widget_name			alias for $7;
	p_pretty_name			alias for $8;
	p_pretty_plural			alias for $9;
	p_storage_type_id		alias for $10;
	p_acs_datatype			alias for $11;
	p_widget			alias for $12;
	p_sql_datatype			alias for $13;
	p_parameters			alias for $14;
	p_deref_plpgsql_function	alias for $15;

	v_widget_id			integer;
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
		storage_type_id, acs_datatype, widget, sql_datatype, parameters, deref_plpgsql_function
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters, p_deref_plpgsql_function
	);
	return v_widget_id;
end;' language 'plpgsql';




create or replace function im_dynfield_widget__delete (integer) returns integer as '
DECLARE
	p_widget_id		alias for $1;
BEGIN
	-- Erase the im_dynfield_widgets item associated with the id
	delete from im_dynfield_widgets
	where widget_id = p_widget_id;

	-- Erase all the privileges
	delete from acs_permissions
	where object_id = p_widget_id;

	PERFORM acs_object__delete(v_widget_id);
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


create or replace function im_dynfield_attribute__new (
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
	integer, varchar, char(1), char(1), integer, varchar, char(1), char(1)
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_acs_attribute_id	alias for $7;
	p_widget_name		alias for $8;
	p_deprecated_p		alias for $9;
	p_already_existed_p	alias for $10;
	p_pos_y			alias for $11;
	p_label_style		alias for $12;
	p_also_hard_coded_p	alias for $13;
	p_include_in_search_p	alias for $14;

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
		attribute_id, acs_attribute_id, widget_name, also_hard_coded_p
		deprecated_p, already_existed_p, include_in_search_p
	) values (
		v_attribute_id, p_acs_attribute_id, p_widget_name, p_also_hard_coded_p
		p_deprecated_p, p_already_existed_p, p_include_in_search_p
	);

	insert into im_dynfield_layout (
		attribute_id, page_url, pos_y, label_style
	) values (
		v_attribute_id, ''default'', p_pos_y, p_label_style
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
		where	object_type_id = row.category_id and attribute_id = v_attribute_id;
		IF 0 = v_count THEN
			insert into im_dynfield_type_attribute_map (
				attribute_id, object_type_id, display_mode
			) values (
				v_attribute_id, row.category_id, ''edit''
			);
		END IF;
	END LOOP;

	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Employees''), ''read'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Employees''), ''write'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Customers''), ''read'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Customers''), ''write'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Freelancers''), ''read'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Freelancers''), ''write'');

	return v_attribute_id;
end;' language 'plpgsql';






create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char, varchar
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
	-- Check for duplicate
	select	da.attribute_id into v_attribute_id
	from	acs_attributes aa, im_dynfield_attributes da 
	where	aa.attribute_id = da.acs_attribute_id and
		aa.attribute_name = p_attribute_name and aa.object_type = p_attribute_object_type;
	if v_attribute_id is not null then return v_attribute_id; end if;

	select	attribute_id into v_acs_attribute_id
	from	acs_attributes
	where	object_type = p_attribute_object_type and
		attribute_name = p_attribute_name;

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



-- Same as before with the object main table as default
create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char
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

	v_table_name		varchar;
BEGIN
	select table_name into v_table_name
	from acs_object_types where object_type = p_attribute_object_type;

	return im_dynfield_attribute__new (
		p_attribute_id, p_object_type, p_creation_date, p_creation_user, p_creation_ip, p_context_id,
		p_attribute_object_type, p_attribute_name, p_min_n_values, p_max_n_values, p_default_value,
		p_datatype, p_pretty_name, p_pretty_plural, p_widget_name, p_deprecated_p, p_already_existed_p, v_table_name
	);

end;' language 'plpgsql';




create or replace function im_dynfield_attribute__delete (integer) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
BEGIN
	-- Erase the mapping of im_dynfield_attributes to object sub-types
	delete from im_dynfield_type_attribute_map
	where attribute_id = p_attribute_id;

	-- Erase all the privileges
	delete from acs_permissions
	where object_id = p_attribute_id;

	-- Erase im_dynfield_layout
	delete from im_dynfield_layout
	where attribute_id = p_attribute_id;

	delete from im_dynfield_attributes
	where attribute_id = p_attribute_id;

	PERFORM acs_object__delete(p_attribute_id);
	return 0;
end;' language 'plpgsql';




-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1), integer, char(1), varchar
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
	p_table_name		alias for $9;

	v_dynfield_id		integer;
	v_widget_id		integer;
	v_type_category		varchar;
	row			RECORD;
	v_count			integer;
	v_min_n_value		integer;
BEGIN
	-- Make sure the specified widget is available
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
	IF p_required_p = ''t'' THEN v_min_n_value := 1; END IF;

	v_dynfield_id := im_dynfield_attribute__new (
		null, ''im_dynfield_attribute'', now(), 0, ''0.0.0.0'', null,
		p_object_type, p_column_name, v_min_n_value, 1, null,
		p_datatype, p_pretty_name, p_pretty_name, p_widget_name,
		''f'', ''f'', p_table_name
	);

	update im_dynfield_attributes set also_hard_coded_p = p_also_hard_coded_p
	where attribute_id = v_dynfield_id;



	-- Insert a layout entry into the default page
	select	count(*) into v_count
	from	im_dynfield_layout
	where	attribute_id = v_dynfield_id and page_url = ''default'';

	IF 0 = v_count THEN
		insert into im_dynfield_layout (
			attribute_id, page_url, pos_y, label_style
		) values (
			v_dynfield_id, ''default'', p_pos_y, ''plain''
		);
	END IF;


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

	select	attribute_name
	into	v_name
	from	acs_attributes
	where	attribute_id = v_acs_attribute_id;

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

-- 10000-10999	Intranet DynField


SELECT im_category_new ('10001', 'time', 'Intranet DynField Storage Type');
SELECT im_category_new ('10003', 'date', 'Intranet DynField Storage Type');
SELECT im_category_new ('10005', 'multimap', 'Intranet DynField Storage Type');
SELECT im_category_new ('10007', 'value', 'Intranet DynField Storage Type');
SELECT im_category_new ('10009', 'value_with_mime_type', 'Intranet DynField Storage Type');


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'date',					-- widget_name
	'#intranet-dynfield.Date#',		-- pretty_name
	'#intranet-dynfield.Date#',		-- pretty_plural
	10007,					-- storage_type_id
	'date',					-- acs_datatype
	'date',					-- widget
	'date',					-- sql_datatype
	'{format "YYYY-MM-DD"} {after_html {<input type="button" style="height:20px; width:20px; background: url(''/resources/acs-templating/calendar.gif'');" onclick ="return showCalendarWithDateWidget(''$attribute_name'', ''y-m-d'');" >}}'
);


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'timestamp',				-- widget_name
	'Timestamp',				-- pretty_name
	'Timestamp',				-- pretty_plural
	10007,					-- storage_type_id
	'date',					-- acs_datatype
	'date',					-- widget
	'timestamptz',				-- sql_datatype
	'{format "YYYY-MM-DD HH24:MI"} {after_html {<input type="button" style="height:20px; width:20px; background: url(''/resources/acs-templating/calendar.gif'');" onclick ="return showCalendarWithDateWidget(''$attribute_name'', ''y-m-d'');" >}}}'
);


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'gender_select',			-- widget_name
	'#intranet-dynfield.Gender_Select#',	-- pretty_name
	'#intranet-dynfield.Gender_Select#',	-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'select',				-- widget
	'string',				-- sql_datatype
	'{options {{Male m} {Female f}}}' 	-- parameters
);



select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'integer',				-- widget_name
	'#intranet-dynfield.Integer#',		-- pretty_name
	'#intranet-dynfield.Integer#',		-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'text',					-- widget
	'integer',				-- sql_datatype
	'{html {size 6 maxlength 100}}' 	-- parameters
);


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'textbox_small',			-- widget_name
	'#intranet-dynfield.Textbox# #intranet-dynfield.Small#',	-- pretty_name
	'#intranet-dynfield.Textboxes# #intranet-dynfield.Small#',	-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'text',					-- widget
	'text',					-- sql_datatype
	'{html {size 18 maxlength 30}}' 	-- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'textbox_medium',			-- widget_name
	'#intranet-dynfield.Textbox# #intranet-dynfield.Medium#',	-- pretty_name
	'#intranet-dynfield.Textboxes# #intranet-dynfield.Medium#',	-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'text',					-- widget
	'text',					-- sql_datatype
	'{html {size 30 maxlength 100}}' 	-- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'textbox_large',			-- widget_name
	'#intranet-dynfield.Textbox# #intranet-dynfield.Large#',	-- pretty_name
	'#intranet-dynfield.Textboxes# #intranet-dynfield.Large#',	-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'text',					-- widget
	'text',					-- sql_datatype
	'{html {size 50 maxlength 400}}' 	-- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'textarea_small',			-- widget_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'textarea',				-- widget
	'text',					-- sql_datatype
	'{html {cols 60 rows 4} validate {check_area}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'textarea_small_nospell',		-- widget_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_name
	'#intranet-dynfield.Textarea# #intranet-dynfield.Small#',	-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'textarea',				-- widget
	'text',					-- sql_datatype
	'{html {cols 60 rows 4} {nospell}}' 	-- parameters
);


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'checkbox',				-- widget_name
	'#intranet-dynfield.Checkbox#',		-- pretty_name
	'#intranet-dynfield.Checkboxes#',	-- pretty_plural
	10007,					-- storage_type_id
	'boolean',				-- acs_datatype
	'checkbox',				-- widget
	'char(1)',				-- sql_datatype
	'{options {{"" t}}}'			-- parameters
);


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'category_company_type',		-- widget_name
	'#intranet-core.Company_Type#',		-- pretty_name
	'#intranet-core.Company_Types#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Company Type"}}' 	-- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'category_company_status',		-- widget_name
	'#intranet-core.Company_Status#',	-- pretty_name
	'#intranet-core.Company_Statuss#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Company Status"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'category_office_type',			-- widget_name
	'#intranet-core.Office_Type#',		-- pretty_name
	'#intranet-core.Office_Types#',		-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Office Type"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'category_office_status',		-- widget_name
	'#intranet-core.Office_Status#',	-- pretty_name
	'#intranet-core.Office_Statuss#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Office Status"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'category_invoice_template',		-- widget_name
	'#intranet-core.Template#',		-- pretty_name
	'#intranet-core.Template#',		-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Cost Template"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'cost_centers',				-- widget_name
	'#intranet-core.Cost_Center#',		-- pretty_name
	'#intranet-core.Cost_Centers#', 	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_cost_center_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {start_cc_id ""} {department_only_p 0} {include_empty_p 1} {translate_p 0}}'
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'departments',				-- widget_name
	'#intranet-core.Departments#',		-- pretty_name
	'#intranet-core.Departments#',		-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_cost_center_tree',			-- widget
	'integer',				-- sql_datatype
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
		null,				-- widget_id
		'im_dynfield_widget',		-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
	
		'currencies',			-- widget_name
		'#intranet-core.Currency#',	-- pretty_name
		'#intranet-core.Currencies#',	-- pretty_plural
		10007,				-- storage_type_id
		'string',			-- acs_datatype
		'generic_sql',			-- widget
		'char(3)',			-- sql_datatype
		'{custom {sql {select iso, iso from currency_codes where supported_p = ''t''}}}'
);

SELECT im_dynfield_widget__new (
		null,				-- widget_id
		'im_dynfield_widget',		-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
	
		'category_payment_method',	-- widget_name
		'#intranet-core.Payment_Method#',	-- pretty_name
		'#intranet-core.Payment_Methods#',	-- pretty_plural
		10007,				-- storage_type_id
		'integer',			-- acs_datatype
		'im_category_tree',		-- widget
		'integer',			-- sql_datatype
		'{custom {category_type "Intranet Invoice Payment Method"}}' -- parameters
);

SELECT im_dynfield_widget__new (
		null,				-- widget_id
		'im_dynfield_widget',		-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
	
		'customers_active',		-- widget_name
		'#intranet-core.Customers#',	-- pretty_name
		'#intranet-core.Customers',	-- pretty_plural
		10007,				-- storage_type_id
		'integer',			-- acs_datatype
		'generic_sql',			-- widget
		'integer',			-- sql_datatype
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
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'category_office_status',		-- widget_name
	'#intranet-core.Office_Status#',	-- pretty_name
	'#intranet-core.Office_Status#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{{custom {category_type "Intranet Office Status"}}}'			-- Parameters
);

	
select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'category_office_type',			-- widget_name
	'#intranet-core.Office_Type#',		-- pretty_name
	'#intranet-core.Office_Type#',		-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{{custom {category_type "Intranet Office Type"}}}'			-- Parameters
);




select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'category_company_status',		-- widget_name
	'#intranet-core.Company_Status#',	-- pretty_name
	'#intranet-core.Company_Status#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{{custom {category_type "Intranet Company Status"}}}'			-- Parameters
);


select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
	'annual_revenue',			-- widget_name
	'#intranet-core.Annual_Revenue#',	-- pretty_name
	'#intranet-core.Annual_Revenue#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{{custom {category_type "Intranet Annual Revenue"}}}'			-- Parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip	
	null,					-- context_id
 	'country_codes',			-- widget_name
	'#intranet-core.Country#',		-- pretty_name
	'#intranet-core.Country#',		-- pretty_plural
	10007,					-- storage_type_id
	'string',				-- acs_datatype
	'generic_sql',				-- widget
	'char(3)',				-- sql_datatype
	'{{custom {sql "select iso,country_name from country_codes order by country_name"}}}'			-- Parameters
);

update im_dynfield_widgets set deref_plpgsql_function = 'im_country_from_code' where widget_name = 'country_codes';




SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'program_projects', 'Program Projects', 'Program Projects',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
select p.project_id, p.project_name
from im_projects p
where project_type_id = 2510
order by lower(project_name)
	}}}'
);


-- Rich Text Field
insert into acs_datatypes (datatype,max_n_values) values ('richtext',null);
SELECT im_dynfield_widget__new (
	null,
	'im_dynfield_widget',
	now(),
	null,
	null,
	null,
	'richtext',
	'Richtext',
	'Richtexts',
	10007,
	'richtext',
	'richtext',
	'im_name_from_id',
	null
);



SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'category_project_type', 'Project Type', 'Project Type',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Project Type"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'category_project_status', 'Project Status', 'Project Status',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Project Status"}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'category_project_on_track_status', 'Project On Track Status', 'Project On Track Status',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Project On Track Status"}}'
);


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'project_managers', 'Project Managers', 'Project Managers',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select u.user_id, im_name_from_user_id(u.user_id) from registered_users u, group_distinct_member_map gm where u.user_id = gm.member_id and gm.group_id in (select group_id from groups where group_name = ''Project Managers'') order by lower(im_name_from_user_id(u.user_id)) }}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'project_sponsors', 'Project Sponsors', 'Project Sponsors',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select u.user_id, im_name_from_user_id(u.user_id) from registered_users u, group_distinct_member_map gm where u.user_id = gm.member_id and gm.group_id in (select group_id from groups where group_name = ''Senior Managers'') order by lower(im_name_from_user_id(u.user_id)) }}}'
);


SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'parent_projects', 'Parent Projects', 'Parent Projects',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select project_id, project_name from im_projects where parent_id is null and project_status_id in (select * from im_sub_categories(76)) order by lower(project_name) }}}'
);

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'customer_companies', 'Customer Companies', 'Customer Companies',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select company_id, company_name from im_companies where company_type_id in (select * from im_sub_categories(57)) and company_status_id in (select * from im_sub_categories(46)) order by lower(company_name) }}}'
);


SELECT im_dynfield_attribute_new ('im_company', 'company_name', 'Name', 'textbox_medium', 'string', 'f', 0, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_path', 'Path', 'textbox_medium', 'string', 'f', 10, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'main_office_id', 'Main Office', 'offices', 'integer', 'f', 20, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_status_id', 'Status', 'category_company_status', 'integer', 'f', 30, 't', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'company_type_id', 'Type', 'category_company_type', 'integer', 'f', 40, 't', 'im_companies');

SELECT im_dynfield_attribute_new ('im_project', 'project_name', 'Name', 'textbox_large', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_nr', 'Nr', 'textbox_medium', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_path', 'Path', 'textbox_medium', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'parent_id', 'Parent Project', 'parent_projects', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'company_id', 'Customer', 'customer_companies', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_type_id', 'Project Type', 'category_project_type', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_status_id', 'Project Status', 'category_project_status', 'string', 'f', 10, 't');

SELECT im_dynfield_attribute_new ('im_project', 'description', 'Description', 'textarea_small', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'note', 'Note', 'textarea_small', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_lead_id', 'Project Manager', 'project_managers', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'supervisor_id', 'Project Sponsor', 'project_sponsors', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_budget', 'Budget', 'numeric', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'percent_completed', '% Done', 'numeric', 'string', 'f', 10, 't');

SELECT im_dynfield_attribute_new ('im_project', 'on_track_status_id', 'On Track', 'category_project_on_track_status', 'string', 'f', 10, 't');
SELECT im_dynfield_attribute_new ('im_project', 'project_budget_currency', 'Budget Currency', 'currencies', 'string', 'f', 10, 't');

-- SELECT im_dynfield_attribute_new ('im_project', 'project_budget_hours', 'Budget Hours', 'numeric', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'end_date', 'End', 'date', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'start_date', 'Start', 'date', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'template_p', 'Template?', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'company_contact_id', 'Customer Contact', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'company_project_nr', 'Customer PO Number', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'confirm_date', 'Confirm Date', 'date', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'release_item_p', 'Release Item?', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'milestone_p', 'Milestone?', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'presales_probability', 'Presales Probability', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'presales_value', 'Presales Value', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'program_id', 'Program', 'string', 'f', 10, 't');
-- SELECT im_dynfield_attribute_new ('im_project', 'project_priority_id', 'Project Priority', 'string', 'f', 10, 't');





-- Create DynFields for Presales Pipeline
SELECT im_dynfield_attribute_new ('im_project', 'presales_probability', 'Presales Probability', 'integer', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_project', 'presales_value', 'Presales Value', 'integer', 'integer', 'f');


-- Create DynField for Program
SELECT im_dynfield_attribute_new ('im_project', 'program_id', 'Program', 'program_projects', 'integer', 'f');





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
--	p_also_hard_coded_p	alias for $8;

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



-- Add javascript calendar buton on date widget
UPDATE im_dynfield_widgets 
SET parameters = '{format "YYYY-MM-DD"} {after_html {<input type="button" style="height:20px; width:20px; background: url(''/resources/acs-templating/calendar.gif'');" onclick ="return showCalendarWithDateWidget(''$attribute_name'', ''y-m-d'');" ></b>}}' 
WHERE widget_name = 'date';


