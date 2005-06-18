# /packages/intranet-dynfield/tcl/attribute-procs.tcl

ad_library {
    
    Procs to help with attributes for object types

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
}


namespace eval attribute { 



ad_proc -public delete_xt { im_dynfield_attribute_id } {
    Intranet-Dynfield extended version of deleting the specified attribute id 
    and all its values. This is irreversible. 
    Returns 1 if the attribute was actually deleted. 0 otherwise.
    <li>1. Drop the column
    <li>2. Drop the attribute
    <li>3. Return

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2005-01-25
} {

    if { ![db_0or1row select_attr_info {
	select
		aa.attribute_name as acs_attribute_name,
		aa.attribute_id as acs_attribute_id,
		t.object_type,
		aa.storage,
		aa.table_name,
		aa.column_name
	from
		acs_attributes aa,
		im_dynfield_attributes fa,
		acs_object_types t
	where
		fa.acs_attribute_id = aa.attribute_id
		and t.object_type = aa.object_type
		and fa.attribute_id = :im_dynfield_attribute_id
    }] } {
        # Attribute doesn't exist
	ad_return_complaint 1 "Error in attribute::delete_xt: 
	attribute #$attribute_id doesn't exist"
	return 0
    }

    if {"" == $column_name} {
	set column_name $acs_attribute_name
    }

#    ad_return_complaint 1 "table_name=$table_name, column_name=$column_name"

    if { [empty_string_p $table_name] || [empty_string_p $column_name] } {
        # We have to have both a non-empty table name and column name
        error "We do not have enough information to automatically remove this\
 attribute. Namely, we are missing either the table name or the column name"
    }

    set plsql [list]
    lappend plsql [list "drop_attribute" "FOO" "db_exec_plsql"]
    if { [db_column_exists $table_name $column_name] } {
        #lappend plsql [list "drop_attr_column" "FOO" "db_dml"]
    }

    foreach pair $plsql {
        eval [lindex $pair 2] [lindex $pair 0] [lindex $pair 1]
    }

    return 1
}



ad_proc -public add_xt {
    { -default "" }
    { -min_n_values "" }
    { -max_n_values "" }
    { -table_name "" }
    { -modify_sql_p "f" }
    { -required_p "f" }
    { -widget_name "" }
    { -attribute_name "" }
    { -sql_datatype "" }
    object_type
    datatype
    pretty_name
    pretty_plural
} {
    A variant of the "add" procedure defined in acs-subsite.
    This version supports adding attributes without generating
    new columns for them and handles widgets, positioning etc.
    
    Wrapper for the <code>acs_attribute.create_attribute</code>
    call. Note that this procedure assumes type-specific storage.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 12/2004

    @return The <code>attribute_id</code> of the newly created attribute
    
} {
    set default_value $default

    set column_name ""
    set sort_order ""
    set storage ""
    set static_p ""

    # We always use type-specific storage. Grab the tablename from 
    # the object_type
    
    if {"" == $table_name} {
	if { ![db_0or1row select_table {
	        select	t.table_name
		from	acs_object_types t
         	where	t.object_type = :object_type
        }] } {
            error "Specified object type \"$object_type\" does not exist"
    	}
    }

    # Generate a default name if not specified    
    if {"" == $attribute_name} {
        # Give the attribute an Oracle/PG friendly name
        set attribute_name [plsql_utility::generate_oracle_name $pretty_name]
    }
    lappend plsql_drop [list "drop_attribute" "FOO" db_exec_plsql]
    lappend plsql [list "create_attribute" "FOO" db_exec_plsql]

    # sql_datatype is used by the .xls files to add a new column to
    # database table
    if {"" == $sql_datatype} {
	set sql_datatype [datatype_to_sql_type -default $default_value $table_name $attribute_name $datatype]
    }
    
    # Only add the column to the table if it doesn't already exist
    if {[string equal $modify_sql_p "t"] && ![db_column_exists $table_name $attribute_name]} {
    	lappend plsql_drop [list "drop_attr_column" "FOO" db_dml]
    	lappend plsql [list "add_column" "FOO" db_dml]
    }
    
    for { set i 0 } { $i < [llength $plsql] } { incr i } {
        set pair [lindex $plsql $i]

	ns_log Notice "attribute::add_xt: pair=$pair"

        if { [catch {eval [lindex $pair 2] [lindex $pair 0] [lindex $pair 1]} err_msg] } {
            # Rollback what we've done so far. The loop contitionals are:
            #  start at the end of the plsql_drop list (Drop things in reverse order of creation)
            # execute drop statements until we reach position $i+1
            #  This position represents the operation on which we failed, and thus
            #  is not executed
            for { set inner [expr [llength $plsql_drop] - 1] } { $inner > [expr $i + 1] } { set inner [expr $inner - 1] } {
                set drop_pair [lindex $plsql_drop $inner]
                if { [catch {eval [lindex $drop_pair 2] [lindex $drop_pair 0] [lindex $drop_pair 1]} err_msg_2] } {
                    append err_msg "\nAdditional error while trying to roll back: $err_msg_2"
                    return -code error $err_msg
                }
            }
            return -code error $err_msg
        }
    }
    
    return [db_string select_attribute_id {
        select a.attribute_id
          from acs_attributes a
         where a.object_type = :object_type
           and a.attribute_name = :attribute_name
    }]

}


}

