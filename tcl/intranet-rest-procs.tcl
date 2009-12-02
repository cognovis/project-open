# /packages/intranet-rest/tcl/intranet-rest-procs.tcl
#
# Copyright (C) 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    REST Web Service Component Library
    @author frank.bergmann@project-open.com
}

# Register handler procedures for the various HTTP methods
#
ad_register_proc GET /intranet-rest/* im_rest_call_get
ad_register_proc POST /intranet-rest/* im_rest_call_post


# -------------------------------------------------------
# HTTP Interface
#
# Deal HTTP parameters, authentication etc.
# -------------------------------------------------------

ad_proc -private im_rest_call_get {} {
    Handler for GET rest calls
} {
    # Get the entire URL and decompose into the "object_type" 
    # and the "object_id" pieces. Splitting the URL on "/"
    # will result in "{} intranet-rest object_type object_id":
    set url [ns_conn url]
    set url_pieces [split $url "/"]
    set object_type [lindex $url_pieces 2]
    set object_id [lindex $url_pieces 3]

    # Get the information about the URL parameters, parse
    # them and store them into a hash array.
    set query [ns_conn query]
    set query_pieces [split $query "&"]
    array set query_hash {}
    foreach query_piece $query_pieces {
	if {[regexp {^([^=]+)=(.+)$} $query_piece match var val]} {
	    set var [ns_urldecode $var]
	    set val [ns_urldecode $val]
	    set query_hash($var) $val
	}
    }
    
    # Determine the authenticated user_id. 0 means not authenticated.
    array set auth_hash [im_rest_authenticate -query_hash_values [array get query_hash]]
    set auth_user_id $auth_hash(user_id)
    set auth_method $auth_hash(method)
    if {0 == $auth_user_id} { return [im_rest_error -http_status 401 -message "Not authenticated"] }

    # Default format are:
    # - "html" for cookie authentication
    # - "xml" for basic authentication
    # - "xml" for auth_token authentication
    switch $auth_method {
	basic { set format "xml" }
	cookie { set format "html" }
	token { set format "xml" }
	default { return [im_rest_error -http_status 401 -message "Invalid authentication method '$auth_method'."] }
    }
    # Overwrite default format with explicitely specified format in URL
    if {[info exists query_hash(format)]} { set format $query_hash(format) }
    set valid_formats {xml html}
    if {[lsearch $valid_formats $format] < 0} { return [im_rest_error -http_status 406 -message "Invalid output format '$format'. Valid formats include {xml|html}."] }

    # Call the main request processing routine
    im_rest_call \
	-method GET \
	-format $format \
	-user_id $auth_user_id \
	-object_type $object_type \
	-object_id $object_id \
	-query_hash [array get query_hash]
    
}

ad_proc -private im_rest_call_post {} {
    Handler for GET rest calls
} {
    return "<?xml version='1.0'?>\n"
}



# -------------------------------------------------------
# REST Call Drivers
# -------------------------------------------------------


ad_proc -private im_rest_call {
    { -method GET }
    { -format "xml" }
    { -user_id 0 }
    { -object_type "" }
    { -object_id 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for all REST calls
} {
    ns_log Notice "im_rest_call: method=$method, format=$format, user_id=$user_id, object_type=$object_type, object_id=$object_id, query_hash=$query_hash"

    # -------------------------------------------------------
    # Special treatment for /intranet-rest/ and /intranet/rest/index URLs
    if {"" == $object_type} { set object_type "index" }
    set pages {"" index auto-login}
    if {[lsearch $pages $object_type] >= 0} {
	return [im_rest_page \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -object_id $object_id \
		    -query_hash $query_hash \
		   ]
    }

    # -------------------------------------------------------
    # Check the "object_type" to be a valid object type
    set valid_object_types [util_memoize [list db_list otypes "select object_type from acs_object_types union select 'im_category'"]]
    if {[lsearch $valid_object_types $object_type] < 0} { return [im_rest_error -http_status 406 -message "Invalid object_type '$object_type'. Valid object types include {im_project|im_company|...}."] }

    # -------------------------------------------------------
    # Special treatment for "im_category", because it's not an object type.
    if {"im_category" == $object_type} {
	return [im_rest_get_im_category \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -object_id $object_id \
		    -query_hash $query_hash \
		   ]
    }

    switch $method  {
	GET {
	    # Is there a valid object_id?
	    if {"" != $object_id && 0 != $object_id} {
		# Return everything we know about the object
		return [im_rest_get_object \
			    -format $format \
			    -user_id $user_id \
			    -object_type $object_type \
			    -object_id $object_id \
			    -query_hash $query_hash \
			    ]
	    } else {
		# Return query from the object object_type
		return [im_rest_get_object_type \
			    -format $format \
			    -user_id $user_id \
			    -object_type $object_type \
			    -query_hash $query_hash \
			    ]
	    }
	}

	POST {
	    # Is there a valid object_id?
	    if {"" != $object_id && 0 != $object_id} {
		# Return everything we know about the object
		return [im_rest_post_object \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -object_id $object_id \
		    -query_hash $query_hash \
			    ]
	    } else {
		# Return query from the object object_type
		return [im_rest_post_object_type \
			    -format $format \
			    -user_id $user_id \
			    -object_type $object_type \
			    -query_hash $query_hash \
			    ]
	    }
	}

	default {
	    return [im_rest_error -http_status 400 -message "Unknown HTTP request '$method'. Valid requests include {GET|POST}."]
	}
    }
}


ad_proc -private im_rest_page {
    { -object_type "index" }
    { -format "xml" }
    { -user_id 0 }
    { -object_id 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    The user has requested /intranet-rest/ or /intranet-rest/index
} {
    ns_log Notice "im_rest_index_page: object_type=$object_type, query_hash=$query_hash"

    set params [list \
                    [list object_type $object_type] \
                    [list format $format] \
                    [list user_id $user_id] \
                    [list object_id $object_id] \
                    [list query_hash $query_hash] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-rest/www/$object_type"]
    doc_return 200 "text/html" $result
}

ad_proc -private im_rest_get_object {
    { -format "xml" }
    { -user_id 0 }
    { -object_type "" }
    { -object_id 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_object: format=$format, user_id=$user_id, object_type=$object_type, object_id=$object_id, query_hash=$query_hash"

    # Check that object_id is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $object_id

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql [util_memoize [list im_audit_object_type_sql -object_type $object_type]]
    #set sql [im_audit_object_type_sql -object_type $object_type]

    # Execute the sql. As a result we get a result_hash with keys corresponding
    # to table columns and values 
    array set result_hash {}
    db_with_handle db {
        set selection [db_exec select $db query $sql 1]
        while { [db_getrow $db $selection] } {
            set col_names [ad_ns_set_keys $selection]
            set this_result [list]
            for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		set var [lindex $col_names $i]
		set val [ns_set value $selection $i]
		set result_hash($var) $val
            }
        }
    }
    db_release_unused_handles

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Did not find object '$object_type' with the ID '$object_id'."] }

    # -------------------------------------------------------
    # Format the result for one of the supported formats
    set result ""
    foreach result_key [array names result_hash] {
	set result_val $result_hash($result_key)
	append result [im_rest_format_line \
			   -column $result_key \
			   -value $result_val \
			   -format $format \
			   -object_type $object_type \
	]
    }
	
    switch $format {
	html { doc_return 200 "text/html" "<html><body><table>\n$result</table></body></html>" }
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?><$object_type>$result</$object_type>" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}


ad_proc -private im_rest_get_im_category {
    { -format "xml" }
    { -user_id 0 }
    { -object_type "" }
    { -object_id 0 }
    { -query_hash {} }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_im_category: format=$format, user_id=$user_id, object_type=$object_type, object_id=$object_id, query_hash=$query_hash"

    # Check that object_id is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $object_id

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql "select * from im_categories where category_id = :object_id"

    # Execute the sql. As a result we get a result_hash with keys 
    # corresponding to table columns and values 
    array set result_hash {}
    db_with_handle db {
        set selection [db_exec select $db query $sql 1]
        while { [db_getrow $db $selection] } {
            set col_names [ad_ns_set_keys $selection]
            set this_result [list]
            for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		set var [lindex $col_names $i]
		set val [ns_set value $selection $i]
		set result_hash($var) $val
            }
        }
    }
    db_release_unused_handles

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Did not find object '$object_type' with the ID '$object_id'."] }

    # -------------------------------------------------------
    # Format the result for one of the supported formats
    set result ""
    foreach result_key [array names result_hash] {
	set result_val $result_hash($result_key)
	append result [im_rest_format_line \
			   -column $result_key \
			   -value $result_val \
			   -format $format \
			   -object_type $object_type \
	]
    }
	
    switch $format {
	html { doc_return 200 "text/html" "<html><body><table>\n$result</table></body></html>" }
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?><$object_type>$result</$object_type>" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}



ad_proc -private im_rest_get_object_type {
    { -format "xml" }
    { -user_id 0 }
    { -object_type "" }
    { -object_id 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_object_type: format=$format, user_id=$user_id, object_type=$object_type, object_id=$object_id, query_hash=$query_hash"

    switch $object_type {
	im_company - im_project {

	}
	default {
	    # Generic permission check using im_rest_user_id
	    set object_type_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$object_type'" -default 0]]
	    if {![im_object_permission -object_id $object_type_id -user_id $user_id -privilege "read"]} {
		return [im_rest_error -http_status 401 -message "No permissions to read object_type '$object_type'"] 
	    }
	}
    }

    db_1row object_type_info "
	select	*
	from	acs_object_types
	where	object_type = :object_type
    "

    set base_url "[im_rest_system_url]/intranet-rest"

    # -------------------------------------------------------
    # Select a number of objects from an object_type, based on criteria in the URL.
    # We join the object's main table with the acs_objects with object_type, because
    # acs_objects may contain "ruin objects" and the object's main table may contain
    # entries for sub-types.
    set sql "
	select	t.$id_column as object_id,
		${name_method}(t.$id_column) as object_name
	from	$table_name t,
		acs_objects o
	where	t.$id_column = o.object_id and
		o.object_type = :object_type
    "
    set result ""
    db_foreach objects $sql {
	set url "$base_url/$object_type/$object_id"
	switch $format {
	    xml { append result "<object_id href=\"$url\">$object_id</object_id>\n" }
	    html { 
		append result "<tr>
			<td>$object_id</td>
			<td>$object_name</td>
			<td><a href=\"$url\">$object_name</a>
		</tr>\n" 
	    }
	    xml {}
	}
    }
	
    switch $format {
	html { doc_return 200 "text/html" "<html>\n<body>\n<table>\n$result</table>\n</body>\n</html>\n" }
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}


# --------------------------------------------------------
# Auxillary functions
# --------------------------------------------------------



ad_proc -private im_rest_authenticate {
    -query_hash_values:required
} {
    Determine the autenticated user
} {
    array set query_hash $query_hash_values
    set header_vars [ns_conn headers]

    # Check for token authentication
    set token_user_id ""
    set token_token ""
    if {[info exists query_hash(user_id)]} { set token_user_id $query_hash(user_id)}
    if {[info exists query_hash(auth_token)]} { set token_token $query_hash(auth_token)}
    if {[info exists query_hash(auto_login)]} { set token_token $query_hash(auto_login)}

    # Check for HTTP "basic" authorization
    # Example: Authorization=Basic cHJvam9wOi5mcmFiZXI=
    set basic_auth [ns_set get $header_vars "Authorization"]
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

    # Check for OpenACS "Cookie" auth
    set cookie_auth_user_id [ad_get_user_id]

    # Determine authentication method used
    set auth_method ""
    if {"" != $cookie_auth_user_id && 0 != $cookie_auth_user_id } { set auth_method "cookie" }
    if {"" != $token_token} { set auth_method "token" }
    if {"" != $basic_auth_user_id} { set auth_method "basic" }

    switch $auth_method {
	cookie { set auth_user_id $cookie_auth_user_id }
	token { set auth_user_id $token_user_id }
	basic { set auth_user_id $basic_auth_user_id }
	default { return [im_rest_error -http_status 401 -message "No authentication found ('$auth_method')."] }
    }

    if {"" == $auth_user_id} { set auth_user_id 0 }
    ns_log Notice "im_rest_authenticate: auth_method=$auth_method, auth_user_id=$auth_user_id"

    return [list user_id $auth_user_id method $auth_method]
}



ad_proc -private im_rest_system_url { } {
    Returns a the system's "official" URL without trailing slash
    suitable to prefix all hrefs used for the XML format.
} {
    set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
    if {[regexp {^(.*)/$} $system_url match system_url_without]} { set system_url $system_url_without }
    return $system_url
}


ad_proc -private im_rest_format_line {
    -format:required
    -object_type:required
    -column:required
    -value:required
} {
    Format a single line according to format and return the result.
} {
    set base_url "[im_rest_system_url]/intranet-rest"

    # Transformation without knowing the object_type
    set href ""
    switch $column {
	company_id - customer_id - provider_id {
	    set company_name [util_memoize [list db_string cname "select company_name from im_companies where company_id=$value" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_company/$value\">$company_name</a>" }
		xml { set href "$base_url/im_company/$value" }
	    }
	}
	office_id - main_office_id {
	    set office_name [util_memoize [list db_string cname "select office_name from im_offices where office_id=$value" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_office/$value\">$office_name</a>" }
		xml { set value "<a href=\"$base_url/im_office/$value\">$office_name</a>" }
	    }
	}
	office_status_id - company_status_id - project_status_id - cost_status_id - cost_type_id - default_po_template_id - annual_revenue_id - default_delnote_template_id - default_bill_template_id - default_payment_method_id {
	    set category_name [im_category_from_id $value]
	    switch $format {
		html { set value "<a href=\"$base_url/im_category/$value\">$category_name</a>" }
		xml { set value "<a href=\"$base_url/im_category/$value\">$category_name</a>" }
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

ad_proc -public im_rest_error {
    { -http_status 404 }
    { -message "" }
} {
    Returns a suitable REST error message
} {
    ns_log Notice "im_rest_error: http_status=$http_status, message=$message"
    set url [im_url_with_query]

    switch $http_status {
	200 { set status_message "OK: Success!" }
	304 { set status_message "Not Modified: There was no new data to return." }
	400 { set status_message "Bad Request: The request was invalid. An accompanying error message will explain why." }
	401 { set status_message "Not Authorized: Authentication credentials were missing or incorrect." }
	403 { set status_message "Forbidden: The request is understood, but it has been refused.  An accompanying error message will explain why." }
	404 { set status_message "Not Found: The URI requested is invalid or the resource requested, for example a non-existing project." }
	406 { set status_message "Not Acceptable: Returned when an invalid format is specified in the request." }
	500 { set status_message "Internal Server Error: Something is broken.  Please post to the ]po[ .Open Discussions. forum." }
	502 { set status_message "Bad Gateway: project-open is probably down." }
	503 { set status_message "Service Unavailable: project-open is up, but overloaded with requests. Try again later." }
	default { set status_message "Unknown http_status '$http_status'." }
    }

    doc_return $http_status "text/xml" "<?xml version='1.0' encoding='UTF-8'?>
	<error>
		<http_status>$http_status</http_status>
		<http_status_message>$status_message</http_status_message>
		<request>$url</request>
		<message>$message</message>
	</error>
    "
    return
}
