##################################
#
# Retrieve an IM Dynfield Object
#
##################################

::im::dynfield::Class ad_proc get_instance_from_db {
    -id:required
} {
    Create an XOTcl object from an acs_object_id. This method detemines the type and initializes the object
    from the information stored in the database. The object is automatically destroyed on cleanup.
    
    It requires the class ::im::dynfield::${type} to exist. Will work on this soon :-).
    
    It differs from ::xo::db::Class in the way that it can deref the values
} {
    ns_log Notice "Getting instance for ID : $id"
    set type  [::xo::db::Class get_object_type -id $id]
    if {$type eq "user"} {
        set type "person"
    }
    set class [my object_type_to_class "$type"]
    if {![my isclass $class]} {
      error "no class $class defined"
    }
    set r [$class create ::$id]
    $r db_1row dbq..get_instance [$class fetch_query $id]

    # Now set the multivalues
    foreach attribute_name [$class set multival_attrs] {
        set slot "${class}::slot::${attribute_name}"
        switch [$slot table_name] {
            im_dynfield_cat_multi_value {
                $r set $attribute_name [db_list ids "select category_id from im_dynfield_cat_multi_value where object_id = :id and attribute_id = [$slot dynfield_attribute_id]"]
                $r set ${attribute_name}_deref [db_list values "select im_category_from_id(category_id) from im_dynfield_cat_multi_value where object_id = :id and attribute_id = [$slot dynfield_attribute_id]"]
            }
            im_dynfield_attr_multi_value {
                $r set $attribute_name [db_list values "select value from im_dynfield_attr_multi_value where object_id = :id and attribute_id = [$slot dynfield_attribute_id]"]
                $r set ${attribute_name}_deref [$r $attribute_name]
            }
        }
    }
    $r set object_type $type
    $r set object_types [::im::dynfield::Class object_supertypes -object_type person]
    $r set object_id $id
    $r destroy_on_cleanup
    $r initialize_loaded_object
    return $r
}

::im::dynfield::Class ad_instproc fetch_query {id} {
    Returns the full SQL statement to get all non multivalue values for an object_id.
    The object should be of a dynfield enable object though
} {
    set tables [list]
    set extra_tables [list]
    set attributes [list]
    set id_column [my id_column]
    set left_joins ""
    set join_expressions [list "[my table_name].$id_column = $id"]
    set ref_column "[my table_name].${id_column}"
    foreach cl [concat [self] [my info heritage]] {
	    if {$cl eq "::xotcl::Object"} break
	    set tn [$cl table_name]
	    if {$tn ne "" && [lsearch $tables $tn] < 0} {
	        lappend tables $tn
	        
	        #my log "--db_slots of $cl = [$cl array get db_slot]"
	        foreach {slot_name slot} [$cl array get db_slot] {
		        # avoid duplicate output names
		        set name [$slot name]
		        if {[lsearch [im_dynfield_multimap_tables] [$slot set table_name]] <0  && ![info exists names($name)]} {
		            lappend attributes [$slot attribute_reference $tn]
		        }
		        set names($name) 1
	        }
	    
	        if {$cl ne [self]} {
		        lappend join_expressions "$tn.[$cl id_column] = $ref_column"
	        }
	    
	        # Deal with the extra tables
	        db_foreach table "select table_name, id_column from acs_object_type_tables where object_type = '[$cl object_type]' and table_name not in ([template::util::tcl_to_sql_list $tables])" {
		    lappend extra_tables [list $table_name $id_column]
		}
	    }
    }
    foreach extra_table $extra_tables {
	set table_name [lindex $extra_table 0]
	set id_column [lindex $extra_table 1]
	if {[lsearch $tables $table_name] <0 } {
	    # Extra table, join_expression needed
	    lappend left_joins "left outer join $table_name on (acs_objects.object_id = ${table_name}.${id_column})"
	}
    }
    return "SELECT [join $attributes ,]\nFROM [join $tables ,] [join $left_joins " "] \nWHERE [join $join_expressions { and }] limit 1"
}






######################################
# Deal with Objects
#
######################################

::im::dynfield::Class create ::im::dynfield::Object \
    -superclass ::xo::db::Object \
    -object_type "acs_object" \
    -pretty_name "Object" \
    -pretty_plural "Objects" \
    -table_name "acs_objects" -id_column "object_id" \
    -slots {
        ::xo::Attribute create object_type
        ::xo::Attribute create object_types
    } 

::im::dynfield::Object instproc insert {} {my log no-insert;}


::im::dynfield::Object proc get_context {package_id_var user_id_var ip_var} {
  my upvar \
      $package_id_var package_id \
      $user_id_var user_id \
      $ip_var ip

  if {![info exists package_id]} {
    if {[info command ::xo::cc] ne ""} {
      set package_id    [::xo::cc package_id]
    } elseif {[ns_conn isconnected]} {
      set package_id    [ad_conn package_id]
    } else {
      set package_id ""
    }
  }
  if {![info exists user_id]} {
    if {[info command ::xo::cc] ne ""} {
      set user_id    [::xo::cc user_id]
    } elseif {[ns_conn isconnected]} {
      set user_id    [ad_conn user_id]
    } else {
      set user_id 0
    }
  }
  if {![info exists ip]} {
    if {[ns_conn isconnected]} {
      set ip [ns_conn peeraddr]
    } else {
      set ip [ns_info address]
    }
  }
}

if {0} {
::im::dynfield::Object ad_instproc save_new {
  -package_id -creation_user -creation_ip
} {
  Save the XOTcl Object with a fresh acs_object
  in the database.

  @return new object id
} {
  if {![info exists package_id] && [my exists package_id]} {
    set package_id [my package_id]
  }

  ::im::dynfield::Object get_context package_id creation_user creation_ip
  db_transaction {
      set id [::im::dynfield::Object new_acs_object \
                -package_id $package_id \
                -creation_user $creation_user \
                -creation_ip $creation_ip \
                -object_type [my object_type] \
                -object_id [my object_id] \
                ""]
    [my info class] initialize_acs_object [self] $id
    
    
    my insert
  }
  return $id
}

::im::dynfield::Object proc new_acs_object {
  -package_id
  -creation_user
  -creation_ip
  -object_type
  -object_id
  {object_title ""}
} {
  my get_context package_id creation_user creation_ip

  set id [::xo::db::sql::acs_object new \
              -object_type $object_type \
              -title $object_title \
              -package_id $package_id \
              -creation_user $creation_user \
              -object_id $object_id \
              -creation_ip $creation_ip \
              -security_inherit_p [my security_inherit_p]]
  return $id
}
}

::im::dynfield::Object ad_instproc list_ids {
} {
    Returns a list of list_ids which are applicable to this object
    
    Each class should define their own version of this as it depends on group_ids for persons
    and company_status type for im_companies and you know what for other dynfield objects.
    
    Default gives back all the lists for the object_type of the object.
} {
    my instvar object_type
    return [db_list lists "select category_id from im_categories c, acs_object_types ot where c.category_type= ot.type_category_type and object_type = '$object_type'"]
}

::im::dynfield::Object ad_instproc lists {} {
    Return the list_names for the object
} {
    return [my object_type]
}

::im::dynfield::Object instproc save {} {
    my instvar object_id
    ::xo::clusterwide ns_cache flush xotcl_object_cache ::$object_id
}

::im::dynfield::Object ad_instproc rel_options {} {
    Return a list of possible relationship_types this object can have
} {    
    return [db_list rel_types "select rel_type from acs_rel_types where object_type_one in ([template::util::tcl_to_sql_list [my object_types]]) or object_type_two in ([template::util::tcl_to_sql_list [my object_types]])"]
}

::im::dynfield::Object ad_instproc value {element} {
        Returns the value of the attribute_name derefed
        @param element Element object we need the value for
} {
    set attribute_name [$element attribute_name]
    switch [$element widget_name] {
        date {
            set value [my set $attribute_name]
            if {$value ne ""} {
                set value [template::util::date::get_property display_date $value]
            }
        }
        default {
            set value [my set ${attribute_name}_deref]
        }
    }
}    

::im::dynfield::Object ad_instproc name {} {
    Returns the fully formatted name as intended by the name_method
    of acs_object_types table
} {
    set name_method [db_string name_method "select name_method from acs_object_types where object_type = '[my object_type]'"]
    return [db_string name "select ${name_method}([my object_id]) from dual"]
}

::im::dynfield::Object ad_instproc full_name {} {
    Return the full name along with salutation
} {
    return "[my salutation] [my name]"
}