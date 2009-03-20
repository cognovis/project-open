# packages/intranet-dynfield/www/import.tcl

ad_page_contract {
    
    Import an XML file with the DynField data
    
    @author Toni Vila (avila@digiteix.com)
    @creation-date 2005-04-04
    
} {
    filename:notnull,trim
    filename.tmpfile:tmpfile
} -validate {

    non_empty_file {
        if { [file size ${filename.tmpfile}] == 0 } {
            ad_complain "The XML file you specified is either empty or invalid."
       }
    }

} -return_errors error_list


ad_return_complaint 1 "This feature hasn't been tested after the modifications of DynFields due to CRM"

# security check
set user_id [ad_verify_and_get_user_id]

# create global variables
set caller_id [ad_conn user_id]
set caller_ip [ad_conn peeraddr]
set page_title "Importing DynField info ..."
set context_bar ""

# read xml
if [catch {
    set xml_stream [open ${filename.tmpfile} r]
    set xml [read $xml_stream]
} errMsg] {
    ns_log "Error" "******************* Error reading xml and dtd: $errMsg"
    ad_return_error "Error reading xml file" "There was an unexpected error reading the xml file: <pre> $errMsg </pre>"
    ad_script_abort
}


# parse xml
if [catch {
    set doc [dom parse "$xml"]
    set root [$doc documentElement]
} errMsg] {
    ns_log "Error" "******************* Error parsing xml: $errMsg"
    ad_return_error "Error parsing xml file" "The file you specified is not a valid xml file: <pre> $errMsg </pre>"
    ad_script_abort
}

# Initialize error vars.
#set error_count 0
#set error_text [list]

set widgets_list [$root selectNodes /DYNFIELD/WIDGETS/WIDGET]

ReturnHeaders
ns_write "<ul>"

foreach widget_node $widgets_list {

    ns_write "<li>Widget attributes</li> <br/> <ul>"
    # get widget attributes
    set widget_name [$widget_node getAttribute widget_name ""]
    set pretty_name [$widget_node getAttribute pretty_name ""]
    set pretty_plural [$widget_node getAttribute pretty_plural ""]
    set storage_type [$widget_node getAttribute storage_type ""]
    set acs_datatype [$widget_node getAttribute acs_datatype ""]
    set widget [$widget_node getAttribute widget ""]
    set sql_datatype [$widget_node getAttribute sql_datatype ""]
    set parameters [$widget_node getAttribute parameters ""]
    
    ns_write "<li>widget Name: $widget_name Pretty Name: $pretty_name Pretty Plural: $pretty_plural 
    	Storage Type: $storage_type ACS datatype: $acs_datatype Widget: $widget SQL datatype: $sql_datatype
    	</li>" 
    
    # check if this widget exists
    if {![db_0or1row widget_exists "select widget_id 
    	from im_dynfield_widgets 
    	where widget_name = :widget_name"]} {
    	# create new widget	
    	db_transaction {
    		db_exec_plsql create_widget ""
    		ns_write "<li><font color=green>Widget created !!!!</font></li>"
	} on_error {
	        ns_write "<li><font color=red>Error creating new widget:</font> $errmsg</li>"
        }
    } else {
    	# update widget info
    	db_transaction {
    		db_dml "update widget info" "update im_dynfield_widgets set
		       widget_name     = :widget_name,
		       pretty_name     = :pretty_name,
		       pretty_plural   = :pretty_plural,
		       storage_type    = :storage_type,
		       acs_datatype    = :acs_datatype,
		       sql_datatype    = :sql_datatype,
		       widget          = :widget,
		       parameters      = :parameters
		       where
        	       widget_id = :widget_id"
        	ns_write "<li><font color=green>Updated !!!!</font></li>"
        } on_error {
        	ns_write "<li><font color=red>Error updating widget:</font> $errmsg</li>"
        }  
    }
    
    ns_write "</ul>"
    
}

set object_types_list [$root selectNodes /DYNFIELD/OBJECT_TYPES/OBJECT_TYPE]

foreach obj_type $object_types_list {
    set object_type_name [$obj_type getAttribute name ""]
    ns_write "<li>Object_type: $object_type_name</li> <br/> <ul>"
    if {![db_0or1row "exists object_type" "select 1 
    	from acs_object_types 
    	where object_type = :object_type_name"]} {
    	ns_write "<li><font color=red>Error processing object type:</font> Object type doesn't exists</li>"
    	continue
    }
    # get dbi interfaces
    set interfaces_list [$obj_type selectNodes DBI/INTERFACE]
    ns_write "DBI Interface:<ul>"
    foreach interface $interfaces_list {
    	set interface_type_key [$interface getAttribute "interface_type_key" ""]
    	set join_column [$interface getAttribute "join_column" ""]
    	
    	ns_write "<li>Interface type key: $interface_type_key Join Column: $join_column"
    	if {![db_0or1row "exist dbi interface" "select 1
    		from im_dynfield_interfaces
    		where object_type = :object_type_name"]} {
    		db_transaction {
    			db_dml "create interface" "insert into im_dynfield_interfaces
    				(object_type,interface_type_key,join_column)
    				values
    				(:object_type_name,:interface_type_key,:join_column)"
    			ns_write "<li><font color=green>Interface added !!!!</font></li>"
    		} on_error {
    			ns_write "<li><font color=red>Error adding Interface:</font> $errmsg</li>"
    		}
    	} else {
    		ns_write "<li><font color=orange>Interface already exists for this object_type !!!!</font></li>"
    	}
    }
    ns_write "</ul>"
    # get object type extencion tables
    set extension_tables_list [$obj_type selectNodes EXTENSION_TABLES/EXT_TABLE]
    ns_write "Extension Tables:<ul>"
    foreach ext_table $extension_tables_list {
    	set table_name [$ext_table getAttribute table_name ""]
    	set id_column [$ext_table getAttribute id_column ""]
    	ns_write "<li>Table name: $table_name Id column: $id_column </li>"
    	#insert if not exists
    	ns_write "<br/><ul>"
    	if {![db_0or1row "table already exists" "select 1 
    		from acs_object_type_tables
    		where object_type = :object_type_name
    		and table_name = :table_name"]} {
    		# insert information
    		db_transaction {
    			db_dml "insert extension table" "insert into acs_object_type_tables 
    				(object_type, table_name, id_column)
    				values
    				(:object_type_name,:table_name,:id_column)"
    			ns_write "<li><font color=green>Extension table added !!!!</font></li>"
    		} on_error {
    			ns_write "<li><font color=red>Error adding extension table:</font> $errmsg</li>"
    		}
    	} else {
    		ns_write "<li><font color=orange>Extension table already exists for this object_type !!!!</font></li>"
    	}
    	ns_write "</ul>"
    }
    ns_write "</ul>"
    
    set dynfield_layout_pages_list [$obj_type selectNodes DYNFIELD_LAYOUT_PAGES/LAYOUT_PAGE]
    ns_write "Layout Pages:<ul>"
    foreach layout_page $dynfield_layout_pages_list {
	set page_url [$layout_page getAttribute page_url ""]
	set layout_type [$layout_page getAttribute layout_type ""]
	set table_height [$layout_page getAttribute table_height ""]
	set table_width [$layout_page getAttribute table_width ""]
	set adp_file [$layout_page getAttribute adp_file ""]
	set default_p [$layout_page getAttribute default_p ""]
	
	ns_write "<li>Page url: $page_url Layout type: $layout_type Table height: $table_height Table width $table_width Adp file: $adp_file Default? $default_p</li>"
	ns_write "<br/> <ul>"
	if {![db_0or1row "page exists" "select 1 
		from im_dynfield_layout_pages 
		where object_type = :object_type_name
		and page_url = :page_url"]} {
		#insert new page layout
		
		db_transaction {
			db_dml "insert layout page" "insert into im_dynfield_layout_pages 
				(page_url,object_type,layout_type,table_height,table_width,adp_file,default_p)
				values
				(:page_url,:object_type_name,:layout_type,:table_height,:table_width,:adp_file,:default_p)"
				ns_write "<li><font color=green>Page layout added !!!!</font></li>"
		} on_error {
			ns_write "<li><font color=red>Error adding page layout:</font> $errmsg</li>"
		}
	} else {
		db_transaction {
			db_dml "update layout page" "update im_dynfield_layout_pages 
				set layout_type = :layout_type,
				table_height = :table_height,
				table_width = :table_width,
				adp_file = :adp_file,
				default_p = :default_p"
				ns_write "<li><font color=green>Page layout updated !!!!</font></li>"
		} on_error {
			ns_write "<li><font color=red>Error updating page layout:</font> $errmsg</li>"
		}
	}
	ns_write "</ul>"
    }
    ns_write "</ul>"
    
    
    set attributes_list [$obj_type selectNodes ATTRIBUTES/ATTRIBUTE]
    ns_write "<br/> Attributes:<ul>"
    foreach attribute $attributes_list {
    	set attribute_name [$attribute getAttribute attribute_name ""]
    	set pretty_name [$attribute getAttribute pretty_name ""]
    	set pretty_plural [$attribute getAttribute pretty_plural ""]
    	set sort_order [$attribute getAttribute sort_order ""]
    	set datatype [$attribute getAttribute datatype ""]
    	set default_value [$attribute getAttribute default ""]
    	set min_n_values [$attribute getAttribute min_n_values ""]
    	set max_n_values [$attribute getAttribute max_n_values ""]
    	set storage [$attribute getAttribute storage ""]
    	set static_p [$attribute getAttribute static_p ""]
    	set column_name [$attribute getAttribute column_name ""]
    	set table_name [$attribute getAttribute table_name ""]
    	set widget_name [$attribute getAttribute widget_name ""]
    	set already_existed_p [$attribute getAttribute already_existed_p ""]
    	set deprecated_p [$attribute getAttribute deprecated_p ""]
    
    	#set class [$layout_page getAttribute class ""]
    	#set sort_key [$layout_page getAttribute sort_key ""]
    	set attribute_name [string tolower $attribute_name]
    	ns_write "<li>Name: $attribute_name Pretty Name: $pretty_name Pretty Plural: $pretty_plural Sort Order: $sort_order 
    		Datatype: $datatype Min n values: $min_n_values Max n values: $max_n_values Storage: $storage Static? $static_p
    		Column_name: $column_name Table_name: $table_name Widget Name: $widget_name Already Existed? $already_existed_p
    		Deprecated? $deprecated_p</li>"
    	
    	set acs_attribute_exists [attribute::exists_p $object_type_name $attribute_name]
	set dynfield_attribute_exists [dynfield::attribute::exists_p -object_type $object_type_name -attribute_name $attribute_name]
	ns_write "<br/> <ul>"
	db_transaction {
		if {!$acs_attribute_exists} {
		    
		    if { ![im_column_exists $table_name $attribute_name]} {
		    	set modify_sql_p "t"
		    } else {
		    	set modify_sql_p "f"
		    }
			
	            set acs_attribute_id [attribute::add_xt \
	                -min_n_values $min_n_values \
	                -max_n_values $max_n_values \
	                -default $default_value \
	                -modify_sql_p $modify_sql_p \
	                -table_name $table_name \
	                -attribute_name $attribute_name \
	                $object_type_name $datatype \
	                $pretty_name $pretty_plural \
	            ]
	
		    ns_write "<li><font color=green>Acs attribute created !!!!</font></li>"
		    
	            # Distinguish between the table_name from acs_attributes
	            # and the table name in acs_objects.
	            # Only set the table_name in acs_attributes if it's different
	            # from the table in acs_objects.
	            
		
	 	} else {
	        	set acs_attribute_id [db_string acs_attribute_id "
	                select attribute_id
	                from acs_attributes
	                where
	                        object_type = :object_type_name
	                        and attribute_name = :attribute_name"
	        	]
	        	ns_write "<li><font color=orange> Acs attribute already exists</font></li>"
    		}
		
		db_dml "update acs_attribute table_name" "
		        update acs_attributes
		        set table_name = :table_name
		        where attribute_id = :acs_attribute_id"
	                 ns_write "<li><font color=green> Acs attribute table name updated to '$table_name'</font></li>"
		
	
   		if {!$dynfield_attribute_exists} {
		
		        # Let's create the new dynfield attribute
		        # We're using exclusively TCL code here (not PL/PG/SQL
		        # API).
		        set attribute_id [db_exec_plsql create_object ""]
		
		        db_dml insert_dynfield_attributes "
		            insert into im_dynfield_attributes
		                (attribute_id, acs_attribute_id, widget_name, deprecated_p)
		            values
		                (:attribute_id, :acs_attribute_id, :widget_name, :deprecated_p)
		        "
			ns_write "<li><font color=green>DynField attribute created !!!!</font></li>"
		} else {
			db_1row "get dynfield attribute_id" "select attribute_id 
				from im_dynfield_attributes
				where acs_attribute_id = :acs_attribute_id"
			ns_write "<li><font color=orange>DynField attribute already exists</font></li>"
		}
	} on_error {
		ns_write "<li><font color=red>Error processing attribute:</font> $errmsg</li>"
	}
    	ns_write "</ul>"
    	
    	set layout_pages_list [$attribute selectNodes LAYOUT_PAGES/LAYOUT_PAGE]
    	ns_write "<br/> Layout_pages:<ul>"
    	foreach page_layout $layout_pages_list {
    		set page_url [$page_layout getAttribute page_url ""]
    		set class [$page_layout getAttribute class ""]
		set sort_key [$page_layout getAttribute sort_key ""]
		ns_write "<li> Page url: $page_url Class: $class Sort Key: $sort_key </li>"
		ns_write "<br/> <ul>"
		db_transaction {
			if {![db_0or1row "exists page layout" "select 1 from im_dynfield_layout
				where object_type = :object_type_name
				and page_url = :page_url 
				and attribute_id = :attribute_id"]} {
				
				db_dml "insert page layout" "insert into im_dynfield_layout
					(attribute_id, page_url, object_type, class, sort_key)
					values
					(:attribute_id,:page_url,:object_type_name,:class,:sort_key)"
				ns_write "<li><font color=green>Page layout created !!!!</font></li>"
				
			} else {
				db_dml "update page layout" "update im_dynfield_layout 
					set class = :class,
					sort_key = :sort_key
					where object_type = :object_type_name
					and page_url = :page_url 
					and attribute_id = :attribute_id"
				ns_write "<li><font color=green>Page layout updated !!!!</font></li>"
			}
		} on_error {
			ns_write "<li><font color=red>Error processing DynField layout:</font> $errmsg</li>"
		}
		ns_write "</ul>"
    	}
    	ns_write "</ul>"
    	
    }
    ns_write "</ul>"
    
    ns_write "</ul>"
}
ns_write "</ul>"
$doc delete
    
