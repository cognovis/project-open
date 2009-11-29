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
    
    # Get URL header and extract interesting variables
    set header_vars [ns_conn headers]

    # ------------------------------------------------------
    # Check for different authentication methods

    # Check for token authentication
    set token_user_id ""
    set token_token ""
    if {[info exists query_hash(token_user_id)]} { set token_user_id $query_hash(token_user_id)}
    if {[info exists query_hash(token_token)]} { set token_token $query_hash(token_token)}

    # Check for HTTP "basic" authorization
    # Example: Authorization=Basic cHJvam9wOi5mcmFiZXI=
    set basic_auth [ns_set get $header_vars "Authorization"]
    set basic_auth_username ""
    set basic_auth_password ""
    if {[regexp {^([a-zA-Z_]+)\ (.*)$} $basic_auth match method userpass_base64]} {
	set basic_auth_userpass [base64::decode $userpass_base64]
	regexp {^([^\:]+)\:(.*)$} $basic_auth_userpass match basic_auth_username basic_auth_password
    }

    # Get information about this system
    set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
    # remove any trailing "/"
    if {[regexp {^(.*)/$} $system_url match body]} { set system_url $body }

    # Default format are:
    # - "html" for cookie authentication
    # - "xml" for basic authentication
    # - "xml" for auth_token authentication
    set format "html"
    if {$basic_auth_username != ""} { set format "xml" }
    if {$token_token != ""} { set format "xml" }
    if {[info exists query_hash(format)]} { set format $query_hash(format) }
    set valid_formats {xml html csv json}
    if {[lsearch $valid_formats $format] < 0} { im_rest_error -http_status 406 -message "Invalid output format '$format'. Valid formats include {xml|html|json}." }

    # Call the main request processing routine
    im_rest_call \
	-method GET \
	-format $format \
	-user_id 626 \
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
    # Check the "object_type" to be a valid object type
    set valid_object_types [util_memoize [list db_list otypes "select object_type from acs_object_types"]]
    if {[lsearch $valid_object_types $object_type] < 0} { im_rest_error -http_status 406 -message "Invalid object_type '$object_type'. Valid object types include {im_project|im_company|...}." }

    switch $method  {
	GET {
	    # Is there a valid object_id?
	    if {"" != $object_id && 0 != $object_id} {
		# Return everything we know about the object
		im_rest_get_object \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -object_id $object_id \
		    -query_hash $query_hash \
	    } else {
		# Return query from the object object_type
		im_rest_get_object_type \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -query_hash $query_hash \
	    }
	}

	POST {
	    # Is there a valid object_id?
	    if {"" != $object_id && 0 != $object_id} {
		# Return everything we know about the object
		im_rest_post_object \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -object_id $object_id \
		    -query_hash $query_hash \
	    } else {
		# Return query from the object object_type
		im_rest_post_object_type \
		    -format $format \
		    -user_id $user_id \
		    -object_type $object_type \
		    -query_hash $query_hash \
	    }
	}

	default {
	    im_rest_error -http_status 400 -message "Unknown HTTP request '$method'. Valid requests include {GET|POST}."
	}
    }
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

    if {{} == [array get result_hash]} { im_rest_error -http_status 404 -message "Did not find object '$object_type' with the ID '$object_id'." }

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

    db_1row object_type_info "
	select	*
	from	acs_object_types
	where	object_type = :object_type
    "

    set base_url "/intranet-rest"

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
	switch $format {
	    xml {}
	    html { 
		append result "<tr>
			<td>$object_id</td>
			<td>$object_name</td>
			<td><a href='$base_url/$object_type/$object_id'>$object_name</a>
		</tr>" 
	    }
	    xml {}
	}
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


# --------------------------------------------------------
# Auxillary functions
# --------------------------------------------------------

ad_proc -private im_rest_format_line {
    -format:required
    -object_type:required
    -column:required
    -value:required
} {
    Format a single line according to format and return the result.
} {
    set base_url "/intranet-rest"

    # Transformation without knowing the object_type
    switch $column {
	company_id - customer_id - provider_id {
	    set company_name [util_memoize [list db_string cname "select company_name from im_companies where company_id=$value" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_company/$value\">$company_name</a>" }
		xml { set value "<a href=\"$base_url/im_company/$value\">$company_name</a>" }
	    }
	}
	office_id - main_office_id {
	    set office_name [util_memoize [list db_string cname "select office_name from im_offices where office_id=$value" -default $value]]
	    switch $format {
		html { set value "<a href=\"$base_url/im_office/$value\">$office_name</a>" }
		xml { set value "<a href=\"$base_url/im_office/$value\">$office_name</a>" }
	    }
	}
	office_status_id - company_status_id - project_status_id - cost_status_id - cost_type_id {
	    set category_name [im_category_from_id $value]
	    switch $format {
		html { set value "<a href=\"$base_url/im_category/$value\">$category_name</a>" }
		xml { set value "<a href=\"$base_url/im_category/$value\">$category_name</a>" }
	    }

	}
    }

    switch $format {
	html { return "<tr><td>$column</td><td>$value</td></tr>\n" }
	xml { return "<$column>$value</$column>\n" }
	json { return "<$column>$value</$column>\n" }
	csv { return "$column=$value\n" }
    }
}

ad_proc -public im_rest_error {
    { -http_status 404 }
    { -message "" }
} {
    Returns a suitable REST error message
} {
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
    ad_script_abort
}
