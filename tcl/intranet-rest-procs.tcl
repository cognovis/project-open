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

ad_proc -private im_rest_call_post {} {
    Handler for GET rest calls
} {
    return [im_rest_call_get -http_method POST]
}


ad_proc -private im_rest_call_get {
    {-http_method GET }
} {
    Handler for GET rest calls
} {
    # Get the entire URL and decompose into the "rest_otype" 
    # and the "rest_oid" pieces. Splitting the URL on "/"
    # will result in "{} intranet-rest rest_otype rest_oid":
    set url [ns_conn url]
    set url_pieces [split $url "/"]
    set rest_otype [lindex $url_pieces 2]
    set rest_oid [lindex $url_pieces 3]

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
	-method $http_method \
	-format $format \
	-user_id $auth_user_id \
	-rest_otype $rest_otype \
	-rest_oid $rest_oid \
	-query_hash [array get query_hash]
    
}

# -------------------------------------------------------
# REST Call Drivers
# -------------------------------------------------------


ad_proc -private im_rest_call {
    { -method GET }
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for all REST calls
} {
    ns_log Notice "im_rest_call: method=$method, format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash"

    # -------------------------------------------------------
    # Special treatment for /intranet-rest/ and /intranet/rest/index URLs
    if {"" == $rest_otype} { set rest_otype "index" }
    set pages {"" index auto-login}
    if {[lsearch $pages $rest_otype] >= 0} {
	return [im_rest_page \
		    -format $format \
		    -user_id $user_id \
		    -rest_otype $rest_otype \
		    -rest_oid $rest_oid \
		    -query_hash $query_hash \
		   ]
    }

    # -------------------------------------------------------
    # Check the "rest_otype" to be a valid object type
    set valid_rest_otypes [util_memoize [list db_list otypes "select object_type from acs_object_types union select 'im_category'"]]
    if {[lsearch $valid_rest_otypes $rest_otype] < 0} { return [im_rest_error -http_status 406 -message "Invalid object_type '$rest_otype'. Valid object types include {im_project|im_company|...}."] }

    # -------------------------------------------------------
    # Special treatment for "im_category", because it's not an object type.
    if {"im_category" == $rest_otype} {
	return [im_rest_get_im_category \
		    -format $format \
		    -user_id $user_id \
		    -rest_otype $rest_otype \
		    -rest_oid $rest_oid \
		    -query_hash $query_hash \
		   ]
    }

    switch $method  {
	GET {
	    # Is there a valid rest_oid?
	    if {"" != $rest_oid && 0 != $rest_oid} {
		# Return everything we know about the object
		return [im_rest_get_object \
			    -format $format \
			    -user_id $user_id \
			    -rest_otype $rest_otype \
			    -rest_oid $rest_oid \
			    -query_hash $query_hash \
		]
	    } else {
		# Return query from the object rest_otype
		return [im_rest_get_object_type \
			    -format $format \
			    -user_id $user_id \
			    -rest_otype $rest_otype \
			    -query_hash $query_hash \
		]
	    }
	}

	POST {
	    # Is there a valid rest_oid?
	    if {"" != $rest_oid && 0 != $rest_oid} {
		# Return everything we know about the object
		return [im_rest_post_object \
		    -format $format \
		    -user_id $user_id \
		    -rest_otype $rest_otype \
		    -rest_oid $rest_oid \
		    -query_hash $query_hash \
		]
	    } else {
		# Return query from the object rest_otype
		return [im_rest_post_object_type \
			    -format $format \
			    -user_id $user_id \
			    -rest_otype $rest_otype \
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
    { -rest_otype "index" }
    { -format "xml" }
    { -user_id 0 }
    { -rest_oid 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    The user has requested /intranet-rest/ or /intranet-rest/index
} {
    ns_log Notice "im_rest_index_page: rest_otype=$rest_otype, query_hash=$query_hash"

    set params [list \
                    [list rest_otype $rest_otype] \
                    [list rest_oid $rest_oid] \
                    [list format $format] \
                    [list user_id $user_id] \
                    [list query_hash $query_hash] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-rest/www/$rest_otype"]
    doc_return 200 "text/html" $result
}

ad_proc -private im_rest_get_object {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_object: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash"

    # Check that rest_oid is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $rest_oid

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql [util_memoize [list im_rest_object_type_select_sql -rest_otype $rest_otype]]

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

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Did not find object '$rest_otype' with the ID '$rest_oid'."] }

    # -------------------------------------------------------
    # Format the result for one of the supported formats
    set result ""
    foreach result_key [array names result_hash] {
	set result_val $result_hash($result_key)
	append result [im_rest_format_line \
			   -column $result_key \
			   -value $result_val \
			   -format $format \
			   -rest_otype $rest_otype \
	]
    }
	
    switch $format {
	html { 
	    set page_title "object_type: [db_string n "select acs_object__name(:rest_oid)"]"
	    doc_return 200 "text/html" "
		[im_header $page_title][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?><$rest_otype>$result</$rest_otype>" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}


ad_proc -private im_rest_get_im_category {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash {} }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_im_category: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash"

    # Check that rest_oid is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $rest_oid

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql "select * from im_categories where category_id = :rest_oid"

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

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Did not find object '$rest_otype' with the ID '$rest_oid'."] }

    # -------------------------------------------------------
    # Format the result for one of the supported formats
    set result ""
    foreach result_key [array names result_hash] {
	set result_val $result_hash($result_key)
	append result [im_rest_format_line \
			   -column $result_key \
			   -value $result_val \
			   -format $format \
			   -rest_otype $rest_otype \
	]
    }
	
    switch $format {
	html { 
	    set page_title "$rest_otype: [im_category_from_id $rest_oid]"
	    doc_return 200 "text/html" "
		[im_header $page_title][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?><$rest_otype>$result</$rest_otype>" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}



ad_proc -private im_rest_get_object_type {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_object_type: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash"
    
    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$rest_otype'" -default 0]]
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "read"]

    db_1row rest_otype_info "
	select	*
	from	acs_object_types
	where	object_type = :rest_otype
    "

    set base_url "[im_rest_system_url]/intranet-rest"

    # -------------------------------------------------------
    # Select a number of objects from an rest_otype, based on criteria in the URL.
    # We join the object's main table with the acs_objects with rest_otype, because
    # acs_objects may contain "ruin objects" and the object's main table may contain
    # entries for sub-types.
    set sql "
	select	t.$id_column as rest_oid,
		${name_method}(t.$id_column) as object_name
	from	$table_name t,
		acs_objects o
	where	t.$id_column = o.object_id and
		o.object_type = :rest_otype
    "
    set result ""
    db_foreach objects $sql {

	# Check permissions
	set read_p $rest_otype_read_all_p

	if {!$read_p} {
	    # There are "view_xxx_all" permissions allowing a user to see all objects:
	    switch $rest_otype {
		bt_bug { }
		im_company { set read_p [im_permission $user_id "view_companies_all"] }
		im_cost { }
		im_conf_item { set read_p [im_permission $user_id "view_conf_items_all"] }
		im_project { set read_p [im_permission $user_id "view_projects_all"] }
		im_user_absence { set read_p [im_permission $user_id "view_absences_all"] }
		im_office { set read_p [im_permission $user_id "view_offices_all"] }
		im_ticket { set read_p [im_permission $user_id "view_tickets_all"] }
		im_timesheet_task { set read_p [im_permission $user_id "view_timesheet_tasks_all"] }
		im_translation_task { }
		user { }
		default { 
		    # No read permissions? Well, all object types except the ones above
		    # have no custom permission procedure...
		    continue 
		}
	    }
	}

	if {!$read_p} {
	    # This is one of the "custom" object types - check the permission:
	    # This may be quite slow checking 100.000 objects one-by-one...
	    eval "${rest_otype}_permissions $user_id $rest_oid view_p read_p write_p admin_p"
	    if {!$read_p} { continue }
	}

	set url "$base_url/$rest_otype/$rest_oid"
	switch $format {
	    xml { append result "<object_id href=\"$url\">$rest_oid</object_id>\n" }
	    html { 
		append result "<tr>
			<td>$rest_oid</td>
			<td><a href=\"$url?format=html\">$object_name</a>
		</tr>\n" 
	    }
	    xml {}
	}
    }
	
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}



# --------------------------------------------------------
# POST
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for POST rest calls to an object type - create a new object.
} {
    ns_log Notice "im_rest_post_object_type: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash"
    set base_url "[im_rest_system_url]/intranet-rest"

    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$rest_otype'" -default 0]]
    set rest_otype_write_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "create"]

    # Get the HTTP contents
    set content [ns_conn content]

    # Switch to object specific procedures for handling new object creation
    # Check if the procedure exists
    if {0 != [llength [info commands im_rest_post_$rest_otype]]} {
	
	set rest_oid [eval [list im_rest_post_$rest_otype \
		  -format $format \
		  -user_id $user_id \
		  -content $content \
	]]

	switch $format {
	    html { 
		set page_title "object_type: $rest_otype"
		doc_return 200 "text/html" "
		[im_header $page_title][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Object ID</td></tr>
		<tr<td>$rest_oid</td></tr>
		</table>[im_footer]
	        "
	    }
	    xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id>$rest_oid</object_id>\n" }
	    default {
		ad_return_complaint 1 "Invalid format: '$format'"
	    }
	}

    } else {
	im_rest_error -http_status 404 -message "No 'create' operation available for object type '$rest_otype'."
    }
    return
}

ad_proc -private im_rest_post_object {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for POST rest calls to an individual object:
    Update the specific object using a generic update procedure
} {
    ns_log Notice "im_rest_post_object: rest_otype=$rest_otype, rest_oid=$rest_oid, user_id=$user_id, query_hash=$query_hash"

    # Get the HTTP contents
    set content [ns_conn content]

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: 'err_msg'."]
    }

    set root_node [$doc documentElement]
    array unset hash_array
    foreach child [$root_node childNodes] {
	set nodeName [$child nodeName]
	set nodeText [$child text]
       	set hash_array($nodeName) $nodeText
    }

    # Generic update for the object
    im_rest_object_type_update_sql \
	-rest_otype $rest_otype \
	-rest_oid $rest_oid \
	-hash_array [array get hash_array] \


    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Object ID</td></tr>
		<tr<td>$rest_oid</td></tr>
		</table>[im_footer]
	    "
	}
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id>$rest_oid</object_id>\n" }
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }

}



ad_proc -private im_rest_post_im_project {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new project and returns the project_id.
} {
    ns_log Notice "im_rest_post_im_project: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: 'err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	set nodeName [$child nodeName]
	set nodeText [$child text]
	
	# Store the values
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set parent_sql "parent_id = :parent_id"
    if {"" == $parent_id} { set parent_sql "parent_id is NULL" }

    set dup_sql "
                select  count(*)
                from    im_projects
                where   $parent_sql and
                        (       upper(trim(project_name)) = upper(trim(:project_name)) OR
                                upper(trim(project_nr)) = upper(trim(:project_nr)) OR
                                upper(trim(project_path)) = upper(trim(:project_path))
                        )
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Project: Your project name or project path already exists for the specified parent_id."]
    }

    if {[catch {
        set rest_oid [project::new \
			-creation_user	    $user_id \
			-context_id	    "" \
			-project_name       $hash(project_name) \
			-project_nr         $hash(project_nr) \
			-project_path       $hash(project_path) \
			-company_id         $hash(company_id) \
			-parent_id          $hash(parent_id) \
			-project_type_id    $hash(project_type_id) \
			-project_status_id  $hash(project_status_id) \
        ]
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating project: 'err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_project" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating project: 'err_msg'."]
    }
    
    return $rest_oid
}


# --------------------------------------------------------
# Auxillary functions
# --------------------------------------------------------



ad_proc -private im_rest_authenticate {
    {-debug 1}
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
    if {$debug} { ns_log Notice "im_rest_authenticate: basic_auth=$basic_auth, basic_auth_username=$basic_auth_username, basic_auth_password=$basic_auth_password" }

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
	    set company_name [util_memoize [list db_string cname "select company_name from im_companies where company_id=$rest_oid" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_company/$value?format=html\">$company_name</a>" }
		xml { set href "$base_url/im_company/$value" }
	    }
	}
	im_company.main_office_id - im_invoice.invoice_office_id - im_timesheet_invoice.invoice_office_id - im_trans_invoice.invoice_office_id {
	    set office_name [util_memoize [list db_string cname "select office_name from im_offices where office_id=$rest_oid" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_office/$value?format=html\">$office_name</a>" }
		xml { set href "$base_url/im_office/$value" }
	    }
	}
	im_invoice.project_id - im_timesheet_invoice.project_id - im_trans_invoice.project_id - im_project.project_id - im_project.parent_id - im_timesheet_task.project_id - im_timesheet_task.parent_id - im_expense.project_id - im_ticket.project_id - im_ticket.parent_id - im_trans_task.project_id {
	    set project_name [util_memoize [list db_string cname "select project_name from im_projects where project_id=$rest_oid" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_project/$value?format=html\">$project_name</a>" }
		xml { set href "$base_url/im_project/$value" }
	    }
	}
	im_project.project_lead_id - im_timesheet_task.project_lead_id - im_invoice.company_contact_id - im_timesheet_invoice.company_contact_id - im_trans_invoice.company_contact_id - im_project.company_contact_id - im_cost_center.manager_id - im_cost_center.parent_id - im_conf_item.conf_item_owner_id - im_expense.provider_id - im_ticket.ticket_customer_contact_id - im_user_absence.owner_id {
	    set user_name [im_name_from_user_id $value]
	    switch $format {
		html { set value "<a href=\"$base_url/user/$value?format=html\">$user_name</a>" }
		xml { set href "$base_url/user/$value" }
	    }
	}
	im_office.office_status_id - im_office.office_type_id - im_company.company_status_id - im_company.company_type_id - im_project.project_status_id - im_project.project_type_id - im_timesheet_task.project_status_id - im_timesheet_task.project_type_id - im_invoice.cost_status_id - im_invoice.cost_type_id - im_timesheet_invoice.cost_status_id - im_timesheet_invoice.cost_type_id - im_trans_invoice.cost_status_id - im_trans_invoice.cost_type_id - im_company.default_invoice_template_id - im_company.default_po_template_id - im_company.annual_revenue_id - im_company.default_delnote_template_id - im_company.default_bill_template_id - im_company.default_payment_method_id - im_invoice.template_id - im_timesheet_invoice.template_id - im_trans_invoice.template_id - im_invoice.payment_method_id - im_timesheet_invoice.payment_method_id - im_trans_invoice.payment_method_id - im_project.on_track_status_id - im_cost_center.cost_center_status_id - im_cost_center.cost_center_type_id - im_biz_object_member.object_role_id - im_conf_item.conf_item_status_id - im_conf_item.conf_item_type_id - im_expense.vat_type_id - im_expense.cost_status_id - im_expense.cost_type_id - im_expense.expense_type_id - im_expense.expense_payment_type_id - im_material.material_type_id - im_material.material_status_id - im_material.material_uom_id - im_release_item.release_status_id - im_rest_object_type.object_type_type_id - im_rest_object_type.object_type_status_id - im_ticket.ticket_status_id - im_ticket.ticket_type_id - im_ticket.project_status_id - im_ticket.project_type_id - im_timesheet_task.uom_id - im_trans_task.task_status_id - im_trans_task.task_type_id - im_trans_task.task_uom_id - im_trans_task.source_language_id - im_trans_task.target_language_id - im_trans_task.tm_integration_type_id - im_user_absence.absence_type_id - im_user_absence.absence_status_id - user.skin_id {
	    set category_name [im_category_from_id $value]
	    switch $format {
		html { set value "<a href=\"$base_url/im_category/$value?format=html\">$category_name</a>" }
		xml { set href "$base_url/im_category/$value" }
	    }

	}
	im_invoice.cost_center_id - im_timesheet_invoice.cost_center_id - im_trans_invoice.cost_center_id - im_expense.cost_center_id - im_timesheet_task.cost_center_id {
	    set cc_name [util_memoize [list db_string cname "select im_cost_center_name_from_id($value)" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_cost_center/$value?format=html\">$cc_name</a>" }
		xml { set href "$base_url/im_cost_center/$value" }
	    }
	}
	im_timesheet_task.material_id {
	    set material_name [util_memoize [list db_string cname "select im_material_name_from_id($value)" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_material/$value?format=html\">$material_name</a>" }
		xml { set href "$base_url/im_material/$value" }
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

ad_proc -public im_rest_object_type_select_sql { 
    -rest_otype:required
} {
    Calculates the SQL statement to extract the value for an object
    of the given rest_otype. The SQL will contains a ":rest_oid"
    colon-variables, so the variable "rest_oid" must be defined in 
    the context where this statement is to be executed.
} {
    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all information about one object
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

    set letters {a b c d e f g h i j k l m n o p q r s t u v w x y z}
    set from {}
    set wheres { "1=1" }
    set cnt 0
    db_foreach tables $tables_sql {
	set letter [lindex $letters $cnt]
	lappend froms "$table_name $letter"
	lappend wheres "$letter.$id_column = :rest_oid"
	incr cnt
    }

    set sql "
	select	*
	from	[join $froms ", "]
	where	[join $wheres " and "]
    "
    return $sql
}



# ----------------------------------------------------------------------
# Update all tables of an object type.
# ----------------------------------------------------------------------

ad_proc -public im_rest_object_type_update_sql { 
    -rest_otype:required
    -rest_oid:required
    -hash_array:required
} {
    Updates all the object's tables with the information from the
    hash array.
} {
    ns_log Notice "im_rest_object_type_update_sql: rest_otype=$rest_otype, rest_oid=$rest_oid, hash_array=$hash_array"

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

	# ignore variables that are not available in the var hash
	if {![info exists hash($column_name)]} { continue }
	# skip tree_sortkey stuff
	if {"tree_sortkey" == $column_name} { continue }
	# ignore reserved variables
	if {"rest_otype" == $column_name} { contiue }
	if {"rest_oid" == $column_name} { contiue }
	if {"hash_array" == $column_name} { contiue }
	# ignore any "*_cache" variables (financial cache)
	if {[regexp {_cache$} $column_name match]} { continue }

	set sqls [list]
	if {[info exists sql_hash($table_name)]} { set sqls $sql_hash($table_name) }
	lappend sqls "$column_name = :$column_name"
	set sql_hash($table_name) $sqls
    }

    # Add the rest_oid to the hash
    set hash(rest_oid) $rest_oid

    foreach table [array names sql_hash] {
	set sqls $sql_hash($table)
	set update_sql "update $table set [join $sqls ", "] where $index_column($table) = :rest_oid"

	if {[catch {
	    db_dml sql_$table $update_sql -bind [array get hash]
	} err_msg]} {
	    return [im_rest_error -http_status 404 -message "Error updating $rest_otype: '$err_msg'"]
	}
    }
    return
}



# ----------------------------------------------------------------------
# Error Handling
# ----------------------------------------------------------------------

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
	500 { set status_message "Internal Server Error: Something is broken.  Please post to the &\#93;project-open&\#91; Open Discussions forum." }
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
