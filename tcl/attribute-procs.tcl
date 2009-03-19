# /packages/intranet-dynfield/tcl/attribute-procs.tcl

ad_library {
    
    Procs to help with attributes for object types

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
}


namespace eval attribute { 

ad_proc -public name {
    attribute_id
} {
    this code returns the name of an attribute
} {
    return [db_string get_attribute_name {} -default ""]
}

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

}