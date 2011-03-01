



ad_proc -public im_dynfield::search_query {
    -object_type:required
    -form_id:required
    {-select_part ""}
    {-from_part ""}
    {-where_clause ""}
    {-debug 0 }
} {
    generate the search query using intranet-dynfield attributes for object_type
    
    @param object_type: the object type that you want to include attributes
    @param form_id: search form id
    @param select_part: string, comma separated, of NON intranet-dynfield attributes that you want to get from DB.
    	Format: the same as in sql query
    @param from_part string, comma separated, containing from tables for de query search. 
    	Format: the same as in sql query
    @param where_clause: Non intranet-dynfield search conditions
    
    @return: list of lists ready to convert in array <br/>
    	array elements:
    	<ul>
    	   <li><b>select</b>: string, comma separated, ready to use in sql query after SELECT</li>
    	   <li><b>from</b>: string, comma separated, ready to use in sql query after FROM</li>
    	   <li><b>where</b>: string, ready to use in sql query after WHERE</li>
    	   <li><b>list_elements</b>: intranet-dynfield attributes to append to list result elements </li>
    	   <li><b>list_orderby</b>: intranet-dynfield attributes to append to orderby result elements </li>
    	</ul>
} {
    eeerror

    # ------------------------------------------
    # Get the list of all variables of the last form
    # ------------------------------------------

    #set form_vars [ns_conn form]
    #template::form get_values $form_id
    
    # ------------------------------------------
    # proces from_list tables
    # ------------------------------------------
    
    
    set query_select_list [list]    
    set query_from_tables [list]
    
    set from_list [split $from_part ","]
    
    foreach from_table_item $from_list {
    	set table_name [string tolower [lindex $from_table_item 0]]
    	set table_alias [lindex $from_table_item 1]
    	if {[empty_string_p $table_alias]} {
    		set alias($table_name) $table_name
    	} else {
    		set alias($table_name) $table_alias
    	}
    	
    	# ------------------------------------------
	# add the table in
    	# ------------------------------------------
    	
    	lappend query_from_tables "$table_name $table_alias"
    	
    }
    
    # ------------------------------------------
    # get object_type main table and column id
    # ------------------------------------------
    
    db_1row "get main object_type table" "select table_name as main_table_name, \
	    id_column as main_id_column \
	    from acs_object_types \
	    where object_type = :object_type"
    set object_type_tables [list [list $main_table_name $main_id_column]]
    
    # ------------------------------------------
    # get object_type extension tables
    # ------------------------------------------
    
    set ext_object_type_tables [db_list_of_lists "get ext object_type tables" "select \
	    table_name,\
	    id_column \
	    from \
	    acs_object_type_tables\
	    where \
	    object_type = :object_type\
	    "]
    if {[llength $ext_object_type_tables] > 0} {
	set object_type_tables [concat $object_type_tables $ext_object_type_tables]
    }    
    
    # ------------------------------------------
    # for all tables related to object_type
    # create new row if not exists
    # ------------------------------------------
    if {[exists_and_not_null alias($main_table_name)]} {
    	set main_table_alias $alias($main_table_name)
    } else {
    	set main_table_alias "$main_table_name"
    }
    foreach table_pair $object_type_tables {
	set table_n [lindex $table_pair 0]
	set column_i [lindex $table_pair 1]

	# ------------------------------------------
	# add to from tables list if table_n not exists
	# ------------------------------------------
	if {![info exists alias($table_n)]} {
		set alias($table_n) "$table_n"
		set table_alias "$table_n"
		lappend query_from_tables "$table_n"
	} else {
		set table_alias $alias($table_n)
	}
		
	set pk($table_n) "$column_i"
	
	# ------------------------------------------
	# Join the current table to the query
	# ------------------------------------------
	if {$table_alias != $main_table_alias} {
		append where_clause " \n AND $table_alias.$column_i = $main_table_alias.$main_id_column"
	}
    }	
    
    set select_list [split $select_part ","]
    foreach select_item $select_list {
    	set attr [lindex $select_item 0]
    	set table_alias [lindex $select_item 1]
    	
    	lappend query_select_list "$attr"
    	
    	# ---------------------------------------------
    	# create this element to the result list
    	# ---------------------------------------------
    	
    	# its nescessary ???? maybe not
    	# if we must create element list we need to split attr in alias and attribute (alias.attribute)
    }

    set attrib_list [db_list_of_lists get_page_attributes {
	select attr.attribute_id,
	attr.attribute_name,
	attr.table_name as attribute_table,
	attr.pretty_name,
	wdgt.widget,
	wdgt.parameters,
	wdgt.storage_type
	from acs_attributes attr,
	im_dynfield_attributes flex,
	im_dynfield_widgets wdgt
	where attr.object_type = :object_type
	AND attr.attribute_id = flex.acs_attribute_id
	AND flex.widget_name = wdgt.widget_name
    }]
    
    # ------------------------------------------
    # Build the search query and the result list for all attributes 
    # ------------------------------------------
    
    foreach attrib $attrib_list {
	set attribute_id [lindex $attrib 0]
	set attribute_name [lindex $attrib 1]
	set attribute_table [lindex $attrib 2]
	set pretty_name [lindex $attrib 3]
	set widget [lindex $attrib 4]
	set parameters [lindex $attrib 5]
	
	if {[empty_string_p $attribute_table]} {
	    set attribute_table $main_table_name
	}
	
	set table_alias $alias($attribute_table)
	set column_i $pk($attribute_table)
	
	#-------------------------------------------
	# skip attributes that does not exists in form
	# maybe it's not present in this page
	#-------------------------------------------
	set multiple_p 0
	if {[template::element::exists $form_id $attribute_name]} { 

		set widget_element [template::element::get_property $form_id $attribute_name widget]
		set $attribute_name [template::element::get_value $form_id $attribute_name]
		if {$debug} { ns_log notice "widget element -----> $widget_element" }
		switch $widget_element {
			"checkbox" - "multiselect" - "category_tree"  - "im_category_tree" {

			    if {$debug} { ns_log notice "$widget_element -----> values [set $attribute_name]" }
				set multiple_p [template::element::get_property $form_id $attribute_name multiple_p]
				if {[empty_string_p $multiple_p]} {
					set multiple_p 0
				}
				if {$multiple_p} {
					# -------------------------
					# get intranet-dynfield attribute_id
					# -------------------------
					db_1row "get flex attribute" "select attribute_id 
						from im_dynfield_attributes
						where acs_attribute_id = (select attribute_id
								  from acs_attributes 
								  where object_type = :object_type
								  and attribute_name = :attribute_name)"
					
					if {$debug} { ns_log Notice "before search multi values [set $attribute_name]" }
					append where_clause "\n\t AND ("
					set i 0
					foreach val [template::element::get_values $form_id $attribute_name] {
						if {![empty_string_p $val]} {
							if {$i>0} {
								append where_clause "\n\t OR "
							}
							append where_clause " $table_alias.$column_i in (select object_id
								from im_dynfield_attr_multi_value
								where attribute_id = '$attribute_id'
								and value = '$val')"
							incr i
						}	
					}
					# ---------------------------
					# if no value selected 
					# ---------------------------
					if {$i == 0} {
						append where_clause " 1=1 "
					}
					append where_clause "\n\t)"
					
	
				} else {
					if {![empty_string_p [set $attribute_name]]} {
						#set $attribute_name $value
						append where_clause "\n\t AND $table_alias.$attribute_name like '%[set $attribute_name]%' "
					}
				}
			    }
			"date" {
				set value_str [template::util::date::get_property sql_date [set $attribute_name]]
				if {$value_str != "NULL"} {
					append where_clause "\n\t AND $table_alias.$attribute_name = $value_str"	
				}
			}
			default {
				# ------------------------------------------
				# Get the value of the form variable from the HTTP form
				# ------------------------------------------
	
				#set value [ns_set get $form_vars $attribute_name]
				set value [set $attribute_name]
				# ------------------------------------------
				# Store the attribute into the local variable frame
				# We take the detour through the local variable frame
				# (form ns_set -> local var frame -> sql statement)
				# in order to be able to use the ":var_name" notation
				# in the dynamically created SQL update statement.
				# ------------------------------------------
				if {![empty_string_p [set $attribute_name]]} {
					#set $attribute_name $value
					append where_clause "\n\t AND $table_alias.$attribute_name like '%[set $attribute_name]%' "
				}
			} 	
		}
	
		#################################################
		
	} else {
	    if {$debug} { ns_log notice "***************** $attribute_name NOT EXISTS in $form_id ***********************"  }
	}
	
	# ------------------------------------------
	# append this attriubute to the result list
	# ------------------------------------------
	
	
	switch $widget {
		"category_tree" {
			if {$multiple_p} {
				lappend query_select_list "im_dynfield_attribute.multimap_val_to_str($attribute_id, $table_alias.$column_i,'$widget') as $attribute_name"
			} else {
				lappend query_select_list "category.name($table_alias.$attribute_name) as $attribute_name"
			}
		}
		"generic_sql" {
			# -------------------------------------------
			# return default value
			# -------------------------------------------
			
			set generic_sql_return "$table_alias.$attribute_name"
			
			# -------------------------------------------
			# try to return pretty name of key
			# -------------------------------------------
			
			set custom_pos [lsearch $parameters "custom"]
			if {$custom_pos > -1} {
			    	set custom_value [lindex $parameters [expr $custom_pos + 1]]
			    	set sql_query [lindex $custom_value 1]
			    	
			    	set result [regexp -nocase {select ([^ , \" \"]+), ([^ \" \"]+) from ([^ \" \"]+)} $sql_query match key key_name table_key]
			    	if {$result} {
			    		# -------------------------------------------
			    		# create query to return pretty key name
			    		# -------------------------------------------
			    		set generic_sql_return " (SELECT $key_name 
			    					  FROM $table_key 
			    					  WHERE $key = $table_alias.$attribute_name) as $attribute_name "
			    	}
    			}
    			
    			lappend query_select_list $generic_sql_return
		}
		default {
			lappend query_select_list "$table_alias.$attribute_name"
		}
	}

	# -----------------------------------------------------------------
	# avila 20050405 disable add intranet-dynfield attributes to result screen
	# -----------------------------------------------------------------
	
	append elements_list  " $attribute_name { 
					label \"$pretty_name\"
					}"
	append orderby_list " $attribute_name {orderby $table_alias.$attribute_name}"
	
	
    }
      
    
    return [list [list "select" "[join $query_select_list ","]"] [list "from" "[join $query_from_tables ", \n"]"] \
	 [list "where" "$where_clause"] [list "list_elements" "$elements_list"] [list "list_orderby" "$orderby_list"]]
    
}


