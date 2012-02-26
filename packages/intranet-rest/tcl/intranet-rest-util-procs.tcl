# /packages/intranet-rest/tcl/intranet-rest-util-procs.tcl
#
# Copyright (C) 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    REST Web Service Library
    Utility functions
    @author frank.bergmann@project-open.com
}

# --------------------------------------------------------
# Auxillary functions
# --------------------------------------------------------

ad_proc -public im_rest_doc_return {args} {
    This is a replacement for doc_return that values if the
    gzip_p URL parameters has been set.
} {
    # Perform some magic work
    db_release_unused_handles
    ad_http_cache_control

    # find out if we should compress or not
    set query_set [ns_conn form]
    set gzip_p [ns_set get $query_set gzip_p]
    ns_log Notice "im_rest_doc_return: gzip_p=$gzip_p"

    # Return the data
    if {"1" == $gzip_p} {
	return [eval "ns_returnz $args"]
    } else {
	return [eval "ns_return $args"]
    }

}


ad_proc -public im_rest_get_rest_columns {
    query_hash_pairs
} {
    Reads the "columns" URL variable and returns the 
    list of selected REST columns or an empty list 
    if the variable was not specified.
} {
    set rest_columns [list]
    set rest_column_arg ""
    array set query_hash $query_hash_pairs
    if {[info exists query_hash(columns)]} { set rest_column_arg $query_hash(columns) }
    if {"" != $rest_column_arg} {
        # Accept both space (" ") and komma (",") separated columns
	set rest_columns [split $rest_column_arg " "]
	if {[llength $rest_columns] <= 1} {
	    set rest_columns [split $rest_column_arg ","]
	}
    }

    return $rest_columns
}


ad_proc -private im_rest_header_extra_stuff {
    {-debug 1}
} {
    Returns a number of HTML header code in order to make the 
    REST interface create reasonable HTML pages.
} {
    set extra_stuff "
	<link rel='stylesheet' href='/resources/acs-subsite/default-master.css' type='text/css' media='all'>
	<link rel='stylesheet' href='/intranet/style/style.saltnpepper.css' type='text/css' media='screen'>
	<link rel='stylesheet' href='/resources/acs-developer-support/acs-developer-support.css' type='text/css' media='all'> 
	<script type='text/javascript' src='/intranet/js/showhide.js'></script>
	<script type='text/javascript' src='/intranet/js/rounded_corners.inc.js'></script>
	<script type='text/javascript' src='/resources/acs-subsite/core.js'></script>
	<script type='text/javascript' src='/intranet/js/style.saltnpepper.js'></script>
    "
}


ad_proc -private im_rest_cookie_auth_user_id {
    {-debug 1}
} {
    Determine the user_id even if ns_conn doesn't work
    in a HTTP PUT call
} {
    # Get the user_id from the ad_user_login cookie
    set header_vars [ns_conn headers]
    set cookie_string [ns_set get $header_vars Cookie]
    set cookie_list [split $cookie_string ";"]
    # ns_log Notice "im_rest_cookie_auth_user_id: cookie=$cookie_string\n"
    # ns_log Notice "im_rest_cookie_auth_user_id: cookie_list=$cookie_list\n"


    array set cookie_hash {}
    foreach l $cookie_list {
	if {[regexp {([^ =]+)\=(.+)} $l match key value]} {
	    set key [ns_urldecode [string trim $key]]
	    set value [ns_urldecode [string trim $value]]
	    ns_log Notice "im_rest_cookie_auth_user_id: key=$key, value=$value"
	    set cookie_hash($key) $value
	}
    }
    set user_id ""

    if {[info exists cookie_hash(ad_session_id)]} { 

	set ad_session_id $cookie_hash(ad_session_id)
        ns_log Notice "im_rest_cookie_auth_user_id: ad_session_id=$ad_session_id"

	set user_id ""
	catch { set user_id [ad_get_user_id] }

	if {"" != $user_id} {
	    ns_log Notice "im_rest_cookie_auth_user_id: found autenticated user_id: storing into cache"
	    ns_cache set im_rest $ad_session_id $user_id    
	    return $user_id
	}
	
	if {[ns_cache get im_rest $ad_session_id value]} { 
	    ns_log Notice "im_rest_cookie_auth_user_id: Didn't find autenticated user_id: returning cached value"
	    return $value 
	}
    }

    if {[info exists cookie_hash(ad_user_login)]} { 

	set ad_user_login $cookie_hash(ad_user_login)
        ns_log Notice "im_rest_cookie_auth_user_id: ad_user_login=$ad_user_login"

	set user_id ""
	catch { set user_id [ad_get_user_id] }
	if {"" != $user_id} {
	    ns_log Notice "im_rest_cookie_auth_user_id: found autenticated user_id: storing into cache"
	    ns_cache set im_rest $ad_user_login $user_id    
	    return $user_id
	}
	
	if {[ns_cache get im_rest $ad_user_login value]} { 
	    ns_log Notice "im_rest_cookie_auth_user_id: Didn't find autenticated user_id: returning cached value"
	    return $value 
	}
    }
    ns_log Notice "im_rest_cookie_auth_user_id: Didn't find any information, returning {}"
    return ""
}


ad_proc -private im_rest_debug_headers {
    {-debug 1}
} {
    Show REST call headers
} {
    set debug "\n"
    append debug "method: [ns_conn method]\n"
    
    set header_vars [ns_conn headers]
    foreach var [ad_ns_set_keys $header_vars] {
	set value [ns_set get $header_vars $var]
	append debug "header: $var=$value\n"
    }
    
    set form_vars [ns_conn form]
    foreach var [ad_ns_set_keys $form_vars] {
	set value [ns_set get $form_vars $var]
	append debug "form: $var=$value\n"
    }
    
    append debug "content: [ns_conn content]\n"
    
    ns_log Notice "im_rest_debug_headers: $debug"
    return $debug
}



ad_proc -private im_rest_authenticate {
    {-debug 1}
    {-format "xml" }
    -query_hash_pairs:required
} {
    Determine the autenticated user
} {
    array set query_hash $query_hash_pairs
    set header_vars [ns_conn headers]

    # --------------------------------------------------------
    # Check for token authentication
    set token_user_id ""
    set token_token ""
    if {[info exists query_hash(user_id)]} { set token_user_id $query_hash(user_id)}
    if {[info exists query_hash(auth_token)]} { set token_token $query_hash(auth_token)}
    if {[info exists query_hash(auto_login)]} { set token_token $query_hash(auto_login)}

    # Check if the token fits the user
    if {"" != $token_user_id && "" != $token_token} {
	if {![im_valid_auto_login_p -user_id $token_user_id -auto_login $token_token]} {
	    set token_user_id ""
	}
    }

    # --------------------------------------------------------
    # Check for HTTP "basic" authorization
    # Example: Authorization=Basic cHJvam9wOi5mcmFiZXI=
    set basic_auth [ns_set get $header_vars "Authorization"]
    set basic_auth_userpass ""
    set basic_auth_username ""
    set basic_auth_password ""
    if {[regexp {^([a-zA-Z_]+)\ (.*)$} $basic_auth match method userpass_base64]} {
	set basic_auth_userpass [base64::decode $userpass_base64]
	regexp {^([^\:]+)\:(.*)$} $basic_auth_userpass match basic_auth_username basic_auth_password
    }
    set basic_auth_user_id [db_string userid "select user_id from users where lower(username) = lower(:basic_auth_username)" -default ""]
    if {"" == $basic_auth_user_id} {
	set basic_auth_user_id [db_string userid "select party_id from parties where lower(email) = lower(:basic_auth_username)" -default ""]
    }
    set basic_auth_password_ok_p undefined
    if {"" != $basic_auth_user_id} {
	set basic_auth_password_ok_p [ad_check_password $basic_auth_user_id $basic_auth_password]
	if {!$basic_auth_password_ok_p} { set basic_auth_user_id "" }
    }
    if {$debug} { ns_log Notice "im_rest_authenticate: format=$format, basic_auth=$basic_auth, basic_auth_username=$basic_auth_username, basic_auth_password=$basic_auth_password, basic_auth_user_id=$basic_auth_user_id, basic_auth_password_ok_p=$basic_auth_password_ok_p" }


    # --------------------------------------------------------
    # Determine the user_id from cookie.
    # Work around missing ns_conn user_id values in PUT and DELETE calls 
    set cookie_auth_user_id [im_rest_cookie_auth_user_id]

    # Determine authentication method used
    set auth_method ""
    if {"" != $cookie_auth_user_id && 0 != $cookie_auth_user_id } { set auth_method "cookie" }
    if {"" != $token_token} { set auth_method "token" }
    if {"" != $basic_auth_user_id} { set auth_method "basic" }

    # --------------------------------------------------------
    # Check if one of the methods was successful...
    switch $auth_method {
	cookie { set auth_user_id $cookie_auth_user_id }
	token { set auth_user_id $token_user_id }
	basic { set auth_user_id $basic_auth_user_id }
	default { 
	    return [im_rest_error -format $format -http_status 401 -message "No authentication found ('$auth_method')."] 
	}
    }

    if {"" == $auth_user_id} { set auth_user_id 0 }
    ns_log Notice "im_rest_authenticate: format=$format, auth_method=$auth_method, auth_user_id=$auth_user_id"

    return [list user_id $auth_user_id method $auth_method]
}



ad_proc -private im_rest_system_url { } {
    Returns a the system's "official" URL without trailing slash
    suitable to prefix all hrefs used for the XML format.
} {
    return [util_current_location]
}


ad_proc -private im_rest_format_line {
    -format:required
    -rest_otype:required
    -column:required
    -value:required
} {
    Format a single line according to format and return the result.
} {
    set base_url "[im_rest_system_url]/intranet-rest"
    set rest_oid $value
    if {"" == $rest_oid} { set rest_oid 0 }

    # Transformation without knowing the rest_otype
    set href ""
    switch "${rest_otype}.${column}" {
	im_project.company_id - im_timesheet_task.company_id - im_invoice.customer_id - im_timesheet_invoice.customer_id - im_trans_invoice.customer_id - im_invoice.provider_id - im_timesheet_invoice.provider_id - im_trans_invoice.provider_id - im_expense.customer_id - im_office.company_id - im_ticket.company_id {
	    set company_name [util_memoize [list db_string cname1 "select company_name from im_companies where company_id=$rest_oid" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_company/$value?format=html\">$company_name</a>" }
		xml { set href "$base_url/im_company/$value" }
	    }
	}
	im_company.main_office_id - im_invoice.invoice_office_id - im_timesheet_invoice.invoice_office_id - im_trans_invoice.invoice_office_id {
	    set office_name [util_memoize [list db_string cname2 "select office_name from im_offices where office_id=$rest_oid" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_office/$value?format=html\">$office_name</a>" }
		xml { set href "$base_url/im_office/$value" }
	    }
	}
	im_invoice.project_id - im_timesheet_invoice.project_id - im_trans_invoice.project_id - im_project.project_id - im_project.parent_id - im_project.program_id - im_timesheet_task.project_id - im_timesheet_task.parent_id - im_expense.project_id - im_ticket.project_id - im_ticket.parent_id - im_trans_task.project_id - im_invoice_item.project_id {
	    set project_name [util_memoize [list db_string cname3 "select project_name from im_projects where project_id=$rest_oid" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_project/$value?format=html\">$project_name</a>" }
		xml { set href "$base_url/im_project/$value" }
	    }
	}
	im_project.project_lead_id - im_timesheet_task.project_lead_id - im_invoice.company_contact_id - im_timesheet_invoice.company_contact_id - im_trans_invoice.company_contact_id - im_project.company_contact_id - im_cost_center.manager_id - im_cost_center.parent_id - im_conf_item.conf_item_owner_id - im_expense.provider_id - im_ticket.ticket_customer_contact_id - im_user_absence.owner_id - im_project.creation_user - im_timesheet_task.creation_user - im_invoice.creation_user - im_timesheet_invoice.creation_user - im_trans_invoice.creation_user - im_cost_center.creation_user - im_conf_item.creation_user - im_expense.creation_user - im_ticket.creation_user - im_user_absence.creation_user {
	    set user_name [im_name_from_user_id $value]
	    switch $format {
		html { set value "<a href=\"$base_url/user/$value?format=html\">$user_name</a>" }
		xml { set href "$base_url/user/$value" }
	    }
	}
	im_office.office_status_id - im_office.office_type_id - im_company.company_status_id - im_company.company_type_id - im_project.project_status_id - im_project.project_type_id - im_timesheet_task.project_status_id - im_timesheet_task.project_type_id - im_invoice.cost_status_id - im_invoice.cost_type_id - im_timesheet_invoice.cost_status_id - im_timesheet_invoice.cost_type_id - im_trans_invoice.cost_status_id - im_trans_invoice.cost_type_id - im_company.default_invoice_template_id - im_company.default_po_template_id - im_company.annual_revenue_id - im_company.default_delnote_template_id - im_company.default_bill_template_id - im_company.default_payment_method_id - im_invoice.template_id - im_timesheet_invoice.template_id - im_trans_invoice.template_id - im_invoice.payment_method_id - im_timesheet_invoice.payment_method_id - im_trans_invoice.payment_method_id - im_project.on_track_status_id - im_cost_center.cost_center_status_id - im_cost_center.cost_center_type_id - im_biz_object_member.object_role_id - im_conf_item.conf_item_status_id - im_conf_item.conf_item_type_id - im_expense.vat_type_id - im_expense.cost_status_id - im_expense.cost_type_id - im_expense.expense_type_id - im_expense.expense_payment_type_id - im_material.material_type_id - im_material.material_status_id - im_material.material_uom_id - im_release_item.release_status_id - im_rest_object_type.object_type_type_id - im_rest_object_type.object_type_status_id - im_ticket.ticket_status_id - im_ticket.ticket_type_id - im_ticket.project_status_id - im_ticket.project_type_id - im_timesheet_task.uom_id - im_trans_task.task_status_id - im_trans_task.task_type_id - im_trans_task.task_uom_id - im_trans_task.source_language_id - im_trans_task.target_language_id - im_trans_task.tm_integration_type_id - im_user_absence.absence_type_id - im_user_absence.absence_status_id - user.skin_id - im_invoice_item.item_uom_id - im_invoice_item.item_type_id - im_invoice_item.item_status_id {
	    set category_name [im_category_from_id $value]
	    switch $format {
		html { set value "<a href=\"$base_url/im_category/$value?format=html\">$category_name</a>" }
		xml { set href "$base_url/im_category/$value" }
	    }

	}
	im_invoice.cost_center_id - im_timesheet_invoice.cost_center_id - im_trans_invoice.cost_center_id - im_expense.cost_center_id - im_timesheet_task.cost_center_id {
	    if {"" == $value} { set value 0 }
	    set cc_name [util_memoize [list db_string cname4 "select im_cost_center_name_from_id($value)" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_cost_center/$value?format=html\">$cc_name</a>" }
		xml { set href "$base_url/im_cost_center/$value" }
	    }
	}
	im_timesheet_task.material_id {
	    if {"" == $value} { set value 0 }
	    set material_name [util_memoize [list db_string cname5 "select im_material_name_from_id($value)" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_material/$value?format=html\">$material_name</a>" }
		xml { set href "$base_url/im_material/$value" }
	    }
	}
	im_invoice_item.invoice_id - im_timesheet_task.invoice_id {
	    if {"" == $value} { set value 0 }
	    set invoice_name [util_memoize [list db_string cname5 "select cost_name from im_costs where cost_id = $value" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_invoice/$value?format=html\">$invoice_name</a>" }
		xml { set href "$base_url/im_invoice/$value" }
	    }
	}

    }

    switch $format {
	html { return "<tr><td>$column</td><td>$value</td></tr>\n" }
	xml { 
	    if {"" != $href} {
		return "<$column href=\"$href\">$value</$column>\n" 
	    } else {
		return "<$column>$value</$column>\n" 
	    }
	}
    }
}



# ----------------------------------------------------------------------
# Extract all fields from an object type's tables
# ----------------------------------------------------------------------

ad_proc -public im_rest_object_type_pagination_sql { 
    -query_hash_pairs:required
} {
    Appends pagination information to a SQL statement depending on
    URL parameters: "LIMIT $limit OFFSET $start".
} {
    set pagination_sql ""
    array set query_hash $query_hash_pairs

    if {[info exists query_hash(limit)]} { 
	set limit $query_hash(limit) 
	im_security_alert_check_integer -location "im_rest_get_object_type" -value $limit
	append pagination_sql "LIMIT $limit\n"
    }

    if {[info exists query_hash(start)]} { 
	set start $query_hash(start) 
	im_security_alert_check_integer -location "im_rest_get_object_type" -value $start
	append pagination_sql "OFFSET $start\n"
    }

    return $pagination_sql
}

ad_proc -public im_rest_object_type_order_sql { 
    -query_hash_pairs:required
} {
    returns an "ORDER BY" statement for the *_get_object_type SQL.
    URL parameter example: sort=[{"property":"creation_date", "direction":"DESC"}]
} {
    set order_sql ""
    array set query_hash $query_hash_pairs

    set order_by_clauses {}
    if {[info exists query_hash(sort)]} { 
	set sort_json $query_hash(sort)
	array set parsed_json [util::json::parse $sort_json]
	set json_list $parsed_json(_array_)

	foreach sorter $json_list {
	    # Skpe the leading "_object_" key
	    set sorter_list [lindex $sorter 1]
	    array set sorter_hash $sorter_list

	    set property $sorter_hash(property)
	    set direction [string toupper $sorter_hash(direction)]
	    
	    # Perform security checks on the sorters
	    if {![regexp {} $property match]} { 
		ns_log Error "im_rest_object_type_order_sql: Found invalid sort property='$property'"
		continue 
	    }
	    if {[lsearch {DESC ASC} $direction] < 0} { 
		ns_log Error "im_rest_object_type_order_sql: Found invalid sort direction='$direction'"
		continue 
	    }
	    
	    lappend order_by_clauses "$property $direction"
	}
    }

    if {"" != $order_by_clauses} {
	return "order by [join $order_by_clauses ", "]\n"
    } else {
	# No order by clause specified
	return ""
    }
}


ad_proc -public im_rest_object_type_select_sql { 
    {-no_where_clause_p 0}
    -rest_otype:required
} {
    Calculates the SQL statement to extract the value for an object
    of the given rest_otype. The SQL will contains a ":rest_oid"
    colon-variables, so the variable "rest_oid" must be defined in 
    the context where this statement is to be executed.
} {
    # get the list of super-types for rest_otype, including rest_otype
    # and remove "acs_object" from the list
    set super_types [im_object_super_types -object_type $rest_otype]
    set s [list]
    foreach t $super_types {
	if {$t == "acs_object"} { continue }
	lappend s $t
    }
    set super_types $s

    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all information about one object
    # Start with the core object tables, so that all important fields
    # are available in the query, even if there are duplicates.
    #
    set letters {a b c d e f g h i j k l m n o p q r s t u v w x y z}
    set from {}
    set froms {}
    set selects { "1 as one" }
    set selected_columns {}
    set selected_tables {}

    set tables_sql "
	select	*
	from	(
		select	table_name,
			id_column,
			1 as sort_order
		from	acs_object_types
		where	object_type in ('[join $super_types "', '"]')
		UNION
		select	table_name,
			id_column,
			2 as sort_order
		from	acs_object_type_tables
		where	object_type in ('[join $super_types "', '"]')
		) t
	order by t.sort_order
    "

    set columns_sql "
	select	lower(column_name) as column_name
	from	user_tab_columns
	where	lower(table_name) = lower(:table_name)
    "

    set cnt 0
    db_foreach tables $tables_sql {

	if {[lsearch $selected_tables $table_name] >= 0} { 
	    ns_log Notice "im_rest_object_type_select_sql: found duplicate table: $table_name"
	    continue 
	}

	set letter [lindex $letters $cnt]
	lappend froms "LEFT OUTER JOIN $table_name $letter ON (o.object_id = $letter.$id_column)"

	db_foreach columns $columns_sql {
	    if {[lsearch $selected_columns $column_name] >= 0} { 
		ns_log Notice "im_rest_object_type_select_sql: found ambiguous field: $table_name.$column_name"
		continue 
	    }
	    lappend selects "$letter.$column_name"
	    lappend selected_columns $column_name
	}

	lappend selected_tables $table_name
	incr cnt
    }

    set sql "
	select	o.*,
		o.object_id as rest_oid,
		acs_object__name(o.object_id) as object_name,
		[join $selects ",\n\t\t"]
	from	acs_objects o
		[join $froms "\n\t\t"]
    "
    if {!$no_where_clause_p} { append sql "
	where	o.object_id = :rest_oid
    "}

    return $sql
}


ad_proc -public im_rest_object_type_columns { 
    -rest_otype:required
} {
    Returns a list of all columns for a given object type.
} {
    set super_types [im_object_super_types -object_type $rest_otype]

    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all tables for an object type,
    # plus all table columns via user_tab_colums.
    set columns_sql "
	select distinct
		lower(utc.column_name)
	from
		user_tab_columns utc
	where
		-- check the main tables for all object types
		lower(utc.table_name) in (
			select	lower(table_name)
			from	acs_object_types
			where	object_type in ('[join $super_types "', '"]')
		) OR
		-- check the extension tables for all object types
		lower(utc.table_name) in (
			select	lower(table_name)
			from	acs_object_type_tables
			where	object_type in ('[join $super_types "', '"]')
		)
    "

    return [db_list columns $columns_sql]
}

ad_proc -public im_rest_object_type_index_columns { 
    -rest_otype:required
} {
    Returns a list of all "index columns" for a given object type.
    The index columns are the primary key columns of the object
    types's tables. They will all contains the same object_id of
    the object.
} {
    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all tables for an object type,
    # plus all table columns via user_tab_colums.
    set index_columns_sql "
	select	id_column
	from	acs_object_type_tables
	where	object_type = :rest_otype
    UNION
	select	id_column
	from	acs_object_types
	where	object_type = :rest_otype
    UNION
	select	'rest_oid'
    "

    return [db_list index_columns $index_columns_sql]
}


# ----------------------------------------------------------------------
# Update all tables of an object type.
# ----------------------------------------------------------------------

ad_proc -public im_rest_object_type_update_sql { 
    { -format "xml" }
    -rest_otype:required
    -rest_oid:required
    -hash_array:required
} {
    Updates all the object's tables with the information from the
    hash array.
} {
    ns_log Notice "im_rest_object_type_update_sql: format=$format, rest_otype=$rest_otype, rest_oid=$rest_oid, hash_array=[array get hash_array]"

    # Stuff the list of variables into a hash
    array set hash $hash_array

    # ---------------------------------------------------------------
    # Get all relevant tables for the object type
    set tables_sql "
			select	table_name,
				id_column
			from	acs_object_types
			where	object_type = :rest_otype
		    UNION
			select	table_name,
				id_column
			from	acs_object_type_tables
			where	object_type = :rest_otype
    "
    db_foreach tables $tables_sql {
	set index_column($table_name) $id_column
	set index_column($id_column) $id_column
    }

    set columns_sql "
	select	lower(utc.column_name) as column_name,
		lower(utc.table_name) as table_name
	from
		user_tab_columns utc,
		($tables_sql) tables
	where
		lower(utc.table_name) = lower(tables.table_name)
	order by
		lower(utc.table_name),
		lower(utc.column_name)
    "

    array unset sql_hash
    db_foreach cols $columns_sql {

	# Skip variables that are not available in the var hash
	if {![info exists hash($column_name)]} { continue }

	# Skip index columns
	if {[info exists index_column($column_name)]} { continue }

	# skip tree_sortkey stuff
	if {"tree_sortkey" == $column_name} { continue }
	if {"max_child_sortkey" == $column_name} { continue }

	# ignore reserved variables
	if {"rest_otype" == $column_name} { contiue }
	if {"rest_oid" == $column_name} { contiue }
	if {"hash_array" == $column_name} { contiue }

	# ignore any "*_cache" variables (financial cache)
	if {[regexp {_cache$} $column_name match]} { continue }

	# Start putting together the SQL
	set sqls [list]
	if {[info exists sql_hash($table_name)]} { set sqls $sql_hash($table_name) }
	lappend sqls "$column_name = :$column_name"
	set sql_hash($table_name) $sqls
    }

    # Add the rest_oid to the hash
    set hash(rest_oid) $rest_oid

    ns_log Notice "im_rest_object_type_update_sql: [array get sql_hash]"

    foreach table [array names sql_hash] {
	ns_log Notice "im_rest_object_type_update_sql: Going to update table '$table'"
	set sqls $sql_hash($table)
	set update_sql "update $table set [join $sqls ", "] where $index_column($table) = :rest_oid"

	if {[catch {
	    db_dml sql_$table $update_sql -bind [array get hash]
	} err_msg]} {
	    return [im_rest_error -format $format -http_status 404 -message "Error updating $rest_otype: '$err_msg'"]
	}
    }

    ns_log Notice "im_rest_object_type_update_sql: returning"
    return
}



# ----------------------------------------------------------------------
# SQL Validator
# ----------------------------------------------------------------------

ad_proc -public im_rest_valid_sql {
    -string:required
    {-variables {} }
    {-debug 1}
} {
    Returns 1 if "where_clause" is a valid where_clause or 0 otherwise.
    The validator is based on applying a number of rules using a rule engine.
    Return the validation result if debug=1.
} {
    ns_log Notice "im_rest_valid_sql: sql=$string, vars=$variables"

    # An empty string is a valid SQL...
    if {"" == $string} { return 1 }

    # ------------------------------------------------------
    # Massage the string so that it suits the rule engine.

    # Reduce all characters to lower case
    set string [string tolower $string]

    # Add spaces around the string
    set string " $string "

    # Replace ocurrences of double (escaped) single-ticks with "quote"
    regsub -all {''} $string { quote } string

    # Add an extra space between all "comparison" strings in the where clause
    regsub -all {([\>\<\=\!]+)} $string { \1 } string

    # Add an extra space around parentesis
    regsub -all {([\(\)])} $string { \1 } string

    # Add an extra space around kommas
    regsub -all {(,)} $string { \1 } string

    # Replace multiple spaces by a single one
    regsub -all {\s+} $string { } string


    # ------------------------------------------------------
    # Rules have a format LHS <- RHS (Left Hand Side <- Right Hand Side)
    set rules {
	query {select [[:alnum:]_]+}
	query {from [[:alnum:]_]+}
	query {where [[:alnum:]_]+ in \( query \)}
	query {where cond}
	query {query query}
	query {query where val}
	query {query val}
	query {query \( val \)}
	cond {cond and cond}
	cond {cond and val}
	cond {cond val}
	cond {cond or cond}
	cond {\( cond \)}
	cond {val = val}
	cond {val like val}
	cond {[[:alnum:]_]+ like val}
	cond {val > val}
	cond {val >= val}
	cond {val < val}
	cond {val <= val}
	cond {val <> val}
	cond {val != val}
	cond {val is null}
	cond {[[:alnum:]_]+ @@ val}
	cond {val is not null}
	cond {val in \( val \)}
	cond {val in \( query \)}
	val  {val , val}
	val  {val val}
	val  {[0-9]+}
	val  {[[:alnum:]_]+\.[[:alnum:]_]+}
	val  {[0-9]+\-[0-9]+\-[0-9]+t[0-9]+\:[0-9]+\:[0-9]+}
	val  {\'[[:alnum:]_\ \-\%\@\.]*\'}
	val  {[[:alnum:]_]+ \( [[:alnum:]_]+ \)}
    }

    # Add rules for every variable saying that it's a var.
    lappend variables member_id user_id group_id object_id_one object_id_two
    foreach var $variables {
	lappend rules val
	lappend rules $var
    }

    # Applies a number of rules to a string, eventually rewriting
    # the string into a single toplevel term.
    # String is expected to have spaces around any payload, and 
    # also each of its tokens surrounded by spaces
    set fired 1
    set debug_result ""
    while {$fired} {
	set fired 0
	foreach {lhs rhs} $rules {
	    set org_string $string
	    incr fired [regsub -all " $rhs " $string " $lhs " string]
	    if {$string != $org_string} {
		append debug_result "$lhs -> $rhs: '$string'\n"
		ns_log Notice "im_rest_valid_sql: $lhs -> $rhs: '$string'\n"
	    }
	}
    }

    set string [string trim $string]
    set result 0
    if {"" == $string || "cond" == $string || "query" == $string || "val" == $string} { set result 1 }

    # Show the application of rules for debugging
    if {$debug} { 
	append debug_result "result=$result\n"
	ns_log Notice "im_rest_valid_sql: result=$result"
	# return $debug_result 
    }

    return $result
}


# ----------------------------------------------------------------------
# Error Handling
# ----------------------------------------------------------------------

ad_proc -public im_rest_error {
    { -http_status 404 }
    { -format "xml" }
    { -message "" }
} {
    Returns a suitable REST error message
} {
    ns_log Notice "im_rest_error: http_status=$http_status, format=$format, message=$message"
    set url [im_url_with_query]

    switch $http_status {
	200 { set status_message "OK: Success!" }
	304 { set status_message "Not Modified: There was no new data to return." }
	400 { set status_message "Bad Request: The request was invalid. An accompanying error message will explain why." }
	401 { set status_message "Not Authorized: Authentication credentials were missing or incorrect." }
	403 { set status_message "Forbidden: The request is understood, but it has been refused.  An accompanying error message will explain why." }
	404 { set status_message "Not Found: The URI requested is invalid or the resource requested, for example a non-existing project." }
	406 { set status_message "Not Acceptable: Returned when an invalid format is specified in the request." }
	500 { set status_message "Internal Server Error: Something is broken.  Please post to the &\#93;project-open&\#91; Open Discussions forum." }
	502 { set status_message "Bad Gateway: project-open is probably down." }
	503 { set status_message "Service Unavailable: project-open is up, but overloaded with requests. Try again later." }
	default { set status_message "Unknown http_status '$http_status'." }
    }

    set page_title [lindex [split $status_message ":"] 0]

    switch $format {
	html { 
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle><td>$status_message</td></tr>
		</table>[im_footer]
	    " 
	}
	xml {  
    doc_return $http_status "text/xml" "<?xml version='1.0' encoding='UTF-8'?>
<error>
<http_status>$http_status</http_status>
<http_status_message>$status_message</http_status_message>
<request>[ns_quotehtml $url]</request>
<message>$message</message>
</error>"
	}
	json {  
	    # Calculate the total number of objects
	    set result "{\"success\": false,\n\"message\": \"[im_quotejson $message]\"\n}"
	    doc_return 200 "text/html" $result
	}
	default {
	     ad_return_complaint 1 "Invalid format1: '$format'"
	}
    }

    ad_script_abort
}


ad_proc -public im_rest_get_content {} {
    There's no [ns_conn content] so this is a hack to get the content of the
    REST request. Taken from ns_xmlrpc.
    @return string - the XML request
    @author Dave Bauer
} {
    # (taken from aol30/modules/tcl/form.tcl)
    # Spool content into a temporary read/write file.
    # ns_openexcl can fail, since tmpnam is known not to
    # be thread/process safe.  Hence spin till success
    set fp ""
    while {$fp == ""} {
        set filename "[ns_tmpnam][clock clicks -milliseconds].xmlrpc2"
        set fp [ns_openexcl $filename]
    }

    fconfigure $fp -translation binary
    ns_conncptofp $fp
    close $fp

    set fp [open $filename r]
    while {![eof $fp]} {
        append text [read $fp]
    }
    close $fp
    ns_unlink $filename
    return $text
}

ad_proc -public im_rest_parse_xml_json_content {
    { -format "" }
    { -content "" }
    { -rest_otype "" }
} {
    Parse the XML or JSON content of a POST request with 
    the values of the object to create or update.
    @author Frank Bergmann
} {
    # Parse the HTTP content
    switch $format {
	json {
	    ns_log Notice "im_rest_parse_xml_json_content: going to parse json content=$content"
	    # {"id":8799,"email":"bbigboss@tigerpond.com","first_names":"Ben","last_name":"Bigboss"}
	    array set parsed_json [util::json::parse $content]
	    set json_list $parsed_json(_object_)
	    array set hash_array $json_list

	    # ToDo: Modify the JSON Parser to return NULL values as "" (TCL NULL) instead of "null"
	    foreach var [array names hash_array] {
		set val $hash_array($var)
		if {"null" == $val} { set hash_array($var) "" }
	    }
	}
	xml {
	    # store the key-value pairs into a hash array
	    ns_log Notice "im_rest_parse_xml_json_content: going to parse xml content=$content"
	    if {[catch {set doc [dom parse $content]} err_msg]} {
		return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
	    }
	    
	    set root_node [$doc documentElement]
	    array unset hash_array
	    foreach child [$root_node childNodes] {
		set nodeName [$child nodeName]
		set nodeText [$child text]
		set hash_array($nodeName) $nodeText
	    }
	}
	default {
	    return [im_rest_error -http_status 406 -message "Unknown format: '$format'. Expected: {xml|json}"]
	}
    }
    return [array get hash_array]
}






ad_proc -public im_quotejson { str } {
    Quote a JSON string. In particular this means escaping
    single and double quotes, as well as new lines, tabs etc.
    @author Frank Bergmann
} {
    regsub -all {\\} $str {\\\\} str
    regsub -all {'} $str {\'} str
    regsub -all {"} $str {\"} str
    regsub -all {\n} $str {\\n} str
    regsub -all {\t} $str {\\t} str
    return $str
}

