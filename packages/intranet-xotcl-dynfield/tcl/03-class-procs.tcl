# packages/intranet-xo-dynfield/tcl/03-class-procs.tcl
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

ad_library {

	Class procedures
	
    @creation-date 2008-08-09
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

namespace eval ::im {}
namespace eval ::im::dynfield {}


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

::im::dynfield::Class ad_instproc object_type_ids {
} {
    Returns a list of object_type_ids which are applicable to this Class
    
    Each class should define their own version of this as it depends on group_ids for persons
    and company_status type for im_companies and you know what for other dynfield objects.
    
    Default gives back all the lists for the object_type of the object.
} {
    set object_types [my object_types]
    return [db_list lists "select category_id from im_categories c, acs_object_types ot where c.category_type= ot.type_category_type and object_type in ([template::util::tcl_to_sql_list $object_types])"]
}

::im::dynfield::Class ad_instproc default_object_type_id {} {
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


##################################
#
# Retrieve an IM Dynfield Object
#
##################################

::im::dynfield::Class ad_instproc instance_select_query {
    {-id ""}
    {-type_id ""}
    {-status_id ""}
    {-orderby ""}
    {-cond ""}
    {-outer_tables ""}
    {-inner_tables ""}
    {-with_subtypes:boolean true}
    {-with_substatus:boolean true}
    {-parent_id ""}
    {-parent_id_column ""}
    {-page_size 20}
    {-page_number ""}
    {-attributes ""}
} {
    returns the SQL-query to select the CrItems of the specified object_type
    The object should be of a dynfield enable object though
    @param id if we only want to retrieve a single object with this query
    
    @param orderby for ordering the solution set
    @param cond a list of where_clauses clause for restricting the answer set
    @param with_subtypes return subtypes as well
    @param with_children return immediate child objects of all objects as well
    @param outer_tables a list of table_name and id_column pairs where the id_column matches the id_column of the class (e.g. im_timesheet_tasks and task_id when matching im_projects as the task_id = project_id). Used in an OUTER join.
    @param inner_tables  a list of table_name and id_column pairs where the id_column matches the id_column of the class (e.g. im_timesheet_tasks and task_id when matching im_projects as the task_id = project_id). Used in a normal (INNER) join.
    @param parent_id parent_id for this query
    @param parent_id_column name of the parent_id column. Use full table_name like im_projects.parent_id
    @param publish_status one of 'live', 'ready', or 'production'
    @param base_table typically automatic view, must contain title and revision_id
    @param attributes List of column names in the tables which we want to have as Attributes in the Object.
    @return sql query
} {
    set tables [list]
    set id_column [my id_column]
    set left_joins ""

    if {$id ne ""} {
	lappend cond "[my table_name].$id_column = $id"
    }
    
    if {$parent_id ne "" && $parent_id_column ne ""} {
	lappend cond "$parent_id_column = $parent_id"
    }

    if {$type_id ne ""} {
	set type_column [my type_column]
	if {$with_subtypes} {
	    lappend cond "$type_column in ([template::util::tcl_to_sql_list [im_sub_categories $type_id]])"
	} else {
	    lappend cond "$type_column = $type_id"
	}
    }

    if {$status_id ne ""} {
	set status_column [my status_column]
	if {$with_substatus} {
	    lappend cond "$status_column in ([template::util::tcl_to_sql_list [im_sub_categories $status_id]])"
	} else {
	    lappend cond "$status_column = $status_id"
	}
    }
    
    if {$page_number ne ""} {
      set limit $page_size
      set offset [expr {$page_size*($page_number-1)}]
    } else {
      set limit ""
      set offset ""
    }

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
		lappend cond "$tn.[$cl id_column] = $ref_column"
	    }
	    
	    # Deal with the extra tables
	    db_foreach table "select table_name, id_column from acs_object_type_tables where object_type = '[$cl object_type]' and table_name not in ([template::util::tcl_to_sql_list $tables])" {
		lappend outer_tables [list $table_name $id_column]
	    }
	}
    }
    foreach outer_table $outer_tables {
	set table_name [lindex $outer_table 0]
	set id_column [lindex $outer_table 1]
	if {[lsearch $tables $table_name] <0 } {
	    # Extra table, join_expression needed
	    lappend left_joins "left outer join $table_name on (acs_objects.object_id = ${table_name}.${id_column})"
	}
    }

    foreach inner_table $inner_tables {
	set table_name [lindex $inner_table 0]
	set id_column [lindex $inner_table 1]
	lappend tables $table_name
	lappend cond "${table_name}.${id_column} = acs_objects.object_id"
    }

    set sql [::xo::db::sql select \
                -vars [join $attributes ",\n"] \
                -from "[join $tables ",\n"] [join $left_joins " "]"\
                -where [join $cond " and "] \
                -orderby $orderby \
                -limit $limit -offset $offset]
    #my log "--sql=$sql"
    return $sql
}

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
    $r db_1row dbq..get_instance [$class instance_select_query -id $id]

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


::im::dynfield::Class ad_instproc get_instances_from_db {
    {-type_id ""}
    {-status_id ""}
    {-orderby ""}
    {-cond ""}
    {-outer_tables ""}
    {-inner_tables ""}
    {-with_subtypes:boolean true}
    {-with_substatus:boolean true}
    {-parent_id ""}
    {-parent_id_column ""}
    {-page_size 20}
    {-page_number ""}
    {-attributes ""}
} {
    Returns a set (ordered composite) of the answer tuples of 
    an 'instance_select_query' with the same attributes.
    The tuples are instances of the class, on which the 
    method was called.

    
    @param attributes List of column names in the tables which we want to have as Attributes in the Object.
    @see instance_select_query
} {
    ns_log Notice "instantiate [self]"
    set s [my instantiate_objects -sql \
	       [my instance_select_query \
		    -type_id $type_id \
		    -cond $cond \
		    -outer_tables $outer_tables \
		    -inner_tables $inner_tables \
		    -orderby $orderby \
		    -with_subtypes $with_subtypes \
		    -status_id $status_id \
		    -with_substatus $with_substatus \
		    -parent_id $parent_id \
		    -parent_id_column $parent_id_column \
		    -page_size $page_size \
		    -page_number $page_number \
            -attributes $attributes
		   ] \
	       -object_class "[self]"
	  ]
    return $s
}


#################################
#
# Element handling for the class
#
#################################

::im::dynfield::Class ad_proc elements {
    {-object_type_id ""}
    {-object_type ""}
    {-order_by "pos_y"}
    {-attribute_names ""}
} {
    Returns an xotcl composite of all the elements of this class for the given object_type_id or object_type.
    
    The list is sorted in order of how the attributes should appear according to the object_type_id order
    
    @param object_type_id The object_type_if for the which to get the elements
    @param object_type Alternatively get all the elements of an object_type
    @param order_by Sorting of the elements. This is especially needed in the spreadsheet functions as the sort_order of the elements will define in which orders the columns in the spreadsheet show up
    @param attribute_names A list of attribute names for which we want to the the elements.
} {

    if {$object_type_id eq ""} {
        if {$object_type eq ""} {
            ad_return_error "Missing object_type" "You need to specify an object_type or an object_type_id"
        } else {
            set tam_clause "and aa.object_type = '$object_type'"
        }
    } else {
        set tam_clause "and tam.object_type_id = $object_type_id and tam.display_mode != 'none'"
    }

    if {$attribute_names ne ""} {
        set attribute_clause "and aa.attribute_name in ([template::util::tcl_to_sql_list $attribute_names])"
    } else {
        set attribute_clause ""
    }

    set sql "
    select 
           ida.attribute_id as dynfield_attribute_id,
           tam.section_heading,
           aa.attribute_id,
           aa.object_type,
           aa.attribute_name,
           aa.pretty_name,
           aa.pretty_plural,
           aa.datatype,
           aa.default_value,
           aa.min_n_values,
           aa.max_n_values,
           aa.column_name,
           aa.table_name,
           tam.required_p,
           ida.include_in_search_p,
           ida.also_hard_coded_p,
           ida.deprecated_p,
           idl.label_style,
           idl.pos_y as sort_order,
           ida.widget_name,
           idw.widget,
           tam.help_text,
           tam.object_type_id as object_type_id,
           tam.default_value,
           idw.widget_id,
           idw.storage_type_id
     from
           acs_attributes aa,
           im_dynfield_widgets idw,
           im_dynfield_attributes ida,
           im_dynfield_type_attribute_map tam,
           im_dynfield_layout idl
     where
           ida.acs_attribute_id = aa.attribute_id
           and ida.widget_name = idw.widget_name
           and tam.attribute_id = ida.attribute_id
           and ida.attribute_id = idl.attribute_id
           $tam_clause
           $attribute_clause
    order by $order_by
     "

    set object_class "::im::dynfield::Element"
    set __result [::xo::OrderedComposite new]
    $__result destroy_on_cleanup

    db_with_handle -dbn "" db {
        
        set selection [db_exec select $db elements $sql]
        while {1} {
            set continue [ns_db getrow $db $selection]
            if {!$continue} break
            set o [$object_class new]
            $__result add $o
            
            foreach {att val} [ns_set array $selection] {$o set $att $val}
            if {[$o exists object_type]} {
                # set the object type if it looks like managed from XOTcl
                if {[string match "::*" [set ot [$o set object_type]] ]} {
                    $o class $ot
                }
            }
            if {[$o istype ::xo::db::Object]} {
                $o initialize_loaded_object
            }
            #my log "--DB more = $continue [$o serialize]" 
        }
    }
    ds_comment "sql ::: $sql"    
    return $__result
}

::im::dynfield::Class ad_proc generate_csv {
    {-Objects:required}
} {
    Returns a CSV of all the Dynfield Objects 
    
    The list is sorted in order of how the attributes should appear according to the object_type_id order
    
    @param Objects xotcl composite with all the Objects
} {

    # Set the header
    set __csv_cols [list]
    set __csv_labels [list]
    set Object [lindex [$Objects children] 0]
    set object_type [[$Object class] object_type]
    set Elements [::im::dynfield::Class elements -object_type "$object_type"]
    foreach Element [$Elements children] {
        set attribute_name [$Element attribute_name]
        
        # Make sure we only append the attribute once!
        if {[lsearch $__csv_cols $attribute_name] <0} {
            lappend __csv_cols $attribute_name
            lappend __csv_labels [template::list::csv_quote [$Element pretty_name]]
        }
    }
    append __output "\"[join $__csv_labels "\",\""]\"\n"
    
    foreach Object [$Objects children] {
        set __cols [list]
        foreach __element_name $__csv_cols {
            lappend __cols [template::list::csv_quote [$Object set ${__element_name}_deref]]
        }
        append __output "\"[join $__cols "\",\""]\"\n"
    }
    
    return $__output
}


::im::dynfield::Class ad_proc generate_spreadsheet {
    {-Objects:required}
    {-Elements ""}
    {-view_name ""}
    {-ods_file ""}
    {-table_name ""}
    {-output_filename ""}
    {-attribute_names ""}
} {
    Returns an ODS of all the Dynfield Objects 
    
    The list is sorted in order of how the attributes should appear according to the object_type_id order
    
    @param view_name Name of the view which will be used generate the columns
    @param attribute_name List of attributes to limit the Elements in case we don't have a view_name
    @param object_type_ids This is a list of object_type_ids. Note that the order is important
} {

    # Check if we have the table.ods file in the proper place
    if {$ods_file eq ""} {
        set ods_file "[acs_package_root_dir "intranet-openoffice"]/templates/table.ods"
    }
    if {![file exists $ods_file]} {
        ad_return_error "Missing ODS" "We are missing your ODS file $ods_file . Please make sure it exists"
    }

    # The table_name is not allowed to contain any quotes
    regsub -all {\"} table_name {'} table_name
    
    template::multirow create columns visible_for variable_name datatype column_name

    if {$view_name ne ""} {
        # Get the "view" (=list of columns to show)
        set view_id [util_memoize [list db_string get_view_id "select view_id from im_views where view_name = '$view_name'" -default 0]]
        if {0 == $view_id} {
            ad_return_error Error "intranet_openoffice::spreadsheet: We didn't find view_name = $view_name"
        }

        # ---------------------- Get Columns ----------------------------------
        # Define the column headers and column contents that
        # we want to show:
        #
        
        set variables [list]
        set column_sql "
         	select	*
         	from	im_view_columns
        	where	view_id=:view_id
		    and group_id is null
         	order by sort_order"
        
        
        db_foreach column_list_sql $column_sql {
            template::multirow append columns $visible_for $variable_name $datatype $column_name
        }
    } else {
        
        if {$Elements eq ""} {
            # get the Elements definition from the object_type
            set Object [lindex [$Objects children] 0]
            set object_type [[$Object class] object_type]
            set Elements [::im::dynfield::Class elements -object_type "$object_type" -attribute_names $attribute_names]
        }
        
        # This will become the list of elements (NOT Elements), which is a
        # trimmed down list where we only take the first element which we
        # find in Elements 
        set elements [list]
        set attributes [list]
        foreach Element [$Elements children] {
            set attribute_name [$Element attribute_name]
            # Make sure we only append the element once!
            if {[lsearch $attributes $attribute_name] <0} {
                lappend attributes $attribute_name
                lappend elements $Element
            }
        }
        
        foreach Element $elements {
            template::multirow append columns "" "[$Element attribute_name]_deref" [$Element widget] [$Element pretty_name]
        }
    }

    # Now we can loop through the Column
    # Set the column definitions and the first row with the header
    set __column_defs ""
    set __header_defs ""
    
    template::multirow foreach columns {

        # We need to check the visibility on the calling procedure....
        if {"" == $visible_for || [eval $visible_for]} {
            if {$variable_name ne ""} {
                switch $datatype {
                    date {
                        append __column_defs "<table:table-column table:style-name=\"co2\" table:default-cell-style-name=\"ce4\"/>\n"
                    }
                    currency {
                        append __column_defs "<table:table-column table:style-name=\"co2\" table:default-cell-style-name=\"ce7\"/>\n"
                    }
                    float {
                        append __column_defs "<table:table-column table:style-name=\"co2\" table:default-cell-style-name=\"ce1\"/>\n"
                    }
                    percentage {
                        append __column_defs "<table:table-column table:style-name=\"co2\" table:default-cell-style-name=\"ce5\"/>\n"
                    }
                    integer {
                        append __column_defs "<table:table-column table:style-name=\"co2\" table:default-cell-style-name=\"ce2\"/>\n"
                    }
                    textarea {
                        # Don't shrink to fit textareas. But Autobreak them
                        # this is done using style ce4
                        append __column_defs "<table:table-column table:style-name=\"co3\" table:default-cell-style-name=\"ce8\"/>\n"
                    }
                    default {
                        # style ce3 is set to "shrink to fit", so the size of
                        # the font automatically decreases if needed
                        append __column_defs "<table:table-column table:style-name=\"co1\" table:default-cell-style-name=\"ce3\"/>\n"
                    }
                }

                # Localize the string
                set key [lang::util::suggest_key $column_name]
                set column_name [lang::message::lookup "" intranet-core.$key $column_name]

                append __header_defs " <table:table-cell office:value-type=\"string\"><text:p>$column_name</text:p></table:table-cell>\n"
                set datatype_arr($variable_name) $datatype
                lappend variables $variable_name
            }
        }
    }
    
    set __output $__column_defs
    
    # Set the first row
    append __output "<table:table-row table:style-name=\"ro1\">\n$__header_defs</table:table-row>\n"
    
    # No create the single rows for each Object
    foreach Object [$Objects children] {
        append __output "<table:table-row table:style-name=\"ro1\">\n"

        foreach variable $variables {        
            set value [$Object set $variable]
            switch $datatype_arr($variable) {
                date {
                    append __output " <table:table-cell office:value-type=\"date\" office:date-value=\"[lc_time_fmt $value %F]\"></table:table-cell>\n"
                }
                currency {
                    append __output " <table:table-cell office:value-type=\"currency\" office:currency=\"EUR\" office:value=\"$value\"></table:table-cell>\n"
                }
                percentage {
                    if {$value ne ""} {
                        set value [expr $value / 100]
                    }
                    append __output "<table:table-cell office:value-type=\"percentage\" office:value=\"$value\"></table:table-cell>"
                }
                float {
                    append __output "<table:table-cell office:value-type=\"float\" office:value=\"$value\"></table:table-cell>"
                }
                default {
                    append __output " <table:table-cell office:value-type=\"string\"><text:p>$value</text:p></table:table-cell>\n"
                }
            }
        }
        append __output "</table:table-row>\n"
    }
    intranet_oo::parse_content -template_file_path $ods_file -output_filename $output_filename
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


ad_proc -public -callback im_dynfield_attribute_after_update -impl xotcl_dynfields_reload_class {
    {-object_type}
    {-attribute_name}
} {
    Relaod the classe when a dynfield is changed
} {

    # ------------------------------------------------------------------
    # Reload the class
    # ------------------------------------------------------------------
    set class [::im::dynfield::Class object_type_to_class $object_type]
    $class destroy
    ::im::dynfield::Class get_class_from_db -object_type $object_type
} 
