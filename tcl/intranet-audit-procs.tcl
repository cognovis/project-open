# /packages/intranet-audit/tcl/intranet-audit-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------


# ----------------------------------------------------------------------
# Audit Package
# ----------------------------------------------------------------------

ad_proc -public im_audit_object_type_sql { 
    -object_type:required
} {
    Calculates the SQL statement to extract the value for an object
    of the given object_type. The SQL will contains a ":object_id"
    colon-variables, so the variable "object_id" must be defined in 
    the context where this statement is to be executed.
} {
    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all information about one object
    set tables_sql "
	select	table_name,
		id_column
	from	acs_object_types
	where	object_type = :object_type
UNION
	select	table_name,
		id_column
	from	acs_object_type_tables
	where	object_type = :object_type
    "

    set letters {a b c d e f g h i j k l m n o p q r s t u v w x y z}
    set from {}
    set wheres { "1=1" }
    set cnt 0
    db_foreach tables $tables_sql {
	set letter [lindex $letters $cnt]
	lappend froms "$table_name $letter"
	lappend wheres "$letter.$id_column = :object_id"
	incr cnt
    }

    set sql "
	select	*
	from	[join $froms ", "]
	where	[join $wheres " and "]
    "
    return $sql
}



ad_proc -public im_audit_object_value { 
    -object_id:required
    { -object_type "" }
} {
    Concatenates the value of all object fields (according to DynFields)
    to form a single string describing the object's values.
} {
    im_security_alert_check_integer -location "im_audit_object_value" -value $object_id
    if {"" == $object_type} {
	set object_type [util_memoize [list db_string otype "select object_type from acs_objects where object_id = $object_id" -default ""]]
    }

    # Get the SQL to extract all values from the object
    set sql [util_memoize [list im_audit_object_type_sql -object_type $object_type]]

    # Execute the sql. As a result we get "col_names" with list of columns and "lol" with the result list of lists
    db_with_handle db {
	set selection [db_exec select $db query $sql 1]
	set lol [list]
	while { [db_getrow $db $selection] } {
	    set col_names [ad_ns_set_keys $selection]
	    set this_result [list]
	    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		lappend this_result [ns_set value $selection $i]
	    }
	    lappend lol $this_result
	}
    }
    db_release_unused_handles

    # lol should have only a single line!
    set col_values [lindex $lol 0]

    set value ""
    for {set i 0} {$i < [llength $col_names]} {incr i} {
	set var [lindex $col_names $i]
	set val [lindex $col_values $i]

	# Skip a number of known internal variables
	if {"tree_sortkey" == $var} { continue }
	if {"max_child_sortkey" == $var} { continue }

	# Add the line to the "value"
	append value "$var	$val\n"
    }

    return $value
}



ad_proc -public im_audit_calculate_diff { 
    -old_value:required
    -new_value:required
} {
    Calculates the difference between and old an a new value and
    returns only the lines that have changed.
    Each line consists of: variable \t value \n.
} {
    foreach old_line [split $old_value "\n"] {
	set pieces [split $old_line "\t"]
	set var [lindex $pieces 0]
	set val [lindex $pieces 1]
	set hash($var) $val
    }

    set diff ""
    foreach new_line [split $new_value "\n"] {
	set pieces [split $new_line "\t"]
	set var [lindex $pieces 0]
	set val [lindex $pieces 1]
	set old_val ""
	if {[info exists hash($var)]} { set old_val $hash($var) }
	if {$val != $old_val} { append diff "$new_line\n" }
    }

    return $diff   
}


ad_proc -public im_audit { 
    -object_id:required
    {-user_id 0}
    {-peeraddr "" }
} {
    Creates a new audit item for object after an update.
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }
    if {"" == $peeraddr} { set peeraddr [ns_conn peeraddr] }

    # Are we behind a firewall or behind a reverse proxy?
    if {"127.0.0.1" == $peeraddr} {

	# Get the IP of the browser of the user
	set header_vars [ns_conn headers]
	set x_forwarded_for [ns_set get $header_vars "X-Forwarded-For"]
	if {"" != $x_forwarded_for} {
	    set peeraddr $x_forwarded_for
	}
    }

    # Get information about the audit object
    set object_type ""
    set old_value ""
    set last_audit_id ""
    db_0or1row last_info "
	select	a.audit_value as old_value,
		o.object_type,
		o.last_audit_id
	from	im_audit a,
		acs_objects o
	where	o.object_id = :object_id and
		o.last_audit_id = a.audit_id
    "

    # Get the new value from the database
    set new_value [im_audit_object_value -object_id $object_id -object_type $object_type]

    # Calculate the "diff" between old and new value.
    # Return "" if nothing has changed:
    set diff [im_audit_calculate_diff -old_value $old_value -new_value $new_value]

#    return "<pre>$old_value\n\n$new_value\</pre>"

    if {"" != $diff} {

	# Something has changed...
	# Create a new im_audit entry and associate it to the object.
	set new_audit_id [db_nextval im_audit_seq]
	set audit_ref_object_id ""
	set audit_note ""
	set audit_hash ""
	db_dml insert_audit "
		insert into im_audit(
			audit_id,
			audit_object_id,
			audit_user_id,
			audit_date,
			audit_ip,
			audit_last_id,
			audit_ref_object_id,
			audit_value,
			audit_diff,
			audit_note,
			audit_hash
		) values (
			:new_audit_id,
			:object_id,
			:user_id,
			now(),
			:peeraddr,
			:last_audit_id,
			:audit_ref_object_id,
			:new_value,
			:diff,
			:audit_note,
			:audit_hash
		)
	"

	db_dml update_object "
		update acs_objects set
			last_audit_id = :new_audit_id
		where object_id = :object_id
	"

    }

    return $diff
}









namespace eval im_audit {

}

