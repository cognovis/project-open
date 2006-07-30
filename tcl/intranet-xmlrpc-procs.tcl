# /packages/intranet-xmlrpc/tcl/intranet-xmlrpc-procs.tcl
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Provides a XML-RPC interface to the ]project-open[
    data model. The API works by wrapping generic SQL
    statements into XML-RPC

    @author frank.bergmann@project-open.com
    @creation-date 2006-07-01
    @cvs-id $Id: syst
}

# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_xmlrpc_id {} {
    Returns the package id of the intranet-forum module
} {
    return [util_memoize "im_package_xmlrpc_id_helper"]
}

ad_proc -private im_package_xmlrpc_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-xmlrpc'
    } -default 0]
}


# ----------------------------------------------------------------------
# sqlapi procedures
# ----------------------------------------------------------------------


ad_proc -public sqlapi.select { authinfo object_type } {
    Retreives all information for an object of a given object type
    Returns:
    1. Status ("ok" or anything else indicating an error)
    2. A key-value list with information about the object
} {
    ns_log Notice "sqlapi.select: user_id=$user_id, timestamp=$timestamp, token=$token, object_type=$object_type, object_id=$object_id"

    set login_p [im_valid_auto_login_p -user_id $user_id -auto_login $token]
    if {!$login_p} { 
	ns_log Notice "sqlapi.select: Bad login info: user_id=$user_id, timestamp=$timestamp, token=$token"
	return [list -string "invalid_auth_token"] 
    }

    set object_table [db_string object_table "select table_name from acs_object_types where object_type=:object_type" -default ""]
    set id_column [db_string id_column "select id_column from acs_object_types where object_type=:object_type" -default ""]

    set query "select * from $object_table where $id_column = $object_id"
    ns_log Notice "sqlapi.select: object_table=$object_table, id_column=$id_column, sql=$query"

    db_with_handle db {
	set selection [ns_db select $db $query]
	if {[ns_db getrow $db $selection]} {

	    set result [list]
	    for {set i 0} {$i < [ns_set size $selection]} {incr i} {
		set column [ns_set key $selection $i]
		set value [ns_set value $selection $i]
		ns_log Notice "sqlapi.select: i=$i, column=$column, value=$value"
		
		lappend result $column
		lappend result [list -string $value]
	    }

	    # Skip any possibly remaining records
	    ns_db flush $db
	    
	    # Return the key-value list as a "struct"
            return [list -array [list \
		[list -string "ok"] \
		[list -struct $result] \
	    ]]

	} else {

	    return [list -string no_records_found]

	}
    }
}


ad_proc -public sqlapi.get_object { user_id timestamp token object_type object_id } {
    Retreives all information for an object of a given object type
    Returns:
    1. Status ("ok" or anything else indicating an error)
    2. A key-value list with information about the object
} {
    ns_log Notice "sqlapi.select: user_id=$user_id, timestamp=$timestamp, token=$token, object_type=$object_type, object_id=$object_id"

    set login_p [im_valid_auto_login_p -user_id $user_id -auto_login $token]
    if {!$login_p} { 
	ns_log Notice "sqlapi.select: Bad login info: user_id=$user_id, timestamp=$timestamp, token=$token"
	return [list -string "invalid_auth_token"] 
    }

    set object_table [db_string object_table "select table_name from acs_object_types where object_type=:object_type" -default ""]
    set id_column [db_string id_column "select id_column from acs_object_types where object_type=:object_type" -default ""]

    set query "select * from $object_table where $id_column = $object_id"
    ns_log Notice "sqlapi.select: object_table=$object_table, id_column=$id_column, sql=$query"

    db_with_handle db {
	set selection [ns_db select $db $query]
	if {[ns_db getrow $db $selection]} {

	    set result [list]
	    for {set i 0} {$i < [ns_set size $selection]} {incr i} {
		set column [ns_set key $selection $i]
		set value [ns_set value $selection $i]
		ns_log Notice "sqlapi.select: i=$i, column=$column, value=$value"
		
		lappend result $column
		lappend result [list -string $value]
	    }

	    # Skip any possibly remaining records
	    ns_db flush $db
	    
	    # Return the key-value list as a "struct"
            return [list -array [list \
		[list -string "ok"] \
		[list -struct $result] \
	    ]]

	} else {

	    return [list -string no_records_found]

	}
    }
}


ad_proc -public sqlapi.login {email password} {
    Returns an authentication token of the user provides
    us with a valid email/password

    @return A list composed of:
    	1. a status,
	2. a user_id,
	3. a timestamp in format "YYYY-MM-DD HH:MM:SS"
	   or "" to indicate a perpetual lease
	4. a token
    or
	an error message. Status can be "ok", or anything
        else such as "bad_password" etc.

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    # Authority - Who is responsible to log the dude in?
    set authority_options [auth::authority::get_authority_options]
    set authority_id [lindex [lindex $authority_options 0] 1]

    # Check username and password
    array set auth_info [auth::authenticate \
                             -return_url "" \
                             -authority_id $authority_id \
                             -email [string trim $email] \
                             -password $password \
    ]

    ns_log Notice "sqlapi.login: [array get auth_info]"

    # Handle authentication problems
    switch $auth_info(auth_status) {
        ok {
	    set user_id $auth_info(user_id)
	    set sec_token [im_generate_auto_login -user_id $user_id]
	    return [list -array [list \
		[list -string $auth_info(auth_status)] \
		[list -string $user_id] \
		[list -string ""] \
		[list -string $sec_token] \
	    ]]
        }
        default {
	    return [list -array [list \
		[list -string $auth_info(auth_status)] \
		[list -string $auth_info(auth_message)] \
	    ]]
        }
    }
}


