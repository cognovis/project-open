ad_library {

	Procedures for intranet-contacts
	
    @creation-date 2008-03-18
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}


namespace eval intranet-contacts:: {}

ad_proc -public intranet-contacts::supported_object_types {
} {
    Returns a list of object types which are supported by intranet-contacts
} {
    return [list person im_company im_office user]
}

ad_proc -public intranet-contacts::supported_rel_types {
} {
    Returns a list of object types which are supported by intranet-contacts
} {
    return [db_list rel_types "select object_type from acs_object_types, acs_rel_types where supertype in ('im_biz_object_member','contact_rel') and object_type = rel_type"]
}

ad_proc -public intranet-contacts::object_type_pretty {
    {-object_type}
} {
    Return the pretty string for an object_type. This handles the special party case
    
    @param object_type Object Type we are looking the string up for
} {
    set type_pretty "[lang::message::lookup "" intranet-core.[lang::util::suggest_key $object_type] " "]"
    if {$type_pretty eq " "} {
       set type_pretty [db_string object_type_pretty {} -default $object_type]
    }
    
    return $type_pretty
}


ad_proc -public intranet-contacts::categories {
    {-expand "all"}
    {-indent_with "..."}
    {-object_types}
    {-no_member_count:boolean}
} {
    Return the categories that belong to object_types
    
    This is somewhat based on contact::groups which is what it should replace.
    
    @param indent_with What should we indent the category name with
    @param output Format in which to output the groups. A tcl list of lists is standard
    @param indent_with String to use for indention of the category name in the tree
    @param no_member_count Do not count the members of the category of the types
    @return list of lists with the category_id, the category_name and the number of entries
} {

    set category_list [list]
    foreach object_type $object_types {
        # Get the categories
        foreach category [im_dynfield::type_categories_for_object_type -object_type $object_type] {
            set count 0
            util_unlist $category category_id category_name
            if {!$no_member_count_p} {
                if {$object_type eq "group"} {
                    set group_id $category_name
                    set count [db_string count "select count(distinct member_id) from group_approved_member_map where group_id = :group_id"]
                    set category_name [contact::group::name -group_id $group_id]
                } else {
                    db_1row table_info "select table_name,status_type_table, type_column from acs_object_types where object_type = :object_type"
                    set count [db_string count "select count(*) from $table_name where $type_column = :category_id"]
                }
                lappend category_list [list $category_id $category_name $count $object_type]
            } else {
                lappend category_list [list $category_id $category_name "" $object_type]
            }
        }
    }
    return $category_list
}

ad_proc -public intranet-contacts::table_and_join_clauses {
    {-object_type}
    {-category_id ""}
    {-and:boolean}
} {
    Return a list of table_names and join_clauses which are needed
    to create a query for this object_type
} {

    set class [::im::dynfield::Class object_type_to_class $object_type]
    set contact_tables [list]
    if {$and_p} {
        set join_clauses ""
    } else {
        set join_clauses "1=1"
    }
    
    foreach object_typ [::im::dynfield::Class object_supertypes -object_type $object_type -exclude_list "acs_object"] {
        set object_class [::im::dynfield::Class object_type_to_class $object_typ]
        lappend contact_tables "[$object_class table_name]"
        append join_clauses " and acs_objects.object_id = [$object_class table_name].[$object_class id_column]"
    }
    lappend contact_tables "acs_objects"

    # Deal with the extra tables
    set extra_clauses ""
    foreach table_info [db_list_of_lists table "select table_name, id_column from acs_object_type_tables where object_type = :object_type and table_name not in ([template::util::tcl_to_sql_list [im_dynfield_multimap_tables]])"] {
	set table_name [lindex $table_info 0]
	set id_column [lindex $table_info 1]
	if {[lsearch $contact_tables $table_name] <0} {
	    # Extra table, join_expression needed
	    append extra_clauses " left outer join $table_name on (acs_objects.object_id = ${table_name}.${id_column})"
	}
     }

    if {$category_id ne ""} {
        switch $object_type {
            person {
                # Find the group_id
                set group_id [im_category_from_id $category_id]
                append join_clauses " and acs_objects.object_id in (select member_id from group_approved_member_map where group_id = $group_id)"
            } 
            default {
                append join_clauses " and [$class table_name].[$class type_column] = :category_id"
            }
        }
    }
    set contact_tables "[join $contact_tables ","] $extra_clauses" 
    ds_comment "test:: $contact_tables"
    return [list $contact_tables $join_clauses]
}
