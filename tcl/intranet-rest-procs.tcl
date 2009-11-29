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
# ad_register_proc DELETE /intranet-rest/* im_rest_call_delete
# ad_register_proc PUT /intranet-rest/* im_rest_call_put


# -------------------------------------------------------
# HTTP Interface
#
# Deal HTTP parameters, authentication etc.
# -------------------------------------------------------

ad_proc -private im_rest_call_get {} {
    Handler for GET rest calls
} {
    # Get the entire URL and decompose into the "factory" 
    # and the "object_id" pieces. Splitting the URL on "/"
    # will result in "{} intranet-rest factory object_id":
    set url [ns_conn url]
    set url_pieces [split $url "/"]
    set factory [lindex $url_pieces 2]
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
    if {1}  {
	im_rest_call \
	    -method GET \
	    -format $format \
	    -user_id 626 \
	    -factory $factory \
	    -object_id $object_id \
	    -query_hash [array get query_hash]
    }

    # ---------------------------------------------------------

    set header_debug ""
    foreach var [ad_ns_set_keys $header_vars] {
        set value [ns_set get $header_vars $var]
        append header_debug "$var=$value\n"
    }

    doc_return 200 "text/html" "
	<h1>im_rest_call_get</h1>
	<pre>
	url=$url
	query=$query
	query_hash=[array get query_hash]
	url_pieces=$url_pieces
	factory=$factory
	oid=$object_id
	system_url=$system_url
	basic_auth_username=$basic_auth_username
	basic_auth_password=$basic_auth_password
	---------------------------------------------------
	$header_debug
	---------------------------------------------------
	</pre>
    "
}

ad_proc -private im_rest_call_post {} {
    Handler for GET rest calls
} {
    return "<?xml version='1.0'?>\n"
}

ad_proc -private im_rest_call_put {} {
    Handler for GET rest calls
} {
    return "<?xml version='1.0'?>\n"
}

ad_proc -private im_rest_call_delete {} {
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
    { -factory "" }
    { -object_id 0 }
    { -query_hash {} }
    { -debug 0 }
} {
    Handler for GET rest calls
} {
    if {$debug} {
	doc_return 200 "text/html" "
	<h1>im_rest_call</h1>
	<pre>
	method=$method
	format=$format
	user_id=$user_id
	factory=$factory
	object_id=$object_id
	query_hash=$query_hash
	</pre>
	"
    }

    # -------------------------------------------------------
    # Check the "factory" to be a valid object type
    set valid_object_types [util_memoize [list db_list otypes "select object_type from acs_object_types"]]
    if {[lsearch $valid_object_types $factory] < 0} { im_rest_error -http_status 406 -message "Invalid object_type '$factory'. Valid object types include {im_project|im_company|...}." }
    set object_type $factory

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
	html {
	    doc_return 200 "text/html" "
		<html><body><table>\n$result</table></body></html>
	    "
	}
	xml {
	    doc_return 200 "text/xml" "<?xml version='1.0'?>
		<$object_type>$result</$object_type>
	    "
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}



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
    doc_return $http_status "text/xml" "<?xml version='1.0' encoding='UTF-8'?>
<error>
	<request>$url</request>
	<message>$message</message>
</error>
"
    ad_script_abort
}
