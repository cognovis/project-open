# packages/intranet-dynfield/tcl/intranet-dynfield-procs.tcl
ad_library {

  Support procs for the intranet-dynfield package

  @author Matthew Geddert openacs@geddert.com
  @author Juanjo Ruiz juanjoruizx@yahoo.es
  @creation-date 2004-09-28

  @vss $Workfile: intranet-dynfield-procs.tcl $ $Revision$ $Date$

}


namespace eval im_dynfield::util {}

# Add render_label element to get element labels in dynamic forms (works with flextag-init)
namespace eval template::element {}

ad_proc -private template::element::render_label { form_id element_id tag_attributes } {
    Render the -label text

    @param form_id	The identifier of the form containing the element.
    @param element_id     The unique identifier of the element within the form.
    @param tag_attributes Reserved for future use.
} {
  get_reference

  return $element(label)
}



ad_proc im_dynfield::type_categories_for_object_type {
    -object_type:required
} {
    set sql "
                select
                        c.category_id,
			c.category
                from
                        im_categories c,
			acs_object_types ot
                where
                        (c.enabled_p = 't' OR c.enabled_p is NULL)
                        and c.category_type = ot.type_category_type
			and ot.object_type = :object_type
		order by
			lower(c.category)
    "
    return [db_list_of_lists cats $sql]
}



ad_proc -public im_dynfield::type_category_for_object_type {
    -object_type:required
} {
    Get the category for the type_id of a given object_type
} {
    return [db_string ocat "select type_category_type from acs_object_types where object_type = :object_type" -default ""]
}


ad_proc -public im_dynfield::status_category_for_object_type {
    -object_type:required
} {
    Get the category for the status_id of a given object_type
} {
    return [db_string ocat "select status_category_type from acs_object_types where object_type = :object_type" -default ""]
}

namespace eval im_dynfield::util {}



ad_proc -public im_dynfield::util::sqlify_list {
    -list:required
} {
    eeerror
    set output_list {}
    foreach item $list {
	if { [exists_and_not_null output_list] } {
	    append output_list ", "
	}
	regsub -all {'} $item {''} item
	append output_list "'$item'"
    }
    return $output_list
}


######




namespace eval im_dynfield:: {}

ad_proc -public im_dynfield::search_sql_criteria_from_form {
    -form_id:required
    -object_type:required
} {
    This procedure generates a subquery SQL clause
    "(select object_id from ...)" that can be used
    by a main query clause either as a "where xxx_id in ..."
    or via a join in order to limit the number of object_ids
    to the ones that fit to the filter criteria.

    @param form_id:
   	    search form id
    @return:
		An array consisting of:
		where: A SQL phrase and
		bind_vars: a key-value paired list carrying the bind
			vars for the SQL phrase
} {
    # Get the list of all elements in the form
    set form_elements [template::form::get_elements $form_id]

    # Get the main table for the data type
    db_1row main_table "
	select
		table_name as main_table_name,
		id_column as main_id_column
	from
		acs_object_types
	where
		object_type = :object_type
    "

    set attributes_sql "
	select
		a.attribute_id,
		a.table_name as attribute_table_name,
		a.attribute_name,
		at.pretty_name,
		a.datatype,
		case when a.min_n_values = 0 then 'f' else 't' end as required_p,
		a.default_value,
		t.table_name as object_type_table_name,
		t.id_column as object_type_id_column,
		at.table_name as attribute_table,
		at.object_type as attr_object_type
	from
		acs_object_type_attributes a,
		im_dynfield_attributes aa,
		acs_attributes at,
		acs_object_types t
	where
		a.object_type = :object_type
		and t.object_type = a.ancestor_type
		and a.attribute_id = aa.acs_attribute_id
		and a.attribute_id = at.attribute_id
	order by
		attribute_id
    "

    set ext_table_sql "
	select distinct
		attribute_table_name as ext_table_name,
		object_type_id_column as ext_id_column
	from
		($attributes_sql) s
    "
    set ext_tables [list]
    set ext_table_join_where ""
    db_foreach ext_tables $ext_table_sql {
	if {$ext_table_name == ""} { continue }
	if {$ext_table_name == $main_table_name} { continue }

	lappend ext_tables $ext_table_name
	append ext_table_join_where "\tand $main_table_name.$main_id_column = $ext_table_name.$ext_id_column\n"
    }

    set bind_vars [ns_set create]
    set criteria [list]
    db_foreach attributes $attributes_sql {
	
	# Check whether the attribute is part of the form
	if {[lsearch $form_elements $attribute_name] >= 0} {
	    set value [template::element::get_value $form_id $attribute_name]
	    if {"" == $value} { continue }
	    ns_set put $bind_vars $attribute_name $value
	    lappend criteria "$attribute_table_name.$attribute_name = :$attribute_name"
	}
    }

    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    set sql "
	(select
		$main_id_column as object_id
	from	
		[join [concat [list $main_table_name] $ext_tables] ",\n\t"]
	where	1 = 1 $ext_table_join_where
		$where_clause
	)
    "

    # Skip empty where clause
    if {"" == $where_clause} {
	set sql "" 
    }

    set extra(where) $sql
    set extra(bind_vars) [util_ns_set_to_list -set $bind_vars]
    ns_set free $bind_vars

    return [array get extra]
}


ad_proc -public im_dynfield::create_clone_update_sql {
    -object_type:required
    -object_id:required
} {
    Returns an SQL update statement that can be executed in
    the context of an object clone() procedure in order to
    update dynfields from variables in memory, pulled out
    of the DB by a statement such as "select p.* from im_projects...".
} {
    # Get the main table for the data type
    db_1row main_table "
	select
		table_name as main_table_name,
		id_column as main_id_column
	from
		acs_object_types
	where
		object_type = :object_type
    "

    set attributes_sql "
	select
		a.attribute_id,
		a.table_name as attribute_table_name,
		a.attribute_name,
		at.pretty_name,
		a.datatype,
		case when a.min_n_values = 0 then 'f' else 't' end as required_p,
		a.default_value,
		t.table_name as object_type_table_name,
		t.id_column as object_type_id_column,
		at.table_name as attribute_table,
		at.object_type as attr_object_type
	from
		acs_object_type_attributes a,
		im_dynfield_attributes aa,
		acs_attributes at,
		acs_object_types t
	where
		a.object_type = :object_type
		and t.object_type = a.ancestor_type
		and a.attribute_id = aa.acs_attribute_id
		and a.attribute_id = at.attribute_id
	order by
		attribute_id
    "

    set sql "update $main_table_name set\n"
    set komma_required 0
    db_foreach attributes $attributes_sql {
	if {$komma_required} { append sql "," }
	append sql "\t$attribute_name = :$attribute_name\n"
	set komma_required 1
    }

    append sql "where $main_id_column = $object_id\n"

    return $sql
}



ad_proc -public im_dynfield::set_form_values_from_http {
    -form_id:required
} {
    Set the values of a form based on the values from "ns_conn form".
    This procedure is usefule when using an ad_form as a "filter"
    selector in P/O index ("report") pages, to pass the URL
    parameters to the form.
    @param form_id:
		search form id
    @return:
		nothing

} {
    ns_log Notice "im_dynfield::set_form_values_from_form: form_id=$form_id"
    
    set form_elements [template::form::get_elements $form_id]
    set form_vars [ns_conn form]
    
    if {"" == $form_vars} { 
	# There are no variables from HTTP - so there
	# are not values to be set...
	return "" 
    }

    foreach element $form_elements {

	# Only set the values for variables that are found in the
	# HTTP variable frame to avoid ambiguities
	set pos [ns_set find $form_vars $element]
	if {$pos >= 0} {
	   set value [ns_set get $form_vars $element]
	   template::element::set_value $form_id $element $value
	
	   ns_log Notice "set_form_values_from_http: request_form: $element = $value"
	}
    }
}


ad_proc -public im_dynfield::set_local_form_vars_from_http {
    -form_id:required
} {
    Set local variables to the values passed on in HTTP,
    so that we don't need to add all of them into the ad_header.
    @param form_id: search form id
    @return:	Form_vars that are also in the HTTP are set to the
		calling variable frame
} {
    ns_log Notice "im_dynfield::set_local_form_vars_form_http: form_id=$form_id"
    
    set form_elements [template::form::get_elements $form_id]
    set form_vars [ns_conn form]
    
    if {"" == $form_vars} { 
	# There are no variables from HTTP - so there
	# are not values to be set...
	return "" 
    }

    foreach element $form_elements {
	# Only set the values for variables that are found in the
	# HTTP variable frame to avoid ambiguities
	set pos [ns_set find $form_vars $element]
	if {$pos >= 0} {
	   set value [ns_set get $form_vars $element]

	   # Write the values to the calling stack frame
	   upvar $element $element
	   set $element $value
	}
	append debug " $element"
    }
}


ad_proc -public im_dynfield::attribute_store {
    -object_type:required
    -object_id:required
    -form_id:required
    {-user_id ""}
} {
    Store intranet-dynfield attributes.
    Basicly, the procedure copies all values of the form into
    local variables and then builds an update statement to update
    the object's main table with the local variables.

    Doesn't support "extension tables" yet (storing attributes in
    tables different from the main object's table).
} {
    # -------------------------------------------------
    # Defaults and setup
    # -------------------------------------------------

    if {"" == $user_id} { set user_id [ad_get_user_id] }
    set current_user_id $user_id

    set object_id_org $object_id
    set object_type_org $object_type
    ns_log Notice "im_dynfield::attribute_store: object_type=$object_type_org, object_id=$object_id_org, form_id=$form_id"

    # Get the list of all variables of the form
    template::form get_values $form_id

    # Get object_type main table and column id
    db_1row get_main_table "
	select	table_name as main_table,
		id_column as main_table_id_column
	from	acs_object_types
	where 	object_type = :object_type_org
    "

    # -------------------------------------------------
    # Create the update SQL statement
    # -------------------------------------------------

    set attribute_sql "
	select	da.attribute_id as dynfield_attribute_id,
		*
	from	im_dynfield_attributes da,
		acs_attributes aa,
		im_dynfield_widgets dw
	where
		da.acs_attribute_id = aa.attribute_id
		and aa.object_type = :object_type_org
		and da.widget_name = dw.widget_name
		and 't' = acs_permission__permission_p(da.attribute_id, :current_user_id, 'write')
	order by aa.attribute_name
    "
    array set update_lines {}
    db_foreach attributes $attribute_sql {

	# Skip attributes that do not exists in (the partial) form.
	if {![template::element::exists $form_id $attribute_name]} { continue }

	# Empty table name? Ugly, but that's the main table then...
	if {[empty_string_p $table_name]} { set table_name $main_table }

	# Is this a multi-value field?
	set multiple_p [template::element::get_property $form_id $attribute_name multiple_p]
	if {[empty_string_p $multiple_p]} { set multiple_p 0 }	
	if {$storage_type_id == [im_dynfield_storage_type_id_multimap]} { set multiple_p 1 }

	if {!$multiple_p} {

	    # Special treatment for certain types of widgets
	    set widget_element [template::element::get_property $form_id $attribute_name widget]
	    switch $widget_element {
		date {
		    set ulines [list]
		    if {[info exists update_lines($table_name)]} { set ulines $update_lines($table_name) }
		    lappend ulines "\n\t\t\t$attribute_name = [template::util::date::get_property sql_date [set $attribute_name]]"
		    set update_lines($table_name) $ulines
		}
		default {
		    set ulines [list]
		    if {[info exists update_lines($table_name)]} { set ulines $update_lines($table_name) }
		    lappend ulines "\n\t\t\t$attribute_name = :$attribute_name"
		    set update_lines($table_name) $ulines
		}
	    }

	} else {

	    # Multi-value field. This must be a field with widget multi-select...
	    ad_return_complaint 1 "Storing multiple values not tested yet: $attribute_name"
	    db_transaction {
		db_dml "delete previous values" "
			delete from im_dynfield_attr_multi_value
			where object_id = :object_id_org 
			and attribute_id = :attribute_id
		"
		foreach val [template::element::get_values $form_id $attribute_name] {
		    db_dml "create multi value" "
			insert into im_dynfield_attr_multi_value (attribute_id,object_id,value) 
			values (:attribute_id,:object_id_org,:val)"
		}
	    }
	}
    }

    foreach table_name [array names update_lines] {

	# Get the index column for the table_name
	set table_index_column [util_memoize "db_string icol \"select id_column from acs_object_type_tables where table_name = '$table_name'\" -default {}"]

	# Get the update lines for each table
	set ulines $update_lines($table_name)

	# Execute the update statement, assuming that all
	# variables will be available as local variables.
	if {[llength $ulines] > 0} {
	    set sql "
		update $table_name set[join $ulines ","]
		where $table_index_column = :object_id_org
	    "
	    db_dml update_object $sql
	}
	
    }
}





ad_proc -public im_dynfield::search_query {
    -object_type:required
    -form_id:required
    {-select_part ""}
    {-from_part ""}
    {-where_clause ""}
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
    ns_log notice "************************************* start query search part **********************"    
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
		ns_log notice "widget element -----> $widget_element"
		switch $widget_element {
			"checkbox" - "multiselect" - "category_tree"  - "im_category_tree" {

				ns_log notice "$widget_element -----> values [set $attribute_name]"
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
					
					ns_log notice "***************** before search multi values [set $attribute_name]"
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
		ns_log notice "***************** $attribute_name NOT EXISTS in $form_id ***********************"	
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
			    	#ns_log notice "sql_query $sql_query"
			    	
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




# ------------------------------------------------------------------
# DynFields per Subtype
# ------------------------------------------------------------------

ad_proc -public im_dynfield::dynfields_per_object_subtype {
    -object_type:required
} {
    Returns the list of dynfield_attributes for each subtype
} {
    return [util_memoize [list im_dynfield::dynfields_per_object_subtype_helper -object_type $object_type]]
}

ad_proc -public im_dynfield::dynfields_per_object_subtype_helper {
    -object_type:required
} {
    Returns the list of dynfield_attributes that are common to all 
    object subtypes
} {
    set type_category [im_dynfield::type_category_for_object_type -object_type $object_type]

    set mapping_sql "
	select distinct
		cat.category_id as type_id,
		m.attribute_id
	from	
		(select	category_id
		 from	im_categories
		 where	category_type = :type_category
		 	and enabled_p = 't'
		) cat
		LEFT OUTER JOIN (
			select	*
			from	im_dynfield_type_attribute_map
			where	display_mode in ('edit','display')
		) m on (cat.category_id = m.object_type_id)
    "
    db_foreach dynfield_mapping $mapping_sql {
        if {0 == $attribute_id} { continue }
    	set attribs [list]
	if {[info exists attrib_hash($type_id)]} { set attribs $attrib_hash($type_id) }
	lappend attribs $attribute_id
	set attrib_hash($type_id) $attribs
    }
    return [array get attrib_hash]
}


ad_proc -public im_dynfield::subtype_have_same_attributes_p {
    -object_type:required
} {
    Returns "1" if all object subtypes have the same list of dynfields.
    This routine is useful if we want to know if we have to redirect
    to the big-object-type-select page to select an object's subtype.
} {
    array set attrib_hash [im_dynfield::dynfields_per_object_subtype -object_type $object_type]
    set first_array_name [lindex [array names attrib_hash] 0]
    set first_array_name_attribs $attrib_hash($first_array_name)

    set same_p 1
    foreach name [array names attrib_hash] {
	set attribs $attrib_hash($name)
	if {$attribs != $first_array_name_attribs} { set same_p 0 }
    }
    return $same_p
}






ad_proc -public im_dynfield::widget_request {
    -widget
    -request 
    -attribute_name 
    -pretty_name 
    -value 
    -optional_p 
    -form_name 
    -attribute_id 
    -html_options
    { -display_mode "edit" }
} {
    Corresponds to ::ams::widget::${widget} functions to answer to "request".
} {
    set value [ams::util::text_value -value $value]
    if { [llength $html_options] == 0 } { set html_options [list] }

    db_1row widget_params "select widget as acs_widget, acs_datatype,parameters as custom_parameters from im_dynfield_widgets where widget_name = :widget"

    switch $request {

        ad_form_widget  {

	        set help_text [attribute::help_text -attribute_id $attribute_id] 

	        set element [list]
	        if { [string is true $optional_p] } {
		        lappend element ${attribute_name}:${acs_datatype}(${acs_widget}),optional 
	        } else {
		        lappend element ${attribute_name}:text(text)
	        }

	        lappend element [list label ${pretty_name}]
	        lappend element [list html $html_options]
	        lappend element [list mode $display_mode]
	        lappend element [list custom $custom_parameters]
	        lappend element [list help_text $help_text]

	        switch $widget {
		        checkbox - radio - select - multiselect - im_category_tree - category_tree {
		            ns_log Notice "im_dynfield::widget_request: select-widgets: with options"
		            set option_list ""
		            set options_pos [lsearch $parameter_list "options"]
		            if {$options_pos >= 0} {
			            set option_list [lindex $parameter_list [expr $options_pos + 1]]
		            }
		    
		            if { [string eq $required_p "f"] && ![string eq $widget "checkbox"]} {
			            set option_list [linsert $option_list -1 [list " [_ intranet-dynfield.no_value] " ""]]
		            }

		            # Drop-down widgets need an options list
		            lappend element [list options $option_list]
		        }
	        }
	        return $element
	    }
        template_form_widget  {
	        if { [string is true $optional_p] } {
		        ::template::element::create ${form_name} ${attribute_name} \
		        -label ${pretty_name} \
		        -datatype text \
		        -widget text \
		        -optional \
		        -html $html_options
	        } else {
		        ::template::element::create ${form_name} ${attribute_name} \
		        -label ${pretty_name} \
		        -datatype text \
		        -widget text \
		        -html $html_options
	        }
	    }
        form_set_value {
	        ::template::element::set_value ${form_name} ${attribute_name} $value
	    }
        form_save_value {
	        set value [::template::element::get_value ${form_name} ${attribute_name}]
	        return [ams::util::text_save -text $value -text_format "text/plain"]
	    }
        value_text {

#	    set status [template::util::aim::status -username $value]
#
            # getting the status can take too long. so we return it for html views
            # but do not return it for text. This is in part because text exports 
            # are often used for csv export and the like.
	        return $value
	    }
        value_html {

#	    switch $status {
#		"online"  {set status_html "<img src=\"/resources/ams/aim_online.gif\" alt\"online\" />"}
#		"offline" {set status_html "<img src=\"/resources/ams/aim_offline.gif\" alt=\"offline\" />"}
#		default   {set status_html "Not A Valid ID"}
#	    }
	        return "$value [template::util::aim::status_img -username $value]"
	    }
        csv_value {
	        # not yet implemented
	    }
        csv_headers {
	        # not yet implemented
	    }
        csv_save {
	        # not yet implemented
	    }
	    widget_datatypes {
	        return [list "string"]
	    }
	    widget_name {
	        return $widget
            #	    return [_ "intranet-dynfield.AIM"]
	    }
	    value_method {
	        set acs_widget [db_string widget_type "select widget from im_dynfield_widgets where widget_name = :widget" -default ""]
	        switch $acs_widget {
		        checkbox - multiselect - category_tree - im_category_tree - radio - select - generic_sql - im_cost_center_tree {
		            return "ams_value__options"
		        }
		        date {
		            return "ams_value__time"
		        }
		        default {
		            return "ams_value__text"
		        }
	        }
	    }
    }
}


ad_proc -public im_dynfield::elements {
    -list_ids:required
    {-privilege "read"}
    {-user_id ""}
} {
    This returns a list of lists with the attribute information
    It checks for permission on the dynfield
    
    @param list_ids Lists for which to get the elements
    @param orderby_clause Clause for odering the lists.

    @return list of lists where each attribute is made of <ol>
    <li>attribute_id
    <li>required_p  
    <li>section_heading
    <li>attribute_name 
    <li>pretty_name    
    <li>widget         
    <li>html_options</ol>
} {
    if {$user_id eq ""} {
        set user_id [ad_conn user_id]
    }
    set attributes [list]
    set list_ids [template::util::tcl_to_sql_list $list_ids]
    db_foreach select_elements " " {
        if {[im_object_permission -object_id $dynfield_attribute_id -user_id $user_id -privilege $privilege]} {
            lappend attributes [list $dynfield_attribute_id $attribute_id $section_heading $attribute_name \
                $pretty_name $attribute_id $sort_order $widget $required_p]
        }
    }
    return $attributes
}

ad_proc -public im_dynfield::append_attributes_to_form {
    {-object_subtype_id "" }
    -object_type:required
    -form_id:required
    {-object_id ""}
    {-search_p "0"}
    {-form_display_mode "edit" }
    {-advanced_filter_p 0}
    {-include_also_hard_coded_p 0 }
    {-page_url "default" }
} {
    Append intranet-dynfield attributes for object_type to an existing form.<p>
    @option object_type The object_type attributes you want to add to the form
    @option object_subtype_id Specifies the "subtype" of the objects (i.e. project_type_id)
    @option advanced_filter_p Tells us that the dynfields are used for an 
            "advanced filter" as oposed to a data form. Text fields dont make
            much sense here, so we'll skip them.

    @param include_also_hard_coded_p Should we include fields that are also hard
            coded in ]po[ screens?

    @param page_url
		Serves to identify the page layout.

    @return Returns the number of added fields

    The code consists of two main parts:
    <ul>
    <li>Adding the the attributes to the forum and
    <li>Extracting the values of the attributes from a number of storage tables.
    </ul>

} {
    set debug 0
    if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: object_type=$object_type, object_id=$object_id" }
    set user_id [ad_get_user_id]

    # Add a hidden "object_type" field to the form
    if {![template::element::exists $form_id "object_type"]} {
	if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: creating object_type=$object_type" }
    	template::element create $form_id "object_type" \
    			    -datatype text \
    			    -widget hidden \
    			    -value  $object_type
    }
    
    # add a hidden object_id field to the form
    if {[exists_and_not_null object_id]} {
    	if {![template::element::exists $form_id "object_id"]} {
	    if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: creating object_id=$object_id" }
	    template::element create $form_id "object_id" \
		-datatype integer \
		-widget hidden \
		-value  $object_id
    	}
    }

    # Get display mode per attribute and object_type_id
    set sql "
       select	m.attribute_id,
                m.object_type_id as ot,
                m.display_mode as dm
        from
                im_dynfield_type_attribute_map m,
                im_dynfield_attributes a,
                acs_attributes aa
        where
                m.attribute_id = a.attribute_id
                and a.acs_attribute_id = aa.attribute_id
                and aa.object_type = :object_type
    "

#    if {!$include_also_hard_coded_p} { append sql "\t\tand also_hard_coded_p = 'f'\n" } 

    # Default: Set all field to form's display mode
    set default_display_mode $form_display_mode

    db_foreach attribute_table_map $sql {
	set key "$attribute_id.$ot"
	set display_mode_hash($key) $dm

	# Now we've got atleast one display mode configured:
	# Set the default to "none", so that no field is shown
	# except for the configured fields.
	set default_display_mode "none"

	ns_log Notice "append_attributes_to_form: display_mode($key) <= $dm"
    }

    # Disable the mechanism if the object_type_id hasn't been specified
    # (compatibility mode)
    if {"" == $object_subtype_id} { set default_display_mode "edit" }


    db_1row object_type_info "
        select
                t.table_name as object_type_table_name,
                t.id_column as object_type_id_column
        from
                acs_object_types t
        where
                t.object_type = :object_type
    "

    set extra_wheres [list "1=1"]
    if {$advanced_filter_p} {
	lappend extra_wheres "aw.widget in (
		'select', 'generic_sql', 
		'im_category_tree', 'im_cost_center_tree',
		'checkbox'
	)"
    }
    set extra_where [join $extra_wheres "\n\t\tand "]

    # Does the specified layout page exist? Otherwise we'll use
    # "default".
    set page_url_exists_p [db_string exists "select count(*) from im_dynfield_layout_pages where object_type = :object_type and page_url = :page_url"]
    if {!$page_url_exists_p} { set page_url "default" }

    set attributes_sql "
	select *
	from (
		select
			dl.*,
			coalesce(dl.pos_y, 10000 + a.attribute_id) as pos_y_coalesce,
			a.attribute_id,
			aa.attribute_id as dynfield_attribute_id,
			a.table_name as attribute_table_name,
			tt.id_column as attribute_id_column,
			a.attribute_name,
			a.pretty_name,
			a.datatype, 
			case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
			a.default_value, 
			aw.widget,
			aw.parameters,
			aw.storage_type_id,
			im_category_from_id(aw.storage_type_id) as storage_type
		from
			im_dynfield_attributes aa
			LEFT OUTER JOIN	(
				select	* 
				from	im_dynfield_layout 
				where	page_url = :page_url
			) dl ON (aa.attribute_id = dl.attribute_id),
			im_dynfield_widgets aw,
			acs_attributes a 
			left outer join 
				acs_object_type_tables tt 
				on (tt.object_type = :object_type and tt.table_name = a.table_name)
		where 
			a.object_type = :object_type
			and a.attribute_id = aa.acs_attribute_id
			and aa.widget_name = aw.widget_name
			and $extra_where
		) t
	order by
		pos_y_coalesce
    "

    set field_cnt 0
    db_foreach attributes $attributes_sql {

	# Check if the elements as disabled in the layout page
	if {$page_url_exists_p && "" == $page_url} { continue }

	# Check if the current user has the right to read and write on the dynfield
	set read_p [im_object_permission \
			-object_id $dynfield_attribute_id \
			-user_id $user_id \
			-privilege "read" \
	]
	set write_p [im_object_permission \
			-object_id $dynfield_attribute_id \
			-user_id $user_id \
			-privilege "write" \
	]
	if {!$read_p} { continue }

	set display_mode $default_display_mode
	set key "$dynfield_attribute_id.$object_subtype_id"
	if {[info exists display_mode_hash($key)]} { 
	    set display_mode $display_mode_hash($key) 
	}
	if {"edit" == $display_mode && "display" == $form_display_mode}  {
            set display_mode $form_display_mode
        }
	if {"edit" == $display_mode && !$write_p}  {
            set display_mode "display"
        }
	if {"none" == $display_mode} { continue }


	ns_log Notice "im_dynfield::append_attributes_to_form: attribute_name=$attribute_name, datatype=$datatype, widget=$widget, storage_type_id=$storage_type_id"

	# set optional all attributes if search mode
	if {$search_p} { set required_p "f" }

	# No help yet...
	set help ""

	im_dynfield::append_attribute_to_form \
	    -attribute_name $attribute_name \
	    -widget $widget \
	    -form_id $form_id \
	    -datatype $datatype \
	    -display_mode $display_mode \
	    -parameters $parameters \
	    -required_p $required_p \
	    -pretty_name $pretty_name \
	    -help $help

	incr field_cnt

    }	

    # That's all until here IF this is a new object. Otherwise, we'll need 
    # to retreive the object's values from several tables and from the multi-fields...
    #
    if { ![template::form is_request $form_id] } { return }
    if { ![info exists object_id]} { return }


    # Same loop as before...
    db_foreach attributes $attributes_sql {

	# Check if the elements as disabled in the layout page
	if {$page_url_exists_p && "" == $page_url} { continue }

	# Check if the current user has the right to read the dynfield
	if {![im_object_permission -object_id $dynfield_attribute_id -user_id $user_id]} { continue }

	set display_mode $default_display_mode
	set key "$dynfield_attribute_id.$object_subtype_id"
	if {[info exists display_mode_hash($key)]} { set display_mode $display_mode_hash($key) }
	if {"none" == $display_mode} { continue }


	switch $storage_type {
	    multimap {

		# "MultiMaps" (select with multiple values) are stored in a separate
		# "im_dynfield_attr_multi_value", because we can't store it like the
		# other attributes directly inside the object's table.
		ns_log Notice "im_dynfield::append_attributes_to_form: multipmap storage"
		template::element set_properties $form_id $attribute_name "multiple_p" "1"
		set value_list [db_list get_multiple_values "
			select	value 
			from	im_dynfield_attr_multi_value
			where	attribute_id = :dynfield_attribute_id
				and object_id = :object_id
		"]
		template::element::set_values $form_id $attribute_name $value_list

	    }

	    date {

		# ToDo: Remove this part. It's not used anymore. Dates are stored as
		# values in YYYY-MM-DD format
		ns_log Notice "im_dynfield::append_attributes_to_form: date storage"
		set value [template::util::date::get_property ansi [set $attribute_name]]
		set value_list [split $value "-"]			
		set value "[lindex $value_list 0] [lindex $value_list 1] [lindex $value_list 2]"
		template::element::set_value $form_id $attribute_name $value

	    }

	    value - default {

		# ToDo: slow. This piece issues N SQL statements, instead of constructing
		# a single SQL and issuing it once. Causes performance problems at BaselKB
		# for example.
		ns_log Notice "im_dynfield::append_attributes_to_form: value - default storage"
		set value [db_string get_single_value "
		    select	$attribute_name
		    from	$attribute_table_name
		    where	$attribute_id_column = :object_id
		" -default ""]
		template::element::set_value $form_id $attribute_name $value

	    }

	}
    }
    
    return $field_cnt
}





ad_proc -public im_dynfield::append_attribute_to_form {
    -widget:required
    -form_id:required
    -datatype:required
    -display_mode:required
    -parameters:required
    -required_p:required
    -attribute_name:required
    -pretty_name:required
    -help:required
} {
    Append a single attribute to a form
} {
    # Might translate the datatype into one for which we have a
    # validator (e.g. a string datatype would change into text).
    set translated_datatype [attribute::translate_datatype $datatype]
    if {$datatype == "number"} {
	set translated_datatype "float"
    } elseif {$datatype == "date"} {
	set translated_datatype "date"
    }
    
    set parameter_list [lindex $parameters 0]
    
    # Find out if there is a "custom" parameter and extract its value
    # "Custom" is the parameter to pass-on widget parameters from the
    # DynField Maintenance page to certain form Widgets.
    # Example: "custom {sql {select ...}}" in the "generic_sql" widget.
    set custom_parameters ""
    set custom_pos [lsearch $parameter_list "custom"]
    if {$custom_pos >= 0} {
	set custom_parameters [lindex $parameter_list [expr $custom_pos + 1]]
    }
    
    set html_parameters ""
    set html_pos [lsearch $parameter_list "html"]
    if {$html_pos >= 0} {
	set html_parameters [lindex $parameter_list [expr $html_pos + 1]]
    }
    
    switch $widget {
	checkbox - radio - select - multiselect - im_category_tree - category_tree {
	    
	    ns_log Notice "im_dynfield::append_attribute_to_form: select-widgets: with options"
	    set option_list ""
	    set options_pos [lsearch $parameter_list "options"]
	    if {$options_pos >= 0} {
		set option_list [lindex $parameter_list [expr $options_pos + 1]]
	    }
	    
	    if { [string eq $required_p "f"] && ![string eq $widget "checkbox"]} {
		set option_list [linsert $option_list -1 [list " [_ intranet-dynfield.no_value] " ""]]
	    }
	    if {![template::element::exists $form_id "$attribute_name"]} {
		template::element create $form_id "$attribute_name" \
		    -datatype "text" [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -label "$pretty_name" \
		    -options $option_list \
		    -custom $custom_parameters \
		    -html $html_parameters \
		    -help_text $help \
		    -mode $display_mode
	    }
	}
	
	default {
	    
	    ns_log Notice "im_dynfield::append_attribute_to_form: default: no options"
	    if {![template::element::exists $form_id "$attribute_name"]} {
		template::element create $form_id "$attribute_name" \
		    -datatype $translated_datatype [ad_decode $required_p f "-optional" ""] \
		    -widget $widget \
		    -label $pretty_name \
		    -html $html_parameters \
		    -custom $custom_parameters\
		    -help_text $help \
		    -mode $display_mode
	    }
	}
    }
}


ad_proc -public im_dynfield::append_attributes_to_im_view {
    -object_type:required
    {-table_prefix "" }
} {
    Returns a list with two elements:

    Element 0: A list of PrettyNames, suitable to be appended to the
    "column_headers" list of a project-open im_view type of ListPage
    (such as ProjectListPage, CompanyListPage, ...)

    Element 1: A list of "display_tcl" expressions suitable to be appended 
    to the "column_vars" list of a project-open im_view ListPage.

    Element 2: A list of select expressions suitable to be included
    in a SQL select statement

    ToDo: Element 1 currently only contains works for columns of 
    storage type "table_column" and will only show the table value
    itself, instead of a value, depending on the "display" mode of
    the corresponding widet.

    table_prefix is a trick when your're trying to aggregate values
    of a joined object, such as the "im_company" in the case of
    im_invoices.
} {
    set current_user_id [ad_get_user_id]

    set attributes_sql "
	select	a.*,
		aa.attribute_id as dynfield_attribute_id,
		tt.id_column as attribute_id_column,
		t.table_name as object_type_table_name,
		t.id_column as object_type_id_column,
		aw.widget,
		aw.parameters,
		aw.storage_type_id,
		im_category_from_id(aw.storage_type_id) as storage_type
	from
		im_dynfield_attributes aa,
		im_dynfield_widgets aw,
		acs_object_types t,
		acs_attributes a
		left outer join
			acs_object_type_tables tt
			on (tt.object_type = :object_type and tt.table_name = a.table_name)
	where
		t.object_type = :object_type
		and a.object_type = t.object_type
		and a.attribute_id = aa.acs_attribute_id
		and aa.widget_name = aw.widget_name
		and im_object_permission_p(aa.attribute_id, :current_user_id, 'read') = 't'
    "

    set column_headers [list]
    set column_vars [list]
    set column_select [list]
    db_foreach dynfield_attributes $attributes_sql {
	lappend column_headers $pretty_name
	lappend column_vars "\$$attribute_name"
	lappend column_select "$table_prefix$attribute_name,"
    }

    return [list $column_headers $column_vars $column_select]
}


ad_proc -public im_dynfield::form {
    -object_type:required
    -form_id:required
    -object_id:required
    -return_url:required
    {-page_url ""}
} {
    Returns a fully formatted template, similar to ad_form.
    As a difference to ad_form, you don't need to specify the
    fields of the object, because they are defined dynamically
    in the intranet-dynfield database.
    Please see the Intranet-Dynfield documentation for more details.
} {
    eeerror
    if { [empty_string_p $page_url] } {
	# get default page_url
	set page_url [db_string get_default_page {
	    select page_url
	    from im_dynfield_layout_pages
	    where object_type = :object_type
	    and default_p = 't'
	} -default ""]
    }

    
    # verify correctness of page_url if something wrong just ignore dynamic position
    if { [db_0or1row exists_page_url_p "select 1 from im_dynfield_layout_pages
	where object_type = :object_type and page_url = :page_url"]
    } {
	set layout_page_p 1
    } else {
	set layout_page_p 0
    }

    db_1row object_type_info "
	select 
		pretty_name as object_type_pretty_name,
		table_name,
		id_column
	from 
		acs_object_types 
	where 
		object_type = :object_type
	"
    
    # check if this object_type involve more tables
    # get object_type tables tree
    set obj_type $object_type
    set object_type_tables [list]
    while {$obj_type != "acs_object"} {

	set obj_type_tables [db_list "get tables related to object_type" "
		select distinct table_name 
		from acs_attributes 
		where object_type = :obj_type 
		and table_name is not null
	"]
	db_1row "get obj_type table" "select table_name as t, supertype as obj_type \
	    from acs_object_types \
	    where object_type = :obj_type"
	lappend obj_type_tables $t
	foreach table $obj_type_tables {

	    if {[lsearch -exact $object_type_tables $table] == -1} {
		lappend object_type_tables $table
	    }
	}

    }

    foreach t_name $object_type_tables {
	# get the primary key for all tables related to object type
    
	db_1row "get table pk" "
	select COLUMN_NAME as c_id
	FROM ALL_CONS_COLUMNS \
	WHERE 
		TABLE_NAME = UPPER(:t_name) \
		AND CONSTRAINT_NAME = ( SELECT CONSTRAINT_NAME \
		FROM ALL_CONSTRAINTS \
		WHERE TABLE_NAME = UPPER(:t_name) \
		AND CONSTRAINT_TYPE = 'P')"
    
	lappend object_type_tables_colid_list [list $t_name $c_id]
    }

    # ------------------------------------------------------
    # Create the form
    # ------------------------------------------------------
    
    # Create a new blank form.
    #
    template::form create $form_id


    # ------------------------------------------------------
    # Retreive object information 
    # OR:
    # Setup form to create a new object
    # ------------------------------------------------------

    if { [template::form is_request $form_id] } {

	if {[info exists object_id]} {
	    # get values from all tables related to object_type
	    foreach table_pair $object_type_tables_colid_list {
		set table_n [lindex $table_pair 0]
		set column_i [lindex $table_pair 1]

		# We can use a wildcard ("p.*") to select all columns from 
		# the object or from its extension table in order to get
		# values that might be added for a specific customer
		db_1row info "
			select 	o.*
			from	$table_n o
			where	o.$column_i = :object_id
		"
	    }


	} else {
	    
	    # Setup the form with an id_column field in order to
	    # create a new object of the given type

	    set object_id [db_nextval "acs_object_id_seq"]
	}
    }


    # ------------------------------------------------------
    # Create form elements from the "im_dynfield_attributes" 
    # table
    # ------------------------------------------------------

    # The table "im_dynfield_attributes" contains the list of
    # "attributes" (= fields or columns) of an object.
    # We are going to add these fields to the current view/
    # edit template.
    #
    # There is a special treatment for attribute "parameters".
    # These parameters are are passed on to the TCL widget
    # that renders the specific attribute value.


    # Pull out all the attributes up the hierarchy from this object_type
    # to the $object_type object type
    set attributes_sql "
	select a.attribute_id,
	       a.table_name as attribute_table_name,
	       a.attribute_name,
	       at.pretty_name,
	       a.datatype, 
	       case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
	       a.default_value, 
	       t.table_name as object_type_table_name, 
	       t.id_column as object_type_id_column,
	       aw.widget,
	       aw.parameters,
	       at.table_name as attribute_table,
	       at.object_type as attr_object_type
	  from
	  	acs_object_type_attributes a, 
	  	im_dynfield_attributes aa,
	  	im_dynfield_widgets aw,
	  	acs_attributes at,
		acs_object_types t
	 where 
	 	a.object_type = :object_type
	 	and t.object_type = a.ancestor_type 
	 	and a.attribute_id = aa.acs_attribute_id
	 	and a.attribute_id = at.attribute_id
	 	and aa.widget_name = aw.widget_name
	 order by 
	 	attribute_id
    "

    db_foreach attributes $attributes_sql {
	# Might translate the datatype into one for which we have a
	# validator (e.g. a string datatype would change into text).
	set translated_datatype [attribute::translate_datatype $datatype]
	    
	set parameter_list [lindex $parameters 0]

	# Find out if there is a "custom" parameter and extract its value
	set custom_parameters ""
	set custom_pos [lsearch $parameter_list "custom"]
	if {$custom_pos >= 0} {
	    set custom_parameters [lindex $parameter_list [expr $custom_pos + 1]]
	}

	set html_parameters ""
	if {[string equal [lindex $parameter_list 0] "html"]} {
	    set html_parameters [lindex $parameter_list 1]
	}


	set value $default_value
	if {[info exists $attribute_name]} {
	    set value [expr "\$$attribute_name"]
	}

	if { [string eq $widget "radio"] || [string eq $widget "select"] || [string eq $widget "multiselect"]} {

	    # For enumerations, we generate a list all the possible values
	    set option_list [db_list_of_lists select_enum_values {
		select enum.pretty_name, enum.enum_value
		from acs_enum_values enum
		where enum.attribute_id = :attribute_id 
		order by enum.sort_order
	    }]
	    	    
	    if { [string eq $required_p "f"] } {
		# This is not a required option list... offer a default
		lappend option_list [list " (no value) " ""]
	    }
	    template::element create $form_id "$attribute_name" \
		    -datatype "text" [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -options $option_list \
		    -label "$pretty_name" \
		    -value $value \
		    -custom $custom_parameters
	} else {
	
	    # ToDo: Catch errors when the variable doesn't exist
	    # in order to create reasonable error messages with
	    # object, object_type, expected variable name and the
	    # list of currently existing variables.
		
	    template::element create $form_id "$attribute_name" \
		    -datatype $translated_datatype [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -label $pretty_name \
		    -value  $value\
		    -html $html_parameters \
		    -custom $custom_parameters
	}
    }
    

    # ------------------------------------------------------
    # Execute this for a "request" (= this page creates a HTML form)
    # In this case we pass some more parameters on to the form
    # ------------------------------------------------------

    if { [template::form is_request $form_id] } {
	
	# A list of additional variables to export
	set export_var_list [list object_id object_type]

	foreach var $export_var_list {
	    template::element create $form_id $var \
		    -value [set $var] \
		    -datatype text \
		    -widget hidden
	}
    }


    # ------------------------------------------------------
    # Store values if the form was valid
    # ------------------------------------------------------

    if { [template::form is_valid $form_id] } {

	set object_exists [db_string object_exists "select count(*) from $table_name where $id_column=:object_id"]

	if {!$object_exists} {
	    # We would have to insert a new object - 
	    # not implmeneted yet
	    ad_return_complaint 1 "Creating new objects not implmented yet<br>
	    Please create the object first via an existing maintenance screen
	    before using the Intranet-Dynfield generic architecture to modify its fields"
	    return
	}

	# check if exist entry in all relates object_type tables
	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
	    if {$table_n != $table_name} {
		set extension_exist [db_string object_exists "select count(*) from $table_n where $column_i=:object_id"]
		if {!$extension_exist} {
		    # todo : create it
		    # mandatory fields!!!!!!!
		}

	    }
	}


	# Build the update_list for all attributes except $id_column
	#
	# for all tables related to object_type
	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
	    set update_sql($table_n) "update $table_n set"
	    set first($table_n) 1
	    set pk($table_n) "$column_i"
	}

	# Get the list of all variables of the last form
	set form_vars [ns_conn form]

	db_foreach attributes $attributes_sql {

	    if {[empty_string_p $attribute_table]} {
		db_1row "get attr object type table" "
		    select table_name as attribute_table \
		    from acs_object_types \
		    where object_type = :attr_object_type"
	    }
	    # Skip the index column - it doesn't need to be
	    # stored.
	    if {[string equal $attribute_name $pk($attribute_table)]} { continue }
	    if {!$first($attribute_table)} { append update_sql($attribute_table) "," }

	    # Get the value of the form variable from the HTTP form
	    set value [ns_set get $form_vars $attribute_name]

	    # Store the attribute into the local variable frame
	    # We take the detour through the local variable frame
	    # (form ns_set -> local var frame -> sql statement)
	    # in order to be able to use the ":var_name" notation
	    # in the dynamically created SQL update statement.
	    set $attribute_name $value

	    append update_sql($attribute_table) "\n\t$attribute_name = :$attribute_name"
	    set first($attribute_table) 0
	}

	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    append update_sql($table_n) "\nwhere $pk($table_n) = :object_id\n"
	    
	    db_transaction {
		if {$first($table_n) == 0} {
		    db_dml update_object $update_sql($table_n)
		}
	    }
	}

	# Add the original return_url as the last one in the list
	lappend return_url_list $return_url
	
	set return_url_stacked [subsite::util::return_url_stack $return_url_list]

	ad_returnredirect $return_url_stacked
	ad_script_abort
    }
}


ad_proc -public im_dynfield::package_id {} {

    TODO: Get the INTRANET-DYNFIELD package ID, not the connection package_id
    Get the package_id of the intranet-dynfield instance

    @return package_id
} {
    return [apm_package_id_from_key "intranet-dynfield"]
}


# ------------------------------------------------------------------
# Compose the Pl/SQL call to create a new object
# ------------------------------------------------------------------

namespace eval im_dynfield::plsql {}

ad_proc -public im_dynfield::plsql::new_object_create_call {
    -object_type:required
} {
    Returns the Pl/SQL call to create a new object of type object_type.
    The call expects that all relevant variables are available in the
    calling variable frame.
    The call returns the object_id of the new object.
    Example:
    im_report__new(null, 
} {
    set plsql_function "${object_type}__new"
    set vars [db_list vars "
	select	':'||lower(arg_name) as arg_name
	from	acs_function_args
	where	function = upper(:plsql_function)
	order by arg_seq
    "]
    return "${plsql_function}([join $vars ","])"
}


ad_proc -public im_dynfield::plsql::required_variables {
    -object_type:required
} {
    Returns the list of variables that need to be present in order to
    execute the new_object_create_call Pl/SQL call successfully.
} {
    set plsql_function "${object_type}__new"
    set index_column [im_dynfield::plsql::index_column -object_type $object_type]

    return [db_list required_vars "
	select	lower(arg_name) as arg_name
	from	acs_function_args
	where	function = upper(:plsql_function)
		and lower(arg_name) != :index_column
    "]
}

ad_proc -public im_dynfield::plsql::index_column {
    -object_type:required
} {
    Returns the index column for the object's main table
} {
    return [db_string oindex_column "select id_column from acs_object_types where object_type = :object_type" -default ""]
}


ad_proc -public im_dynfield::util::missing_attributes_from_table {
    -table_name:required
} {
    Returns a list of list of column names from the table which 
    are not in acs_attributes. This helps to insert elements into acs_attributes
    if they are not there.
    
    I did not write an automated procedure to insert them into acs_attributes 
    or im_dynfield_attributes as too much information is misssing for doing this
    in a computed fashion. Best to read the outcome of this procedure and then write the
    statements for im_dynfield::add manually. 
} {
    return [db_list_of_lists missing_attributes {
              SELECT
                  a.attname as "Column",
                  pg_catalog.format_type(a.atttypid, a.atttypmod) as "Datatype"
              FROM
                  pg_catalog.pg_attribute a
              WHERE
                  a.attnum > 0
                  AND NOT a.attisdropped
                  AND a.attrelid = (
                      SELECT c.oid
                      FROM pg_catalog.pg_class c
                          LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                      WHERE c.relname = :table_name
                          AND pg_catalog.pg_table_is_visible(c.oid)
                  )
                  and attname not in (select attribute_name from acs_attributes aa, acs_object_types ot where aa.object_type = ot.object_type and ot.table_name = :table_name)
    }]
}