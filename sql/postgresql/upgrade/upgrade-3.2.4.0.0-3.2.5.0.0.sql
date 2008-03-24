-- upgrade-3.2.4.0.0-3.2.5.0.0.sql



drop table im_dynfield_layout;
drop table im_dynfield_layout_pages;


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
	page_url		varchar(1000)
				constraint im_dynfield_layout_page_nn
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
				check (label_style in ('plain','no_label')),
	div_class		varchar(400),
	sort_key		integer
);

alter table im_dynfield_layout add
  constraint im_dynfield_layout_pk primary key (attribute_id, page_url)
;

-- Skip the foreign key meanwhile so that we dont have to add the 
-- page_layout for the beginning. By default, a "table" layout will
-- be used.
--
-- alter table im_dynfield_layout add
--   constraint im_dynfield_layout_fk foreign key (page_url, object_type) 
--   references im_dynfield_layout_pages(page_url, object_type)
-- ;


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'cost_centers',		-- widget_name
	'#intranet-core.Cost_Center#',	-- pretty_name
	'#intranet-core.Cost_Centers#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_cost_center_tree',	-- widget
	'integer',		-- sql_datatype
	'{custom {start_cc_id ""} {department_only_p 0} {include_empty_p 1} {translate_p 0}}'
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'departments',		-- widget_name
	'#intranet-core.Departments#',	-- pretty_name
	'#intranet-core.Departments#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_cost_center_tree',	-- widget
	'integer',		-- sql_datatype
	'{custom {start_cc_id ""} {department_only_p 1} {include_empty_p 1} {translate_p 0}}'
);

