ad_library {

	Class procedures
	
    @creation-date 2008-08-09
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}




namespace eval ::im {}
namespace eval ::im::dynfield {}


#############################
#
# Meta Class for the creation
# Of other classes
# 
##############################

::xotcl::Class create ::im::dynfield::Class \
    -superclass ::xo::db::Class \
    -parameter {
        status_column
        status_type_table
        type_column
        type_category_type
        multival_attr_ids
    } -ad_doc {
        ::im::dynfield::Class is a meta class for interfacing with dynfield enabled acs_object_types.
        acs_object_types are instances of this meta class. The meta class defines the bahvior common to 
        all acs_object_types.
        
        @param status_columns Column where the status_id is stored
        @param status_type_table Tablename where the status type is stored
        @param type_column Which column stores the type_id of the object
        @param type_category_type Which is the defaul im_category_type for this object_type
        @param multival_attr_ids Storage slot for the list of multivalued attribute_ids so we can quickly access them
    }
    

::im::dynfield::Class ad_instproc save_new {} {
    Save the new class
} {    
    # First generate the object_type
    next    

    foreach attribute [list object_type] {
        set $attribute [my $attribute]
    }
    set pretty_name [db_string pretty "select pretty_name from acs_object_types where object_type = :object_type" -default $object_type]
    set object_type_category "$pretty_name"

    # Then update the type_category
    db_dml update "update acs_object_types set type_category_type = :object_type_category where object_type = :object_type"	

    # Create a new category for this list with the same name
    db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:object_type, :object_type_category)"

}

::im::dynfield::Class proc object_type_to_class {name} {
  switch -glob -- $name {
    acs_object       {return ::im::dynfield::Object}
    content_revision {return ::xo::db::CrItem}
    ::*              {return ::im::dynfield::Class::[namespace tail $name]}
    default          {return ::im::dynfield::Class::$name}
  }
}


::im::dynfield::Class ad_proc object_supertypes {
    -object_type
    {-exclude_list ""}
} {
    Return a list of object_types starting with the current type and ending with acs_object,
    looping through the whole hierarchy
    
    @param object_type object_type from which we start
    @param exclude_list List of object_types which we don't want returned. Useful e.g. to exclude acs_objects
} {
    return [util_memoize [list ::im::dynfield::Class object_supertypes_not_cached -object_type $object_type -exclude_list $exclude_list]]
}

::im::dynfield::Class ad_proc object_supertypes_not_cached {
    -object_type
    -exclude_list
} {
    Return a list of object_types starting with the current type and ending with acs_object,
    looping through the whole hierarchy
} {

    if {[lsearch $exclude_list $object_type]<0} {
        # Include the calling object type
        set supertype_list [list $object_type]
    } else {
        set supertype_list ""
    }

    set supertype ""
     
    while {$supertype ne "acs_object"} {
        set supertype [db_string dbqd..fetch_supertype {
            select supertype
            from acs_object_types where object_type = :object_type
        }]
        if {[lsearch $exclude_list $supertype]<0} {
            lappend supertype_list $supertype
        }
        set object_type $supertype
    } 
    return $supertype_list
}

::im::dynfield::Class ad_instproc list_ids {
} {
    Returns a list of list_ids which are applicable to this Class
    
    Each class should define their own version of this as it depends on group_ids for persons
    and company_status type for im_companies and you know what for other dynfield objects.
    
    Default gives back all the lists for the object_type of the object.
} {
    set object_types [my object_types]
    return [db_list lists "select category_id from im_categories c, acs_object_types ot where c.category_type= ot.type_category_type and object_type in ([template::util::tcl_to_sql_list $object_types])"]
}

::im::dynfield::Class ad_instproc default_list_id {} {
    Returns the default list_id for the class
} {
    set object_type [my object_type]
    return [db_string default_id "select category_id from im_categories where category = :object_type"]
}

#########################################
#
# Creator Procs for the created classes
#
#########################################

::im::dynfield::Class ad_instproc mk_save_method {} {
    This mk_save_method differs from the normal one as it takes extension tables into account
    
    
    This is also the place to insert special conditions if you need to edit 
    the user input before save. Usually this needs to be done for dates
    or any other combined widgets.
} { 
    # We need to get the attributes sorted by table
    set table_list [list]
    set attributes [list]
    set date_statements ""
    set instvar_statements ""
    set update_statements ""
    
    foreach {slot_name slot} [my array get db_slot] {
        $slot instvar name column_name table_name datatype dynfield_attribute_id
        if {![info exists table_name]} {
            set table_name [my table_name]
        }
        if {[lsearch $table_list $table_name]<0} {
            lappend table_list $table_name
            set updates($table_name) [list]
            set vars($table_name) [list]
            set attribute_ids($table_name) [list]
        }
        
        if {$column_name ne [my id_column]} {
            if {$datatype == "date"} {
                append date_statements "set $name \[template::util::date get_property ansi \[set $name\]\]
                "
            }
            lappend updates($table_name) "$column_name = :$name"                                
            lappend vars($table_name) $name
            lappend attribute_ids($table_name) $dynfield_attribute_id
            set attribute_name($dynfield_attribute_id) $name
        }
        lappend attributes $name
    }
    
    foreach table $table_list {
        switch $table {
            im_dynfield_cat_multi_value {
                append instvar_statments "my instvar object_id"
                foreach attribute_id $attribute_ids($table) {
                    # First delete all the old values
                    append update_statements "
                        my instvar $attribute_name($attribute_id)
                        db_dml dbqd..update_$attribute_name($attribute_id) \{delete from im_dynfield_cat_multi_value where attribute_id = $attribute_id and object_id = :object_id\}
                    "
                    append update_statements "
                        foreach category_id \$$attribute_name($attribute_id) \{
                            db_dml dbqd..update \{insert into im_dynfield_cat_multi_value (attribute_id,object_id,category_id) values ($attribute_id,:object_id,:category_id)\}
                        \}
                    "
                }
            }
            im_dynfield_attr_multi_value {
                append instvar_statments "my instvar object_id $vars($table)"
                foreach attribute_id $attribute_ids($table) {  
                    # First delete all the old values
                    append update_statements "
                        my instvar $attribute_name($attribute_id)
                        db_dml dbqd..update_$attribute_name($attribute_id) \{delete from im_dynfield_attr_multi_value where attribute_id = $attribute_id and object_id = :object_id\}"
                                      
                    append update_statements "
                        foreach attr_multival \$$attribute_name($attribute_id) \{
                            db_dml dbqd..update \{insert into im_dynfield_attr_multi_value (attribute_id,object_id,value) values ($attribute_id,:object_id,:attr_multival)\}
                        \}
                    "
                }
            }
            default {
                # Get the id column for that table
                set id_column [db_string id "select id_column from acs_object_type_tables where table_name = :table and object_type = '[my object_type]'" -default ""]
                if {$id_column == ""} {
                    set id_column [db_string id "select id_column from acs_object_types where object_type = '[my object_type]'"]
                }
                if {$updates($table) ne ""} {
                    append instvar_statements "my instvar object_id $vars($table)
                    "
                    append update_statements "
                        db_dml dbqd..update_${table} \{update $table set [join $updates($table) ,] where $id_column = :object_id \}
                    "
                }
            }
        }
    }
    
    if {$update_statements == ""} return

    set name_method [db_string name_method "select name_method from acs_object_types where object_type = '[my object_type]'"]

    if {$name_method == ""} {
	set name_method "ACS_OBJECT__DEFAULT_NAME"
    }
    set documentation "This is the save procedure for <b>[my object_type]</b>. It updates the following attributes:<ul><li>[join "$attributes" "</li><li>"] </li></ul>"
    my ad_instproc save {} [subst { $documentation } ] [subst {
        db_transaction {
            # Create the elements in the superclass first
            next
            ds_comment \[my serialize\]
            $instvar_statements
            $date_statements
            # Now run the updates
            $update_statements

	    # Now change the title
	    db_dml update_title "update acs_objects set title = ${name_method}(object_id) where object_id = :object_id"
        }
    }]
}

::im::dynfield::Class ad_instproc mk_insert_method {} {
    create method 'insert' for the application class
    The caller (e.g. method new) should care about db_transaction
    
    It also takes the extension tables into account
    
    This is also the place to insert special conditions if you need to edit 
    the user input before insert. Usually this needs to be done for dates
    or any other combined widgets.
} {
  # We need to get the attributes sorted by table
  set object_type [my object_type]
  set table_list [list [db_string table_name "select table_name from acs_object_types where object_type = :object_type"]]
  set attributes [list]
  foreach {slot_name slot} [my array get db_slot] {
      $slot instvar name column_name table_name dynfield_attribute_id
      if {![info exists table_name]} {
          set table_name [my table_name]
      }
      if {[lsearch $table_list $table_name]<0} {
          lappend table_list $table_name
          set columns($table_name) [list]
          set vars($table_name) [list]
          set attribute_ids($table_name) [list]
      }
        
      if {$column_name ne [my id_column]} {
          lappend columns($table_name) "$column_name"
          lappend vars($table_name) $name
          lappend attribute_ids($table_name) $dynfield_attribute_id
          set attribute_name($dynfield_attribute_id) $name
      }
      lappend attributes $name
  }
  
  set insert_statements ""
  foreach table $table_list {
      switch $table {
          im_dynfield_cat_multi_value {
              append instvar_statments "my instvar object_id $vars($table)"
              foreach attribute_id $attribute_ids($table) {                
                  append insert_statements "
                        my instvar $attribute_name($attribute_id)
                      if \{\[info exists $attribute_name($attribute_id)\]\} \{
                      foreach category_id \$$attribute_name($attribute_id) \{
                          db_dml dbqd..update \{insert into im_dynfield_cat_multi_value (attribute_id,object_id,category_id) values ($attribute_id,:object_id,:category_id)\}
                      \}
                    \}
                  "
              }
          }
          im_dynfield_attr_multi_value {
              append instvar_statments "my instvar object_id $vars($table)"
              foreach attribute_id $attribute_ids($table) {                
                  append insert_statements "
                    my instvar $attribute_name($attribute_id)
                      if \{\[info exists $attribute_name($attribute_id)\]\} \{
                      foreach attr_multival \$$attribute_name($attribute_id) \{
                          db_dml dbqd..update \{insert into im_dynfield_attr_multi_value (attribute_id,object_id,value) values ($attribute_id,:object_id,:attr_multival)\}
                      \}
                    \}
                  "
              }
          }
          default {
              # Get the id column for that table
              set id_column [db_string id "select id_column from acs_object_type_tables where table_name = :table and object_type = '[my object_type]'" -default ""]
              if {$id_column == ""} {
                  set id_column [db_string id "select id_column from acs_object_types where table_name = :table"]
              }
              lappend columns($table) "$id_column"
              lappend vars($table) "object_id"
              if {$columns($table) ne ""} {
                    append insert_statements "
                      my instvar object_id $vars($table)
                      foreach var \{$vars($table)\} \{
                          if \{!\[info exists \$var\]\} \{
                              set \$var \"\"
                          \}
                     \}
                     db_dml dbqd..insert_${table} \{insert into $table ([join $columns($table) ,]) values (\:[join $vars($table) ,\:]) \}
                              "
              }              
          }
      }
  }
  ds_comment "Inserts $insert_statements"
  
    set documentation "This will help the save_new function to correctly insert the object
    
    If you want to insert a new object though, ALWAYS call save_new ! <p/><b>[my object_type]</b>. It inserts the following attributes:<ul><li>[join "$attributes" "</li><li>"] </li></ul>"


    set name_method [db_string name_method "select name_method from acs_object_types where object_type = '[my object_type]'"]

    if {$name_method == ""} {
	set name_method "ACS_OBJECT__DEFAULT_NAME"
    }

    my ad_instproc insert {} [subst { $documentation } ] [subst {
            # Create the elements in the superclass first
            next

            # Now run the updates
            $insert_statements
	    # Now change the title
	    db_dml update_title "update acs_objects set title = ${name_method}(object_id) where object_id = :object_id"
    }]
}

::im::dynfield::Class ad_proc get_class_from_db {
    -object_type
} {
   Fetch an acs_object_type from the database and create
   an XOTcl class from this information.
   
   The XOTcl class is dynfield enabled

   @return class name of the created XOTcl class. This is in the ::im::dynfield realm
} {

    # some table_names and id_columns in acs_object_types are unfortunately upper case, 
    # so we have to convert to lower case here....
    db_1row dbqd..fetch_class {
        select object_type, supertype, pretty_name, lower(id_column) as id_column, lower(table_name) as table_name,
            status_column, type_column,status_type_table,type_category_type
        from acs_object_types where object_type = :object_type
    }
   
    set classname [my object_type_to_class "$object_type"]
   
    # Check if the supertype class exists and if not, create it.
    # This works recursive
    if {$supertype ne "acs_object" && ![my isclass [my object_type_to_class "$supertype"]]} {
        my get_class_from_db -object_type "$supertype"
    }
   
    # We might have to destroy the class later
    # [$classname destroy]   
        
    if {![my isclass $classname]} {
        # the XOTcl class does not exist, we create it
        my log "--db create class $classname superclass $supertype"
        my create $classname \
         -superclass [my object_type_to_class $supertype] \
         -object_type $object_type \
         -supertype $supertype \
         -pretty_name $pretty_name \
         -id_column $id_column \
         -table_name $table_name \
         -sql_package_name [namespace tail $classname] \
         -status_column $status_column \
         -type_column $type_column \
         -status_type_table $status_type_table \
         -type_category_type $type_category_type \
         -noinit
    }

    # Create the corresponding Form Class
    set form_class [::im::dynfield::Form object_type_to_class $object_type]
    set class_table_name $table_name
    
    if {![my isclass $form_class]} {
        ::xotcl::Class create $form_class \
            -superclass [::im::dynfield::Form object_type_to_class $supertype] \
            -ad_doc "This is the specific Form class for the object type ${object_type} and allows manipulation of the on_submit etc. blocks for this object_type when ::im::dynfield::Form generate is called. Obviously if you know your      object_type you could just as well call this Class."
    }
    
    set attributes [db_list_of_lists dbqd..get_atts {
        select attribute_name, aa.pretty_name, aa.pretty_plural, datatype, 
        default_value, min_n_values, max_n_values, table_name, ida.attribute_id,
        ida.widget_name, already_existed_p, deprecated_p, include_in_search_p, also_hard_coded_p,
        storage_type_id, idw.widget, parameters as widget_parameters, deref_plpgsql_function, sql_datatype
        from acs_attributes aa, im_dynfield_attributes ida, im_dynfield_widgets idw        
        where aa.attribute_id = ida.acs_attribute_id
        and ida.widget_name = idw.widget_name
        and aa.object_type = :object_type
    }]
   
   set slots ""
   set multival_attrs [list]
   foreach att_info $attributes {
     foreach {attribute_name pretty_name pretty_plural datatype default_value 
       min_n_values max_n_values table_name attribute_id widget_name already_existed_p deprecated_p include_in_search_p also_hard_coded_p storage_type_id widget widget_parameters deref_plpgsql_function sql_datatype} $att_info break

        # if the attribute does not have a table_name defined
        # Use the default one of the class
        if {$table_name == ""} {
            set table_name $class_table_name
        }

     # ignore some erroneous definitions in the acs meta model
     if {[my exists exclude_attribute($table_name,$attribute_name)]} continue

     set defined_att($attribute_name) 1

    # Deal with the multivalues
    if {[lsearch [im_dynfield_multimap_ids] $storage_type_id] < 0} {
        set multivalued false
    } else {
        set multivalued true
        set table_name [im_dynfield_multimap_table -storage_type_id $storage_type_id]
        lappend multival_attrs $attribute_name
    }

     set cmd [list ::im::dynfield::Attribute create $attribute_name \
                  -pretty_name $pretty_name \
                  -pretty_plural $pretty_plural \
                  -datatype $datatype \
                  -min_n_values $min_n_values \
                  -max_n_values $max_n_values \
                  -table_name $table_name \
                  -widget_name $widget_name \
                  -already_existed_p $already_existed_p \
                  -deprecated_p $deprecated_p \
                  -include_in_search_p $include_in_search_p \
                  -also_hard_coded_p $also_hard_coded_p \
                  -storage_type_id $storage_type_id \
                  -widget $widget \
                  -widget_parameters $widget_parameters \
                  -sql_datatype $sql_datatype \
                  -dynfield_attribute_id $attribute_id \
                  -deref_plpgsql_function $deref_plpgsql_function \
                  -multivalued $multivalued]
     
     if {$default_value ne ""} {
       # if the default_value is "", we assume, no default
       lappend cmd -default $default_value
     }
     
     
     append slots $cmd \n
     if {$multivalued == "false"} {
     #    $classname create ${attribute_name}_deref
     }
   }
 #  if {[catch {$classname slots $slots} errorMsg]} {
 #    error "Error during slots: $errorMsg"
 #  }
   $classname slots $slots
   $classname create object_type
   $classname set table_name $class_table_name
   $classname set multival_attrs $multival_attrs
   $classname init
   return $classname
}

##############################
# Object Cache
# 
# Kudos to Stefan Soberning
##############################

::xotcl::Class create ObjectCache
 ObjectCache instproc get_instance_from_db {
    -id:required
 } {
     set object ::$id
     set code [ns_cache eval xotcl_object_cache $object {
          set created 1
          set o [next]
          return [::Serializer deepSerialize $o]
        }]
    if {![info exists created]} {
      if {[my isobject $object]} {
      } else {
            set o [eval $code]
            $object initialize_loaded_object
      }
    }
    
    return $object
}

ObjectCache instproc delete {-id:required} {
      next
      my flush -id $id
}

ObjectCache ad_proc flush {-id:required} {
    Flush
} {
    ::xo::clusterwide ns_cache flush xotcl_object_cache ::$id
    ds_comment "Flushing ::$id"
}

ObjectCache instproc flush {-id:required} {
      ::xo::clusterwide ns_cache flush xotcl_object_cache ::$id
      ds_comment "Flushing ::$id"
}

# Here we do the mixins
#::im::dynfield::Class mixin ObjectCache
    
