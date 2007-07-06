--
-- packages/intranet-dynfield/sql/postgresql/intranet-dynfield-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @author Frank Bergmann frank.bergmann@project-open.com
-- @author Juanjo Ruiz juanjoruizx@yahoo.es
-- @creation-date 2005-01-04
--
--

-- ------------------------------------------------------------------
-- Widgets
-- ------------------------------------------------------------------

select acs_object_type__create_type (
		'im_dynfield_widget',	-- object_type
		'Dynfield Widget',	-- pretty_name
		'Dynfield Widgets',	-- pretty_plural
		'acs_object',		-- supertype
		'im_dynfield_widgets',	-- table_name
		'widget_id',		-- id_column
		'intranet-dynfield',	-- package_name
		'f',			-- abstract_p
		null,			-- type_extension_table
		'im_dynfield_widget__name' -- name_method
);

create table im_dynfield_widgets (
	widget_id		integer
				constraint im_dynfield_widgets_fk
				references acs_objects
				constraint im_dynfield_widgets_pk
				primary key,
	widget_name		varchar(100)
				constraint im_dynfield_widgets_name_nn
				not null
				constraint im_dynfield_widgets_name_un
				unique,
	pretty_name		varchar(100)
				constraint im_dynfield_widgets_pretty_n_nn 
				not null,
	pretty_plural		varchar(100)
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
	sql_datatype		varchar(200) 
				constraint im_dynfield_widgets_datatype_nn 
				not null,
	parameters		varchar(4000),
				-- Name of a PlPg/SQL function to convert a 
				-- reference (integer, timestamptz) into a
				-- printable value. Example: im_name_from_user_id,
				-- im_cost_center_name_from_id
	deref_plpgsql_function	varchar(100) default 'im_name_from_id'
);


-- ------------------------------------------------------------------
-- Layout
-- ------------------------------------------------------------------


create table im_dynfield_layout_pages (
	page_url		varchar(1000)
				constraint im_dynfield_layout_page_nn
				not null,
	object_type		varchar(1000)
				constraint im_dynfield_ly_page_object_nn
				not null
				constraint im_dynfield_ly_page_object_fk
				references acs_object_types,
	layout_type		varchar(15)
				constraint im_dynfield_layout_type_nn
				not null
				constraint im_dynfield_layout_type_ck
				check (layout_type in ('table', 'div_absolute', 'div_relative', 'adp')),
	table_height		integer,
	table_width		integer,
	adp_file		varchar(400),
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
	page_url		varchar(1000),
	object_type		varchar(1000)
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
				check (label_style in ('table', 'div_absolute', 'div_relative', 'div', 'adp')),
	div_class		varchar(400),
	sort_key		integer
);

alter table im_dynfield_layout add
  constraint im_dynfield_layout_pk primary key (attribute_id, page_url, object_type)
;

-- Skip the foreign key meanwhile so that we dont have to add the 
-- page_layout for the beginning. By default, a "table" layout will
-- be used.
--
-- alter table im_dynfield_layout add
--   constraint im_dynfield_layout_fk foreign key (page_url, object_type) 
--   references im_dynfield_layout_pages(page_url, object_type)
-- ;




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
	widget_name		varchar(100)
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
				not null
				-- Should the field be included in intranet-search-pg?
	include_in_search_p	char(1) default 'f'
				constraint im_dynfield_attributes_search_ch
				check (include_in_search_p in ('t','f'))
);


--

create table im_dynfield_type_attribute_map (
        attribute_id            integer
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
	value			varchar(400),
	sort_order		integer				
);


-- ToDo: Add indices


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Project/Open Core
-- to render the forum components in the Home, Users, Projects
-- and Company pages.
--
-- The TCL code in the "component_tcl" field is executed
-- via "im_component_bay" in an "uplevel" statemente, exactly
-- as if it would be written inside the .adp <%= ... %> tag.
-- I know that's relatively dirty, but TCL doesn't provide
-- another way of "late binding of component" ...


-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...

select im_component_plugin__del_module('intranet-dynfield');
select im_menu__del_module('intranet-dynfield');


-- Setup the "Dynfield" main menu entry
--


create or replace function inline_0 ()
returns integer as '
declare
        v_menu                  integer;
        v_admin_menu             integer;
        v_admins                integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-dynfield'',  -- package_name
        ''dynfield_admin'',     -- label
        ''DynField'',           -- name
        ''/intranet-dynfield/'',-- url
        750,                     -- sort_order
        v_admin_menu,           -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();







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
        p_widget_id             alias for $1;
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
	p_widget_id	alias for $1;
	v_name		varchar;
BEGIN
	select  widget_name
	into    v_name
	from    im_dynfield_widgets
	where   widget_id = p_widget_id;

	return v_name;
end;' language 'plpgsql';


-- ------------------------------------------------------------------
-- Package
-- ------------------------------------------------------------------

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

	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_table_name		varchar;
BEGIN
	select table_name into v_table_name
	from acs_object_types where object_type = p_attribute_object_type;

	v_acs_attribute_id := acs_attribute__create_attribute (
		p_attribute_object_type,
		p_attribute_name,
		p_datatype,
		p_pretty_name,
		p_pretty_plural,
		v_table_name,		-- table_name
		null,			-- column_name
		p_default_value,
		p_min_n_values,
		p_max_n_values,
		null,			-- sort order
		''type_specific'',	-- storage
		''f''			-- static_p
	);

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
	return v_attribute_id;
end;' language 'plpgsql';


-- Delete a single attribute (if we know its ID...)
create or replace function im_dynfield_attribute__del (integer) returns integer as '
DECLARE
        p_attribute_id             alias for $1;

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
	p_attribute_id	alias for $1;
	v_name		varchar;
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

	v_ret_string varchar2(400);
	v_value im_dynfield_attr_multi_value.value%TYPE;
	v_cat_name category_translations.name%TYPE;
		
	CURSOR csr_flex_multi_attr_value (attr integer, obj integer) IS
	SELECT value
	FROM im_dynfield_attr_multi_value
	WHERE attribute_id = attr
	AND object_id = obj
	AND value is not null;
BEGIN
	v_ret_string := null;
	OPEN csr_flex_multi_attr_value (attr_id,obj_id);
	LOOP 
		FETCH csr_flex_multi_attr_value INTO v_value;
		EXIT WHEN csr_flex_multi_attr_value%NOTFOUND;						

		if v_ret_string is not null then 
		 v_ret_string := v_ret_string || '', '';
		end if; 
	
		if widget_type = ''category_tree'' then
		 select category.name(v_value) into v_cat_name from dual;
	 
		 v_ret_string := v_ret_string || v_cat_name;
			 
		else
		 v_ret_string := v_ret_string || v_value;
		end if;
	END LOOP;
	CLOSE csr_flex_multi_attr_value;
		 
	return v_ret_string;

end;' language 'plpgsql';


-- ------------------------------------------------------------------
-- Storage Type Population
-- ------------------------------------------------------------------

-- 10000-10999  Intranet DynField

insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, ENABLED_P) values
('10001', 'time', 'Intranet DynField Storage Type', 'f');
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, ENABLED_P) values
('10003', 'date', 'Intranet DynField Storage Type', 'f');
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, ENABLED_P) values
('10005', 'multimap', 'Intranet DynField Storage Type', 'f');
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, ENABLED_P) values
('10007', 'value', 'Intranet DynField Storage Type', 'f');
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, ENABLED_P) values
('10009', 'value_with_mime_type', 'Intranet DynField Storage Type', 'f');



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
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'integer',        -- widget_name
        '#intranet-dynfield.Integer#',    -- pretty_name
        '#intranet-dynfield.Integer#',    -- pretty_plural
        10007,                  -- storage_type_id
        'integer',               -- acs_datatype
        'text',               -- widget
        'integer',               -- sql_datatype
        '{html {size 6 maxlength 100}}' -- parameters
);


select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'textbox_small',        -- widget_name
        '#intranet-dynfield.Textbox# #intranet-dynfield.Small#',    -- pretty_name
        '#intranet-dynfield.Textboxes# #intranet-dynfield.Small#',    -- pretty_plural
        10007,                  -- storage_type_id
        'string',               -- acs_datatype
        'text',               -- widget
        'text',               -- sql_datatype
        '{html {size 18 maxlength 30}}' -- parameters
);

select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'textbox_medium',        -- widget_name
        '#intranet-dynfield.Textbox# #intranet-dynfield.Medium#',    -- pretty_name
        '#intranet-dynfield.Textboxes# #intranet-dynfield.Medium#',    -- pretty_plural
        10007,                  -- storage_type_id
        'string',               -- acs_datatype
        'text',               -- widget
        'text',               -- sql_datatype
        '{html {size 30 maxlength 100}}' -- parameters
);

select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'textbox_large',        -- widget_name
        '#intranet-dynfield.Textbox# #intranet-dynfield.Large#',    -- pretty_name
        '#intranet-dynfield.Textboxes# #intranet-dynfield.Large#',    -- pretty_plural
        10007,                  -- storage_type_id
        'string',               -- acs_datatype
        'text',               -- widget
        'text',               -- sql_datatype
        '{html {size 50 maxlength 400}}' -- parameters
);

select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'textarea_small',        -- widget_name
        '#intranet-dynfield.Textarea# #intranet-dynfield.Small#',    -- pretty_name
        '#intranet-dynfield.Textarea# #intranet-dynfield.Small#',    -- pretty_plural
        10007,                  -- storage_type_id
        'string',               -- acs_datatype
        'textarea',               -- widget
        'text',               -- sql_datatype
        '{html {cols 60 rows 4} validate {check_area}}' -- parameters
);

select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'textarea_small_nospell',        -- widget_name
        '#intranet-dynfield.Textarea# #intranet-dynfield.Small#',    -- pretty_name
        '#intranet-dynfield.Textarea# #intranet-dynfield.Small#',    -- pretty_plural
        10007,                  -- storage_type_id
        'string',               -- acs_datatype
        'textarea',               -- widget
        'text',               -- sql_datatype
        '{html {cols 60 rows 4} {nospell}}' -- parameters
);


select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'checkbox',        -- widget_name
        '#intranet-dynfield.Checkbox#',    -- pretty_name
        '#intranet-dynfield.Checkboxes#',    -- pretty_plural
        10007,                  -- storage_type_id
        'boolean',               -- acs_datatype
        'checkbox',               -- widget
        'char(1)',               -- sql_datatype
        '{options {{"" t}}}' -- parameters
);


select im_dynfield_widget__new (
        null,                   -- widget_id
        'im_dynfield_widget',   -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        'category_company_type',        -- widget_name
        '#intranet-core.Company_Type#',    -- pretty_name
        '#intranet-core.Company_Types#',    -- pretty_plural
        10007,                  -- storage_type_id
        'integer',               -- acs_datatype
        'im_category_tree',               -- widget
        'integer',               -- sql_datatype
        '{custom {category_type "Intranet Company Type"}}' -- parameters
);

