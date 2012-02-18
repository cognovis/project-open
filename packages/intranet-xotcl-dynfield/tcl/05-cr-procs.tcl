# packages/intranet-xo-dynfield/tcl/05-cr-procs.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# 

ad_library {
    
    Interface for CR enabled Dynfields.
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-03-18
    @cvs-id $Id$
}


#############################
#
# Meta Class for the creation
# Of other classes
# 
##############################

::xotcl::MetaSlot create ::im::dynfield::CrAttribute \
    -superclass ::xo::db::Attribute \
    -parameter {
	{widget_name}
	{already_existed_p f}
	{deprecated_p f}
	{include_in_search_p t}
	{also_hard_coded_p t}
	{storage_type_id}
	{widget}
	{widget_parameters}
	{sql_datatype}
	{deref_plpgsql_function "im_name_from_id"}
	{table_name}
	{pos_y 0}
	{label_style "plain"}
	{default_value ""}
	{dynfield_attribute_id ""}
    }    


::im::dynfield::CrAttribute instproc create_attribute {} {
    if {![my create_acs_attribute]} return
    
    my instvar datatype pretty_name min_n_values max_n_values domain column_name table_name required name
    my instvar widget_name already_existed_p deprecated_p include_in_search_p also_hard_coded_p default_value
    my instvar storage_type_id widget widget_parameters sql_datatype deref_plpgsql_function pos_y label_style
    
    set object_type [$domain object_type]
    
    # Create the class if it does not exist (albeit unlikely)
    if {![::xo::db::Class object_type_exists_in_db -object_type $object_type]} {
        $domain create_object_type
    }

    # do nothing, if create_acs_attribute is set to false
    if {![my create_acs_attribute]} return
    
    my instvar name column_name datatype pretty_name domain
    set object_type [$domain object_type]
    
    if {$object_type eq "content_folder"} {
        # content_folder does NOT allow to use create_attribute etc.
        return
    }

    #my log "check attribute $column_name ot=$object_type, domain=$domain"
    if {[db_string dbqd..check_att {select 0 from acs_attributes where 
        attribute_name = :column_name and object_type = :object_type} -default 1]} {
                
        ::xo::db::sql::content_type create_attribute \
            -content_type $object_type \
            -attribute_name $column_name \
            -datatype $datatype \
            -pretty_name $pretty_name \
            -column_spec [my column_spec]
    }
    
    if {$required == "false"} {
        set required_p 0
    } else {
        set required_p 1
    }
    
    # Create the acs_attribute along with the im_dynfield one.
    # If the acs_attribute already exists we just create the dynfield attribute
    
    set im_dynfield_attribute_exists [im_dynfield::attribute::exists_p -object_type $object_type -attribute_name $name]
    
    if {![exists_and_not_null table_name]} {
        set table_name [::xo::db::Class get_table_name -object_type $object_type]
    }
    
    if {!$im_dynfield_attribute_exists} {
         im_dynfield::attribute::add \
            -object_type $object_type \
            -widget_name $widget_name \
            -attribute_name $name \
            -pretty_name $pretty_name \
            -pretty_plural $pretty_name \
            -table_name $table_name \
            -required_p $required_p \
            -modify_sql_p "t" \
            -deprecated_p $deprecated_p \
            -datatype $datatype \
            -default_value $default_value \
            -include_in_search_p $include_in_search_p \
            -also_hard_coded_p $also_hard_coded_p \
            -label_style $label_style \
            -pos_y $pos_y
    }
}

::xotcl::Class create ::im::dynfield::CrClass \
    -superclass ::xo::db::CrClass \
    -parameter {
        {status_column ""}
        {status_type_table ""}
        {type_column ""}
        {type_category_type ""}
        multival_attr_ids
    } -ad_doc {
        ::im::dynfield::Class is a meta class for interfacing with dynfield enabled acs_object_types.
        acs_object_types are instances of this meta class. The meta class defines the behavior common to 
        all acs_object_types.
        
        @param status_columns Column where the status_id is stored
        @param status_type_table Tablename where the status type is stored
        @param type_column Which column stores the type_id of the object
        @param type_category_type Which is the defaul im_category_type for this object_type
        @param multival_attr_ids Storage slot for the list of multivalued attribute_ids so we can quickly access them
    }


::im::dynfield::CrClass ad_instproc create_object_type {} {
    We need to save additional stuff when we create an object_type for dynfields.
} { 
    next
    
    # Set the needed attributes so we can insert them
    foreach attribute [list object_type type_category_type status_type_table status_column type_column] {
        set $attribute [my $attribute]
    }
    
    if {$status_type_table eq ""} {
        set status_type_table [my table_name]
    }
    
    # Then update the acs_object_type
    db_dml update "update acs_object_types set type_category_type = :type_category_type, status_column = :status_column, type_column = :type_column, status_type_table = :status_type_table where object_type = :object_type"	
    # Create a new category for this list with the same name
    if {$type_category_type ne ""} {
        db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:object_type, :type_category_type)"
    }
}


::im::dynfield::CrClass ad_instproc save_new {} {
    Additional stuff if we save an instance of this class, e.g. if we change it on the fly.
} {    
    # First generate the normal ::xo::db::CrClass
    next

    # Set the needed attributes so we can insert them
    foreach attribute [list object_type type_category_type status_type_table status_column type_column] {
        set $attribute [my $attribute]
    }

    if {$status_type_table eq ""} {
        set status_type_table [my table_name]
    }

    set pretty_name [db_string pretty "select pretty_name from acs_object_types where object_type = :object_type" -default $object_type]
    
    if {$type_category_type eq ""} {
        set type_category_type "$pretty_name Type"
    }
    
    set status_category_type "$pretty_name Status"
    
    # Then update the acs_object_type
    db_dml update "update acs_object_types set type_category_type = :object_type_category, status_column = :status_column, type_column = :type_column, status_type_table = :status_type_table where object_type = :object_type"	

    # Create a new category for this list with the same name
    db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:object_type, :type_category_type)"
    db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:object_type, :status_category_type)"
}

::im::dynfield::CrClass proc object_type_to_class {name} {
  switch -glob -- $name {
    acs_object       {return ::im::dynfield::Object}
    content_revision {return ::xo::db::CrItem}
    ::*              {return ::im::dynfield::CrClass::[namespace tail $name]}
    default          {return ::im::dynfield::CrClass::$name}
  }
}


::im::dynfield::CrClass ad_proc object_supertypes {
    -object_type
    {-exclude_list ""}
} {
    Return a list of object_types starting with the current type and ending with acs_object,
    looping through the whole hierarchy
    
    @param object_type object_type from which we start
    @param exclude_list List of object_types which we don't want returned. Useful e.g. to exclude acs_objects
} {
    return [util_memoize [list ::im::dynfield::CrClass object_supertypes_not_cached -object_type $object_type -exclude_list $exclude_list]]
}

::im::dynfield::CrClass ad_proc object_supertypes_not_cached {
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

::im::dynfield::CrClass ad_instproc object_type_ids {
} {
    Returns a list of object_type_ids which are applicable to this Class
    
    Each class should define their own version of this as it depends on group_ids for persons
    and company_status type for im_companies and you know what for other dynfield objects.
    
    Default gives back all the lists for the object_type of the object.
} {
    set object_types [my object_types]
    return [db_list lists "select category_id from im_categories c, acs_object_types ot where c.category_type= ot.type_category_type and object_type in ([template::util::tcl_to_sql_list $object_types])"]
}

::im::dynfield::CrClass ad_instproc default_object_type_id {} {
    Returns the default object_type_id for the class
} {
    set object_type [my object_type]

    if {[catch {
	set object_type_id [db_string default_id "select min(category_id) from im_categories c, acs_object_types ot where c.category_type= ot.type_category_type and object_type =:object_type" -default 0]} err_msg]} {
	ad_return_complaint 1 "
		<b>[lang::message::lookup "" intranet-dynfield.Configuration_Error "Configurtion Error"]</b>:
		The system has found more then one category with the name '$object_type'.<br>
	"
	ad_script_abort
    }
    if {0 == $object_type_id} {
	ad_return_complaint 1 "
		<b>[lang::message::lookup "" intranet-dynfield.Configuration_Error "Configurtion Error"]</b>:
		The system could not find a category for object_type '$object_type'.<br>
	"
	ad_script_abort
    }
    return $object_type_id
}

#########################################
#
# Creator Procs for the created classes
#
#########################################

::im::dynfield::CrClass ad_instproc mk_save_method {} {
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
    my ad_instproc save {
        {-live_p:boolean true} 
    } [subst { $documentation } ] [subst {
        db_transaction {
            # Create the elements in the superclass first
            next
            $instvar_statements
            $date_statements
            # Now run the updates
            $update_statements

	    # Now change the title
	    db_dml update_title "update acs_objects set title = ${name_method}(object_id) where object_id = :object_id"
        }
    }]
}

::im::dynfield::CrClass ad_instproc mk_insert_method {} {
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

::im::dynfield::CrClass ad_proc get_class_from_db {
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
    
    set attributes [db_list_of_lists dbqd..get_atts "
        select attribute_name, aa.pretty_name, aa.pretty_plural, datatype, 
        default_value, min_n_values, max_n_values, table_name, ida.attribute_id,
        ida.widget_name, already_existed_p, deprecated_p, include_in_search_p, also_hard_coded_p,
        storage_type_id, idw.widget, parameters as widget_parameters, deref_plpgsql_function, sql_datatype
        from acs_attributes aa, im_dynfield_attributes ida, im_dynfield_widgets idw        
        where aa.attribute_id = ida.acs_attribute_id
        and ida.widget_name = idw.widget_name
        and aa.object_type = :object_type"
    ]
   
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



##################################
#
# Retrieve an IM Dynfield Object
#
##################################
::im::dynfield::CrClass ad_instproc fetch_query {id} {
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
    return "SELECT [join $attributes ",\n"]\nFROM [join $tables ",\n"] [join $left_joins " "] \nWHERE [join $join_expressions " \n and "] limit 1"
}


######################################
# Deal with Objects
#
######################################

::im::dynfield::CrClass create ::im::dynfield::CrItem \
    -superclass ::xo::db::CrItem \
    -table_name im_xo_items -id_column critem_id


::im::dynfield::CrItem instproc insert {} {my log no-insert;}


::im::dynfield::CrItem proc get_context {package_id_var user_id_var ip_var} {
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
    ::im::dynfield::CrItem ad_instproc save_new {
	-package_id -creation_user -creation_ip
    } {
	Save the XOTcl Object with a fresh acs_object
	in the database.
	
	@return new object id
    } {
	if {![info exists package_id] && [my exists package_id]} {
	    set package_id [my package_id]
	}
	
	::im::dynfield::CrItem get_context package_id creation_user creation_ip
	db_transaction {
	    set id [::im::dynfield::CrItem new_acs_object \
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
    
    ::im::dynfield::CrItem proc new_acs_object {
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



::im::dynfield::CrItem ad_instproc object_type_ids {
} {
    Returns a list of object_type_ids which are applicable to this object
    
    Each class should define their own version of this as it depends on group_ids for persons
    and company_status type for im_companies and you know what for other dynfield objects.
    
    Default gives back all the lists for the object_type of the object.
} {
    my instvar object_type
    return [db_list lists "select category_id from im_categories c, acs_object_types ot where c.category_type= ot.type_category_type and object_type = '$object_type'"]
}

::im::dynfield::CrItem ad_instproc lists {} {
    Return the list_names for the object
} {
    return [my object_type]
}

::im::dynfield::CrItem instproc save {} {
    my instvar object_id
    ::xo::clusterwide ns_cache flush xotcl_object_cache ::$object_id
}

::im::dynfield::CrItem ad_instproc rel_options {} {
    Return a list of possible relationship_types this object can have
} {    
    return [db_list rel_types "select rel_type from acs_rel_types where object_type_one in ([template::util::tcl_to_sql_list [my object_types]]) or object_type_two in ([template::util::tcl_to_sql_list [my object_types]])"]
}

::im::dynfield::CrItem ad_instproc value {element} {
        Returns the value of the attribute_name derefed
        @param element Element object we need the value for
} {

    set attribute_name [$element attribute_name]

    switch [$element widget] {
        date {
            set value [my set $attribute_name]
            if {$value ne ""} {
                set value [template::util::date::get_property display_date $value]
            }
        }
	richtext {
            set value [my set $attribute_name]
            if {$value ne ""} {
                set value [template::util::richtext::get_property contents $value]
            }
	}
	im_category_tree {
            set value [my set $attribute_name]
            if {$value ne ""} {
                set value [im_category_from_id $value]
            }
	}
	generic_sql {
            set value [my set $attribute_name]
            if {$value ne ""} {
                set value [im_dynfield::generic_sql_option_name -widget_name [$element widget_name] -object_id $value]
            }
	}
	default {
	    set value [my set ${attribute_name}_deref]
	}
    }
}    

::im::dynfield::CrItem ad_instproc full_name {} {
    Returns the fully formatted name as intended by the name_method
    of acs_object_types table
} {
    set name_method [db_string name_method "select name_method from acs_object_types where object_type = '[my object_type]'"]
    return [db_string name "select ${name_method}([my object_id]) from dual"]
}
