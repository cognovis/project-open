# packages/intranet-dynfield/www/export.tcl

ad_page_contract {
    
    testing xml and tdom
    
    @author Toni Vila (toni.vila@quest.ie)
    @creation-date 2005-04-01
} {
} -properties {
} -validate {
} -errors {
}

set doc [dom createDocument "INTRANET-DYNFIELD"]
set root [$doc documentElement]
set widgets_node [$root appendChild [$doc createElement "WIDGETS"]]

db_foreach "get all widgets" "select widget_name, 
	pretty_name, 
	pretty_plural, 
	storage_type_id,
	im_category_from_id(storage_type_id) as storage_type,
	acs_datatype, 
	widget, 
	sql_datatype, 
	parameters
	from im_dynfield_widgets" {
	
	set wdg_node [$widgets_node appendChild [$doc createElement "WIDGET"]]
	
	$wdg_node setAttribute "widget_name" "$widget_name"
	$wdg_node setAttribute "pretty_name" "$pretty_name"
	$wdg_node setAttribute "pretty_plural" "$pretty_plural"
	$wdg_node setAttribute "storage_type_id" "$storage_type_id"
	$wdg_node setAttribute "acs_datatype" "$acs_datatype"
	$wdg_node setAttribute "widget" "$widget"
	$wdg_node setAttribute "sql_datatype" "$sql_datatype"
	$wdg_node setAttribute "parameters" "$parameters"
	
}

set object_types_node [$root appendChild [$doc createElement "OBJECT_TYPES"]]

set object_types_list [db_list "get ovject_types" "select distinct object_type 
	from acs_attributes 
	where attribute_id in (select acs_attribute_id 
			       from im_dynfield_attributes
			      )"]
foreach object_type $object_types_list {
	set obj_type_node [$object_types_node appendChild [$doc createElement "OBJECT_TYPE"]]
	$obj_type_node setAttribute "name" "$object_type"
	
	# get dbi interfaces info if exists

	set dbi_interfaces_node [$obj_type_node appendChild [$doc createElement "DBI"]]
	if {[db_0or1row "get dbi info" "select interface_type_key, join_column 
		from qt_im_dynfield_interfaces
		where object_type = :object_type"]} {
		
		set dbi_int_node [$dbi_interfaces_node appendChild [$doc createElement "INTERFACE"]]
		$dbi_int_node setAttribute "interface_type_key" "$interface_type_key"
		$dbi_int_node setAttribute "join_column" "$join_column"
	}
	

	set extension_tables_node [$obj_type_node appendChild [$doc createElement "EXTENSION_TABLES"]]
	db_foreach "get extension tables" "select table_name,
		id_column
		from acs_object_type_tables
		where object_type = :object_type" {
		
		set ext_table_node [$extension_tables_node appendChild [$doc createElement "EXT_TABLE"]]
		
		$ext_table_node setAttribute "table_name" "$table_name"
		$ext_table_node setAttribute "id_column" "$id_column"
		
	}
	
	set im_dynfield_layout_pages_node [$obj_type_node appendChild [$doc createElement "IM_DYNFIELD_LAYOUT_PAGES"]]
	
	db_foreach "get layout_pages" "select page_url,
		layout_type,
		table_height,
		table_width,
		adp_file,
		default_p
		from im_dynfield_layout_pages
		where object_type = :object_type" {
		
		set layout_page_node [$im_dynfield_layout_pages_node appendChild [$doc createElement "LAYOUT_PAGE"]]
		
		$layout_page_node setAttribute "page_url" "$page_url"
		$layout_page_node setAttribute "layout_type" "$layout_type"
		$layout_page_node setAttribute "table_height" "$table_height"
		$layout_page_node setAttribute "table_width" "$table_width"
		$layout_page_node setAttribute "adp_file" "$adp_file"
		$layout_page_node setAttribute "default_p" "$default_p"
			
	}
	
	set attributes_node [$obj_type_node appendChild [$doc createElement "ATTRIBUTES"]]
	
	db_foreach "get object_type_attributes" "select attr.attribute_name,
		attr.pretty_name,
		attr.pretty_plural,
		attr.sort_order,
		attr.datatype,
		attr.default_value,
		attr.min_n_values,
		attr.max_n_values,
		attr.storage,
		attr.static_p,
		attr.column_name,
		attr.table_name,
		flex.widget_name,
		flex.already_existed_p,
		flex.deprecated_p,
		flex.attribute_id 
		from acs_attributes attr,
		im_dynfield_attributes flex
		where attr.object_type = :object_type
		and flex.acs_attribute_id = attr.attribute_id" {
		
		set attr_node [$attributes_node appendChild [$doc createElement "ATTRIBUTE"]]
		
		$attr_node setAttribute "attribute_name" "$attribute_name"
		$attr_node setAttribute "pretty_name" "$pretty_name"
		$attr_node setAttribute "pretty_plural" "$pretty_plural"
		$attr_node setAttribute "sort_order" "$sort_order"
		$attr_node setAttribute "datatype" "$datatype"
		$attr_node setAttribute "default_value" "$default_value"		
		$attr_node setAttribute "min_n_values" "$min_n_values"
		$attr_node setAttribute "max_n_values" "$max_n_values"
		$attr_node setAttribute "storage" "$storage"
		$attr_node setAttribute "static_p" "$static_p"
		$attr_node setAttribute "column_name" "$column_name"
		$attr_node setAttribute "table_name" "$table_name"
		$attr_node setAttribute "widget_name" "$widget_name"
		$attr_node setAttribute "already_existed_p" "$already_existed_p"
		$attr_node setAttribute "deprecated_p" "$deprecated_p"
		
		set layout_pages_node [$attr_node appendChild [$doc createElement "LAYOUT_PAGES"]]
		db_foreach "get layout pages info" "select page_url,
			class,
			sort_key
			from im_dynfield_layout
			where object_type = :object_type
			and attribute_id = :attribute_id" {
			
			set layout_page_node [$layout_pages_node appendChild [$doc createElement "LAYOUT_PAGE"]]
			
			$layout_page_node setAttribute "page_url" "$page_url"
			$layout_page_node setAttribute "class" "$class"
			$layout_page_node setAttribute "sort_key" "$sort_key"
		}
		
	}
		
}

#ns_log notice "[$root asXML]"
set xml_file "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n[$root asXML -indent none -escapeNonASCII]"

ns_return 200 text/xml $xml_file
