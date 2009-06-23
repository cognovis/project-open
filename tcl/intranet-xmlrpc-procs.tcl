# /packages/intranet-xmlrpc/tcl/intranet-xmlrpc-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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

ad_proc -public im_xmlrpc_get_user_id {} {
    This is a private autentication routine in order
    to allow for special permissions to use XML-RPC
} {
    set user_id [ad_maybe_redirect_for_registration]

    set ttt {
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {!$user_is_admin_p} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
	return
    }
    }
    return $user_id
}


# ----------------------------------------------------------------------
# sqlapi procedures
# ----------------------------------------------------------------------



ad_proc -public sqlapi.authenticate { authinfo } {
    Takes an "authinfo" array and checks its validity.
    Returns:
    - An empty list if everything is OK
    - An error message (non-empty list) if there's an error
} {
    ns_log Notice "sqlapi.authenticate: authinfo=$authinfo"

    set auth_method [lindex $authinfo 0]
    ns_log Notice "sqlapi.authenticate: auth_method=$auth_method"
    switch $auth_method {
	token {
	    set user_id [lindex $authinfo 1]
	    set timestamp [lindex $authinfo 2]
	    set token [lindex $authinfo 3]
	    set login_p [im_valid_auto_login_p -check_user_requires_manual_login_p 0 -user_id $user_id -auto_login $token]
	    if {!$login_p} { 
		ns_log Notice "sqlapi.authenticate: Bad login info: user_id=$user_id, timestamp=$timestamp, token=$token"
		return [list -string "invalid_auth_token"] 
	    }
	}
	default {
	    ns_log Notice "sqlapi.authenticate: Unkown auth_method=$auth_method"
	    return [list -string "invalid_auth_token"] 
	}
    }
    return []
}    


ad_proc -public sqlapi.object_types { authinfo } {
    Retreives a list of all object types in the system
} {
    ns_log Notice "sqlapi.object_types: authinfo=$authinfo"
    set auth_error [sqlapi.authenticate $authinfo]
    if {[llength $auth_error] > 0} { return $auth_error }
    ns_log Notice "sqlapi.object_types: authentication successful"

    set result [list]
    set query "
	select * 
	from acs_object_types
	order by pretty_name
    "
    db_foreach object_types $query {
	lappend result [list -array [list \
				[list -string $object_type] \
				[list -string $pretty_name] \
        ]]
    }

    # Return {"ok", {<key-value list>}} 
    return [list -array [list \
		      [list -string "ok"] \
		      [list -array $result] \
    ]]
}



ad_proc -public sqlapi.object_fields { authinfo object_type } {
    Retreives a list of all object fields, together with
    their SQL datatype.
} {
    ns_log Notice "sqlapi.object_fields: authinfo=$authinfo"
    set auth_error [sqlapi.authenticate $authinfo]
    if {[llength $auth_error] > 0} { return $auth_error }
    ns_log Notice "sqlapi.object_fields: authentication successful"

    set result [list]
    set query "
	select	lower(column_name) as column_name,
		lower(data_type) as data_type
	from	user_tab_columns
	where	lower(table_name) in (
			select	lower(table_name)
			from	acs_object_type_tables
			where	object_type = :object_type
		     UNION
			select	lower(table_name)
			from	acs_object_types
			where	object_type = :object_type
		)
	order	by column_name
    "
    db_foreach object_fields $query {
	lappend result [list -array [list \
				[list -string $column_name] \
				[list -string $data_type] \
        ]]
    }

    # Return {"ok", {<key-value list>}} 
    return [list -array [list \
		      [list -string "ok"] \
		      [list -array $result] \
    ]]
}



ad_proc -private sqlapi.select_where_clause { constraints } {
    Convert a list of constraints into a where clause.
    In the future we might want to check permissions here,
    currently, everything goes.
} {
    ns_log Notice "sqlapi.select_where_clause: constraints=$constraints"

    set constrs [list]
    foreach c $constraints {
	# Expecting something like {project_name like 'Test%'} in c
	set cc [join $c " "]
	ns_log Notice "sqlapi.select_where_clause: cc=$cc"
	lappend constrs $cc
    }
    set where_clause [join $constrs "\n\tand "]
    ns_log Notice "sqlapi.select_where_clause: where_clause = $where_clause"

    if {[llength $constrs] > 0} { set where_clause "and $where_clause" }

    return $where_clause
}


ad_proc -public sqlapi.select { authinfo object_type constraints } {
    Retreives all information for an object of a given object type
    Returns:
    1. Status ("ok" or anything else indicating an error)
    2. A key-value list with information about the object
} {
    ns_log Notice "sqlapi.select: authinfo=$authinfo, object_type=$object_type"
    set auth_error [sqlapi.authenticate $authinfo]
    if {[llength $auth_error] > 0} { return $auth_error }
    ns_log Notice "sqlapi.select: authentication successful"

    set object_table [db_string object_table "
	select table_name 
	from acs_object_types 
	where object_type = :object_type
    " -default ""]

    set id_column [db_string id_column "
	select id_column 
	from acs_object_types 
	where object_type = :object_type
    " -default ""]

    set where_clause [sqlapi.select_where_clause $constraints]

    set query "
	select $id_column,
		acs_object__name($id_column) as name
	from $object_table 
	where 1=1 $where_clause
    "

    ns_log Notice "sqlapi.select: object_table=$object_table, id_column=$id_column, sql=$query"

    set result [list]
    set err_msg ""
    catch {
	db_foreach select_query $query {
	    lappend result [list -array \
		[list [list -int [expr $$id_column]] \
		[list -string $name]] \
	    ]
	}
    } err_msg
    
    ns_log Notice "sqlapi.select: err_msg=$err_msg"

    if {"" != $err_msg} {
	# Return an error structure
	ns_log Notice "sqlapi.select: Return error structure: err_msg=$err_msg"
	return [list -array [list \
		[list -string "error_sql"] \
		[list -string $err_msg] \
	]]
    } else {
	# Return the key-value list as a "struct"
	ns_log Notice "sqlapi.select: Return result=$result"
	return [list -array [list \
	    [list -string "ok"] \
	    [list -array $result] \
        ]]
    }

}


ad_proc -public sqlapi.object_info { authinfo object_id } {
    Retreives all information for an object of a given object type
    Returns:
    1. Status ("ok" or anything else indicating an error)
    2. A key-value list with information about the object
} {
    ns_log Notice "sqlapi.objectinfo: authinfo=$authinfo, object_id=$object_id"
    set auth_error [sqlapi.authenticate $authinfo]
    if {[llength $auth_error] > 0} { return $auth_error }
    ns_log Notice "sqlapi.select: authentication successful"


    set object_type [db_string object_type "
	select object_type
	from acs_objects
	where object_id = :object_id
    " -default ""]

    set object_table [db_string object_table "
	select table_name 
	from acs_object_types 
	where object_type=:object_type
    " -default ""]

    set id_column [db_string id_column "
	select id_column 
	from acs_object_types 
	where object_type=:object_type
    " -default ""]

    set query "
	select * 
	from $object_table 
	where $id_column = $object_id
    "
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


ad_proc -public sqlapi.login {email timestamp password} {
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


