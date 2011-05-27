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

# -------------------------------------------------------
# REST Version
# -------------------------------------------------------

ad_proc -private im_rest_version {} {
    Returns the current server version of the REST interface.
    Please see www.project-open.org/documentation/rest_version_history
    <li>2.0	(2011-05-12):	Added support for JSOn and Sencha format variants
				ToDo: Always return "id" instead of "object_id"
    <li>1.5.2	(2010-12-21):	Fixed bug of not applying where_query
    <li>1.5.1	(2010-12-01):	Fixed bug with generic objects, improved rendering of some fields
    <li>1.5	(2010-11-03):	Added rest_object_permissions and rest_group_memberships reports
    <li>1.4	(2010-06-11):	Added /intranet-rest/dynfield-widget-values
    <li>1.3	(2010-04-01):	First public version
} {
    return "1.6"
}

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

ad_proc -private im_rest_call_put {} {
    Handler for PUT rest calls
} {
    set user_id [im_rest_cookie_auth_user_id]
    ns_log Notice "im_rest_call_put: user_id=$user_id"
    return [im_rest_call_get -http_method PUT]
}

ad_proc -private im_rest_call_delete {} {
    Handler for DELETE rest calls
} {
    return [im_rest_call_get -http_method DELETE]
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
	    ns_log Notice "im_rest_call_get: var='$var', val='$val'"

	    # Additional decoding: replace "+" by " "
	    regsub -all {\+} $var { } var
	    regsub -all {\+} $val { } val

	    set var [ns_urldecode $var]
	    set val [ns_urldecode $val]
	    ns_log Notice "im_rest_call_get: var='$var', val='$val'"
	    set query_hash($var) $val
	}
    }

    # Determine the authenticated user_id. 0 means not authenticated.
    array set auth_hash [im_rest_authenticate -query_hash_pairs [array get query_hash]]
    if {0 == [llength [array get auth_hash]]} { return [im_rest_error -http_status 401 -message "Not authenticated"] }
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
    set valid_formats {xml html json}
    if {[lsearch $valid_formats $format] < 0} { return [im_rest_error -http_status 406 -message "Invalid output format '$format'. Valid formats include {xml|html|json}."] }

    # Should we return Sencha or YUI specific status messages?
    set format_variant ""
    if {[info exists query_hash(format_variant)]} { set format_variant $query_hash(format_variant) }
    set valid_format_variants {{} sencha yui}
    if {[lsearch $valid_format_variants $format_variant] < 0} { return [im_rest_error -http_status 406 -message "Invalid format_variant option '$format_variant'. Valid formats include $valid_format_variants."] }


    # Call the main request processing routine
    if {[catch {

	im_rest_call \
	    -method $http_method \
	    -format $format \
	    -format_variant $format_variant \
	    -user_id $auth_user_id \
	    -rest_otype $rest_otype \
	    -rest_oid $rest_oid \
	    -query_hash_pairs [array get query_hash]

    } err_msg]} {

	ns_log Notice "im_rest_call_get: im_rest_call returned an error: $err_msg"
	return [im_rest_error -http_status 500 -message "Internal error: [ns_quotehtml $err_msg]"]

    }
    
}

# -------------------------------------------------------
# REST Call Drivers
# -------------------------------------------------------


ad_proc -private im_rest_call {
    { -method GET }
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for all REST calls
} {
    ns_log Notice "im_rest_call: method=$method, format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

    # -------------------------------------------------------
    # Special treatment for /intranet-rest/ and /intranet/rest/index URLs
    if {"" == $rest_otype} { set rest_otype "index" }
    set pages {"" index version auto-login dynfield-widget-values }
    if {[lsearch $pages $rest_otype] >= 0} {
	return [im_rest_page \
		    -format $format \
		    -format_variant $format_variant \
		    -user_id $user_id \
		    -rest_otype $rest_otype \
		    -rest_oid $rest_oid \
		    -query_hash_pairs $query_hash_pairs \
		   ]
    }

    # -------------------------------------------------------
    # Check the "rest_otype" to be a valid object type
    set valid_rest_otypes [util_memoize [list db_list otypes "
	select	object_type 
	from	acs_object_types union
	select	'im_category'
    "]]
    if {[lsearch $valid_rest_otypes $rest_otype] < 0} { return [im_rest_error -http_status 406 -message "Invalid object_type '$rest_otype'. Valid object types include {im_project|im_company|...}."] }

    # -------------------------------------------------------
    switch $method  {
	GET {

	    # Is there a valid rest_oid?
	    if {"" != $rest_oid && 0 != $rest_oid} {

		# Special treatment for "im_category", because it's not an object type.
		switch $rest_otype {
		    im_category {
			return [im_rest_get_im_category \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_dynfield_attribute {
			return [im_rest_get_im_dynfield_attribute \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_invoice_item {
			return [im_rest_get_im_invoice_item \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_hour {
			return [im_rest_get_im_hour \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    default {
			# Return generic object information
			return [im_rest_get_object \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		}


	    } else {

		# There is no oid, so the resource is the object_type itself.
		switch $rest_otype {
		    im_category {
			return [im_rest_get_im_categories \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_dynfield_attribute {
			return [im_rest_get_im_dynfield_attributes \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_invoice_item {
			return [im_rest_get_im_invoice_items \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_hour {
			return [im_rest_get_im_hours \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    default {
			# Return query from the object rest_otype
			return [im_rest_get_object_type \
				    -format $format \
				    -format_variant $format_variant \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
			
		    }
		}
	    }
	}
	POST - PUT {
	    # Is the post operation performed on a particular object or on the object_type?
	    if {"" != $rest_oid && 0 != $rest_oid} {

		# POST with object_id => Update operation on an object
		ns_log Notice "im_rest_call: Found a POST operation on object_type=$rest_otype with object_id=$rest_oid"
		return [im_rest_post_object \
		    -format $format \
		    -format_variant $format_variant \
		    -user_id $user_id \
		    -rest_otype $rest_otype \
		    -rest_oid $rest_oid \
		    -query_hash_pairs $query_hash_pairs \
		]
		
	    } else {

		# POST without object_id => Update operation on the "factory" object_type
		ns_log Notice "im_rest_call: Found a POST operation on object_type=$rest_otype"
		return [im_rest_post_object_type \
			    -format $format \
			    -format_variant $format_variant \
			    -user_id $user_id \
			    -rest_otype $rest_otype \
			    -query_hash_pairs $query_hash_pairs \
		]
	    }
	}
	default {
	    return [im_rest_error -http_status 400 -message "Unknown HTTP request '$method'. Valid requests include {GET|POST|PUT|DELETE}."]
	}
    }
}


ad_proc -private im_rest_page {
    { -rest_otype "index" }
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    The user has requested /intranet-rest/ or /intranet-rest/index
} {
    ns_log Notice "im_rest_index_page: rest_otype=$rest_otype, query_hash=$query_hash_pairs"

    set params [list \
		    [list rest_otype $rest_otype] \
		    [list rest_oid $rest_oid] \
		    [list format $format] \
		    [list user_id $user_id] \
		    [list query_hash_pairs $query_hash_pairs] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-rest/www/$rest_otype"]
    if {[regexp {<\?xml} $result match]} {
	set mime_type "text/xml"
    } else {
	set mime_type "text/html"
    }

    doc_return 200 $mime_type $result
    return
}

ad_proc -private im_rest_get_object {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_object: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

    # Check that rest_oid is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $rest_oid

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
#    set sql [util_memoize [list im_rest_object_type_select_sql -rest_otype $rest_otype]]
    set sql [im_rest_object_type_select_sql -rest_otype $rest_otype]

    # Get the list of index columns of the object's various tables.
    set index_columns [im_rest_object_type_index_columns -rest_otype $rest_otype]

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
		# fraber 100519: I don't remember why index columns shouldn't be part of the
		# returned fields in the first place. But now we need them in the Timesheet
		# REST application.
		# if {[lsearch $index_columns $var] >= 0} { continue }

		set result_hash($var) $val
	    }
	}
    }
    db_release_unused_handles

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Generic: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<$rest_otype>\n$result</$rest_otype>" 
	}
	json {  
	    doc_return 200 "text/plain" "{object_type: \"$rest_otype\",\n$result\n}" 
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}


ad_proc -private im_rest_get_im_category {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_im_category: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

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

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Category: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    "
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?><$rest_otype>$result</$rest_otype>" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    # ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"
    return

}


ad_proc -private im_rest_get_im_dynfield_attribute {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
} {
    Handler for GET rest calls
} {
    ns_log Notice "im_rest_get_im_dynfield_attribute: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

    # Check that rest_oid is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $rest_oid

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql "
	select	*
	from	im_dynfield_attributes da,
		acs_attributes aa
	where	da.acs_attribute_id = aa.attribute_id and
		da.attribute_id = :rest_oid
    "

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

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Dynfield Attribute: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    set page_title "$rest_otype: $result_hash(table_name).$result_hash(column_name)"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    "
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?><$rest_otype>$result</$rest_otype>" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    return

}

ad_proc -private im_rest_get_im_invoice_item {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
} {
    Handler for GET rest calls to retreive invoice items
} {
    ns_log Notice "im_rest_get_im_invoice_item: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

    # Check that rest_oid is an integer
    im_security_alert_check_integer -location "im_rest_get_object" -value $rest_oid

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql "select * from im_invoice_items where item_id = :rest_oid"

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

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Invoice Item: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    set page_title "$rest_otype: $rest_oid"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    "
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?><$rest_otype>$result</$rest_otype>" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    # ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"
    return

}

ad_proc -private im_rest_get_im_hour {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
} {
    Handler for GET rest calls to retreive timesheet hours
} {
    ns_log Notice "im_rest_get_im_hour: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

    # Check that rest_oid is an integer
    im_security_alert_check_integer -location "im_rest_get_im_hour" -value $rest_oid

    # -------------------------------------------------------
    # Get the SQL to extract all values from the object
    set sql "select * from im_hours where hour_id = :rest_oid"

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

    if {{} == [array get result_hash]} { return [im_rest_error -http_status 404 -message "Timesheet Hour: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    set page_title "$rest_otype: $rest_oid"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Attribute</td><td class=rowtitle>Value</td></tr>$result
		</table>[im_footer]
	    "
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?><$rest_otype>$result</$rest_otype>" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	}
    }
  
    return

}


ad_proc -private im_rest_get_object_type {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls on a whole object type -
    mapped to queries on the specified object type
} {
    ns_log Notice "im_rest_get_object_type: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"
    array set query_hash $query_hash_pairs
    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$rest_otype'" -default 0]]

    # -------------------------------------------------------
    # Get some more information about the current object type
    db_1row rest_otype_info "
	select	*
	from	acs_object_types
	where	object_type = :rest_otype
    "

    set base_url "[im_rest_system_url]/intranet-rest"


    # -------------------------------------------------------
    # Check for generic permissions to read all objects of this type
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "read"]

    # Deny completely access to the object type?
    set rest_otype_read_none_p 0

    if {!$rest_otype_read_all_p} {
	# There are "view_xxx_all" permissions allowing a user to see all objects:
	switch $rest_otype {
	    bt_bug		{ }
	    im_company		{ set rest_otype_read_all_p [im_permission $user_id "view_companies_all"] }
	    im_cost		{ set rest_otype_read_all_p [im_permission $user_id "view_finance"] }
	    im_conf_item	{ set rest_otype_read_all_p [im_permission $user_id "view_conf_items_all"] }
	    im_invoices		{ set rest_otype_read_all_p [im_permission $user_id "view_finance"] }
	    im_project		{ set rest_otype_read_all_p [im_permission $user_id "view_projects_all"] }
	    im_user_absence	{ set rest_otype_read_all_p [im_permission $user_id "view_absences_all"] }
	    im_office		{ set rest_otype_read_all_p [im_permission $user_id "view_offices_all"] }
	    im_ticket		{ set rest_otype_read_all_p [im_permission $user_id "view_tickets_all"] }
	    im_timesheet_task	{ set rest_otype_read_all_p [im_permission $user_id "view_timesheet_tasks_all"] }
	    im_timesheet_invoices { set rest_otype_read_all_p [im_permission $user_id "view_finance"] }
	    im_trans_invoices	{ set rest_otype_read_all_p [im_permission $user_id "view_finance"] }
	    im_translation_task	{ }
	    user		{ }
	    default { 
		# No read permissions? 
		# Well, no object type except the ones above has a custom procedure,
		# so we can deny access here:
		set rest_otype_read_none_p 1
	    }
	}
    }

    # -------------------------------------------------------
    # Check if there is a where clause specified in the URL
    # and validate the clause.
    set where_clause ""
    if {[info exists query_hash(query)]} { set where_clause $query_hash(query)}

    set where_clause [ns_urldecode $where_clause]
    ns_log Notice "im_rest_get_object_type: where_clause=$where_clause"


    # Determine the list of valid columns for the object type
    set valid_vars [util_memoize [list im_rest_object_type_columns -rest_otype $rest_otype]]


    # -------------------------------------------------------
    # Check if there are "valid_vars" specified in the HTTP header
    # and add these vars to the SQL clause
    set where_clause_list [list]
    foreach v $valid_vars {
	if {[info exists query_hash($v)]} { lappend where_clause_list "$v=$query_hash($v)" }
    }
    if {"" != $where_clause && [llength $where_clause_list] > 0} { append where_clause " and " }
    append where_clause [join $where_clause_list " and "]
 
    # Check that the query is a valid SQL where clause
    set valid_sql_where [im_rest_valid_sql -string $where_clause -variables $valid_vars]
    if {!$valid_sql_where} {
	im_rest_error -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
	return
    }
    if {"" != $where_clause} { set where_clause "and $where_clause" }


    # -------------------------------------------------------
    # Transform the database table to deal with exceptions
    #
    switch $rest_otype {
	user - person - party {
	    set table_name "(select * from users u, parties pa, persons pe where u.user_id = pa.party_id and u.user_id = pe.person_id )"
	}
    }


    # -------------------------------------------------------
    # Select SQL: Pull out objects where the acs_objects.object_type 
    # is correct AND the object exists in the object type's primary table.
    # This way we avoid "dangling objects" in acs_objects and sub-types.
    set sql [im_rest_object_type_select_sql -rest_otype $rest_otype -no_where_clause_p 1]
    append sql "
	where	o.object_type = :rest_otype and
		o.object_id in (
			select  t.$id_column as rest_oid
			from    $table_name t
		)
		$where_clause
    "

    # Append pagination "LIMIT $limit OFFSET $start" to the sql.
    set unlimited_sql $sql
    append sql [im_rest_object_type_pagination_sql -query_hash_pairs $query_hash_pairs]

    # -------------------------------------------------------
    # Loop through all objects of the specified type

    set obj_ctr 0
    set result ""
    db_foreach objects $sql {

	# Skip objects with empty object name
	if {"" == $object_name} { continue }

	# -------------------------------------------------------
	# Permissions

	# Denied access?
	if {$rest_otype_read_none_p} { continue }

	# Check permissions
	set read_p $rest_otype_read_all_p
	if {!$read_p} {
	    # This is one of the "custom" object types - check the permission:
	    # This may be quite slow checking 100.000 objects one-by-one...
	    eval "${rest_otype}_permissions $user_id $rest_oid view_p read_p write_p admin_p"
	}
	if {!$read_p} { continue }

	set url "$base_url/$rest_otype/$rest_oid"
	switch $format {
	    xml { 
		append result "<object_id id=\"$rest_oid\" href=\"$url\">[ns_quotehtml $object_name]</object_id>\n" 
	    }
	    json {
		set komma ",\n"
		if {0 == $obj_ctr} { set komma "" }
		set dereferenced_result ""
		if {"sencha" == $format_variant} {
		    foreach v $valid_vars {
			eval "set a $$v"
			regsub -all {\n} $a {\n} a
			regsub -all {\r} $a {} a
			append dereferenced_result ", \"$v\": \"[ns_quotehtml $a]\""
		    }
		}
		append result "$komma{\"id\": \"$rest_oid\", \"object_name\": \"[ns_quotehtml $object_name]\"$dereferenced_result}" 
	    }
	    html { 
		append result "<tr>
			<td>$rest_oid</td>
			<td><a href=\"$url?format=html\">$object_name</a>
		</tr>\n" 
	    }
	}
	incr obj_ctr
    }

    switch $format {
	html {
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    # Calculate the total number of objects
	    set total [db_string total "select count(*) from ($unlimited_sql) t" -default 0]
	    set result "{\"success\": true,\n\"total\": $total,\n\"message\": \"Data loaded\",\n\"data\": \[\n$result\n\]\n}"
	    doc_return 200 "text/plain" $result
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format: '$format'"
	     return
	}
    }
}


ad_proc -private im_rest_get_im_invoice_items {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls on invoice items.
} {
    ns_log Notice "im_rest_get_invoice_items: format=$format, user_id=$user_id, rest_otype=$rest_otype, query_hash=$query_hash_pairs"

    array set query_hash $query_hash_pairs
    set base_url "[im_rest_system_url]/intranet-rest"
    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = 'im_invoice'" -default 0]]
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "read"]


    # -------------------------------------------------------
    # Check if there is a where clause specified in the URL and validate the clause.
    set where_clause ""
    if {[info exists query_hash(query)]} { set where_clause $query_hash(query)}
    # Determine the list of valid columns for the object type
    set valid_vars {item_id item_name project_id invoice_id item_units item_uom_id price_per_unit currency sort_order item_type_id item_status_id description item_material_id}
    # Check that the query is a valid SQL where clause
    set valid_sql_where [im_rest_valid_sql -string $where_clause -variables $valid_vars]
    if {!$valid_sql_where} {
	im_rest_error -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
	return
    }
    if {"" != $where_clause} { set where_clause "and $where_clause" }

    # Select SQL: Pull out invoice_items.
    set sql "
	select	ii.item_id as rest_oid,
		ii.item_name as object_name,
		ii.invoice_id
	from	im_invoice_items ii
	where	1=1
		$where_clause
    "

    # Append pagination "LIMIT $limit OFFSET $start" to the sql.
    set unlimited_sql $sql
    append sql [im_rest_object_type_pagination_sql -query_hash_pairs $query_hash_pairs]


    set result ""
    db_foreach objects $sql {

	# Check permissions
	set read_p $rest_otype_read_all_p
	if {!$read_p} { set read_p [im_permission $user_id "view_finance"] }
	if {!$read_p} { im_invoice_permissions $user_id $invoice_id view_p read_p write_p admin_p }
	if {!$read_p} { continue }

	set url "$base_url/$rest_otype/$rest_oid"
	switch $format {
	    xml { append result "<object_id id=\"$rest_oid\" href=\"$url\">$rest_oid</object_id>\n" }
	    html { 
		append result "<tr>
			<td>$rest_oid</td>
			<td><a href=\"$url?format=html\">$object_name</a>
		</tr>\n" 
	    }
	    json { 
		append result "{object_id: $rest_oid}\n" 
	    }
	    default {}
	}
    }
	
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
    }

    return
}


ad_proc -private im_rest_get_im_hours {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls on timesheet hours
} {
    ns_log Notice "im_rest_get_hours: format=$format, user_id=$user_id, rest_otype=$rest_otype, query_hash=$query_hash_pairs"

    array set query_hash $query_hash_pairs
    set base_url "[im_rest_system_url]/intranet-rest"

    # Permissions:
    # A user can normally read only his own hours,
    # unless he's got the view_hours_all privilege or explicitely 
    # the perms on the im_hour object type
    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = 'im_hour'" -default 0]]
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "read"]
    if {[im_permission $user_id "view_hours_all"]} { set rest_otype_read_all_p 1 }

    set owner_perm_sql "and h.user_id = :user_id"
    if {$rest_otype_read_all_p} { set owner_perm_sql "" }

    # -------------------------------------------------------
    # Check if there is a where clause specified in the URL and validate the clause.
    set where_clause ""
    if {[info exists query_hash(query)]} { set where_clause $query_hash(query)}

    # Determine the list of valid columns for the object type
    set valid_vars {hour_id user_id project_id day hours days note private_note cost_id conf_object_id invoice_id material_id}

    # Check that the query is a valid SQL where clause
    set valid_sql_where [im_rest_valid_sql -string $where_clause -variables $valid_vars]
    if {!$valid_sql_where} {
	im_rest_error -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
	return
    }
    if {"" != $where_clause} { set where_clause "and $where_clause" }

    # Select SQL: Pull out hours.
    set sql "
	select	h.hour_id as rest_oid,
		'(' || im_name_from_user_id(user_id) || ', ' || 
			im_project_name_from_id(h.project_id) || 
			day::date || ', ' || ' - ' || 
			h.hours || ')' as object_name,
		h.*
	from	im_hours h
	where	1=1
		$owner_perm_sql
		$where_clause
    "

    # Append pagination "LIMIT $limit OFFSET $start" to the sql.
    set unlimited_sql $sql
    append sql [im_rest_object_type_pagination_sql -query_hash_pairs $query_hash_pairs]


    set result ""
    db_foreach objects $sql {
	set url "$base_url/$rest_otype/$rest_oid"
	switch $format {
	    xml { append result "<object_id id=\"$rest_oid\" href=\"$url\">$rest_oid</object_id>\n" }
	    html { 
		append result "<tr>
			<td>$rest_oid</td>
			<td><a href=\"$url?format=html\">$object_name</a>
		</tr>\n" 
	    }
	    json { append result "{object_id: $rest_oid}\n" }
	    default {}
	}
    }
	
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "\[$result\]\n"
	    return
	}
    }

    return
}



ad_proc -private im_rest_get_im_categories {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls on invoice items.
} {
    ns_log Notice "im_rest_get_categories: format=$format, user_id=$user_id, rest_otype=$rest_otype, query_hash=$query_hash_pairs"
    array set query_hash $query_hash_pairs
    set base_url "[im_rest_system_url]/intranet-rest"

    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = 'im_category'" -default 0]]
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "read"]

    # Get locate for translation
    set locale [lang::user::locale -user_id $user_id]

    # -------------------------------------------------------
    # Valid variables to return for im_category
    set valid_vars {category_id tree_sortkey category category_translated category_description category_type category_gif enabled_p parent_only_p aux_int1 aux_int2 aux_string1 aux_string2 sort_order}

    # -------------------------------------------------------
    # Check if there is a where clause specified in the URL and validate the clause.
    set where_clause ""
    if {[info exists query_hash(query)]} { set where_clause $query_hash(query)}


    # -------------------------------------------------------
    # Check if there are "valid_vars" specified in the HTTP header
    # and add these vars to the SQL clause
    set where_clause_list [list]
    foreach v $valid_vars {
        if {[info exists query_hash($v)]} { lappend where_clause_list "$v=$query_hash($v)" }
    }
    if {"" != $where_clause && [llength $where_clause_list] > 0} { append where_clause " and " }
    append where_clause [join $where_clause_list " and "]


    # Check that the query is a valid SQL where clause
    set valid_sql_where [im_rest_valid_sql -string $where_clause -variables $valid_vars]
    if {!$valid_sql_where} {
	im_rest_error -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
	return
    }
    if {"" != $where_clause} { set where_clause "and $where_clause" }

    # Select SQL: Pull out categories.
    set sql "
	select	c.category_id as rest_oid,
		c.category as object_name,
		im_category_path_to_category(c.category_id) as tree_sortkey,
		c.*
	from	im_categories c
	where	(c.enabled_p is null OR c.enabled_p = 't')
		$where_clause
	order by category_id
    "

    # Append pagination "LIMIT $limit OFFSET $start" to the sql.
    set unlimited_sql $sql
    append sql [im_rest_object_type_pagination_sql -query_hash_pairs $query_hash_pairs]

    set result ""
    set obj_ctr 0
    db_foreach objects $sql {

	set category_key "intranet-core.[lang::util::suggest_key $category]"
        set category_translated [lang::message::lookup $locale $category_key $category]

	# Check permissions
	set read_p $rest_otype_read_all_p
	set read_p 1
	if {!$read_p} { continue }

	set url "$base_url/$rest_otype/$rest_oid"
	switch $format {
	    xml { append result "<object_id id=\"$rest_oid\" href=\"$url\">$object_name</object_id>\n" }
	    html { 
		append result "<tr>
			<td>$rest_oid</td>
			<td><a href=\"$url?format=html\">$object_name</a>
		</tr>\n" 
	    }
	    json {
		set komma ",\n"
		if {0 == $obj_ctr} { set komma "" }
		set dereferenced_result ""
		foreach v $valid_vars {
			eval "set a $$v"
			regsub -all {\n} $a {\n} a
			regsub -all {\r} $a {} a
			append dereferenced_result ", \"$v\": \"[ns_quotehtml $a]\""
		}
		append result "$komma{\"id\": \"$rest_oid\", \"object_name\": \"[ns_quotehtml $object_name]\"$dereferenced_result}" 
	    }
	    default {}
	}
	incr obj_ctr
    }
	
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    # Deal with different JSON variants for different AJAX frameworks
	    set result "{\"success\": true,\n\"message\": \"Data loaded\",\n\"data\": \[\n$result\n\]\n}"
	    doc_return 200 "text/plain" $result
	    return
	}
    }
    return
}


ad_proc -private im_rest_get_im_dynfield_attributes {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls on dynfield attributes
} {
    ns_log Notice "im_rest_get_im_dynfield_attributes: format=$format, user_id=$user_id, rest_otype=$rest_otype, query_hash=$query_hash_pairs"
    array set query_hash $query_hash_pairs
    set base_url "[im_rest_system_url]/intranet-rest"

    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = 'im_dynfield_attribute'" -default 0]]
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "read"]

    # -------------------------------------------------------
    # Check if there is a where clause specified in the URL and validate the clause.
    set where_clause ""
    if {[info exists query_hash(query)]} { set where_clause $query_hash(query)}
    # Determine the list of valid columns for the object type
    set valid_vars {attribute_name object_type}
    # Check that the query is a valid SQL where clause
    set valid_sql_where [im_rest_valid_sql -string $where_clause -variables $valid_vars]
    if {!$valid_sql_where} {
	im_rest_error -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
	return
    }
    if {"" != $where_clause} { set where_clause "and $where_clause" }

    # Select SQL: Pull out values.
    set sql "
	select	
		aa.object_type||'.'||aa.attribute_name as rest_object_name,
		da.attribute_id as rest_oid,
		da.*,
		aa.*
	from	im_dynfield_attributes da,
		acs_attributes aa
	where	da.acs_attribute_id = aa.attribute_id
		$where_clause
	order by
		aa.object_type, 
		aa.attribute_name
    "

    # Append pagination "LIMIT $limit OFFSET $start" to the sql.
    set unlimited_sql $sql
    append sql [im_rest_object_type_pagination_sql -query_hash_pairs $query_hash_pairs]


    set result ""
    db_foreach objects $sql {

	# Check permissions
	set read_p $rest_otype_read_all_p
	if {!$read_p} { continue }

	set url "$base_url/$rest_otype/$rest_oid"
	switch $format {
	    xml { append result "<object_id id=\"$rest_oid\" href=\"$url\">$rest_object_name</object_id>\n" }
	    html { 
		append result "<tr>
			<td>$rest_oid</td>
			<td><a href=\"$url?format=html\">$rest_object_name</a>
		</tr>\n" 
	    }
	    json { append result "{object_id: $rest_oid, object_name: \"[ns_quotehtml $rest_object_name\"}\n" }
	    default {}
	}
    }
	
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    doc_return 200 "text/plain" "\[\n$result\n\]\n"
	    return
	}
    }

    return
}



# --------------------------------------------------------
# POST
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type {
    { -format "xml" }
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for POST rest calls to an object type - create a new object.
} {
    ns_log Notice "im_rest_post_object_type: format=$format, user_id=$user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"

    set base_url "[im_rest_system_url]/intranet-rest"

    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$rest_otype'" -default 0]]
    set rest_otype_write_all_p [im_object_permission -object_id $rest_otype_id -user_id $user_id -privilege "create"]

    # Get the content of the HTTP POST request
    set content [im_rest_get_content]

    # Switch to object specific procedures for handling new object creation
    # Check if the procedure exists.
    if {0 != [llength [info commands im_rest_post_object_type_$rest_otype]]} {
	
	set rest_oid [eval [list im_rest_post_object_type_$rest_otype \
		  -format $format \
		  -user_id $user_id \
		  -content $content \
	]]

	switch $format {
	    html { 
		set page_title "object_type: $rest_otype"
		doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Object ID</td></tr>
		<tr<td>$rest_oid</td></tr>
		</table>[im_footer]
		"
	    }
	    xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id id=\"$rest_oid\">$rest_oid</object_id>\n" }
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
    { -format_variant "" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for POST rest calls to an individual object:
    Update the specific object using a generic update procedure
} {
    ns_log Notice "im_rest_post_object: rest_otype=$rest_otype, rest_oid=$rest_oid, user_id=$user_id, format='$format', format_variant='$format_variant', query_hash=$query_hash_pairs"

    # Get the content of the HTTP POST request
    set content [im_rest_get_content]
    ns_log Notice "im_rest_post_object: content=$content"

    # Check if there is a customized version of this post handler
    if {0 != [llength [info commands im_rest_post_object_$rest_otype]]} {
	
	ns_log Notice "im_rest_post_object: found a customized POST handler for rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"
	set rest_oid [eval [list im_rest_post_object_$rest_otype \
		  -format $format \
		  -user_id $user_id \
		  -rest_otype $rest_otype \
		  -rest_oid $rest_oid \
		  -query_hash_pairs $query_hash_pairs \
		  -debug $debug \
		  -content $content \
	]]
	return
    }

    # Parse the HTTP content
    switch $format {
	json {
	    ns_log Notice "im_rest_post_object: going to parse json content=$content"
	    # {"id":8799,"email":"bbigboss@tigerpond.com","first_names":"Ben","last_name":"Bigboss"}
	    array set parsed_json [util::json::parse $content]
	    set json_list $parsed_json(_object_)
	    array set hash_array $json_list
	}
	default {
	    # store the key-value pairs into a hash array
	    ns_log Notice "im_rest_post_object: going to parse xml content=$content"
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
    }

    ns_log Notice "im_rest_post_object: hash_array=[array get hash_array]"


    # Update the object. This routine will return a HTTP error in case 
    # of a database constraint violation
    im_rest_object_type_update_sql \
	-rest_otype $rest_otype \
	-rest_oid $rest_oid \
	-hash_array [array get hash_array]

    # The update was successful - return a suitable message.
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Object ID</td></tr>
		<tr<td>$rest_oid</td></tr>
		</table>[im_footer]
	    "
	}
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id id=\"$rest_oid\">$rest_oid</object_id>\n" }
    }

}


# --------------------------------------------------------
# Auxillary functions
# --------------------------------------------------------



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
    if {$debug} { ns_log Notice "im_rest_authenticate: basic_auth=$basic_auth, basic_auth_username=$basic_auth_username, basic_auth_password=$basic_auth_password, basic_auth_user_id=$basic_auth_user_id, basic_auth_password_ok_p=$basic_auth_password_ok_p" }


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
	    return [im_rest_error -http_status 401 -message "No authentication found ('$auth_method')."] 
	}
    }

    if {"" == $auth_user_id} { set auth_user_id 0 }
    ns_log Notice "im_rest_authenticate: auth_method=$auth_method, auth_user_id=$auth_user_id"

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
# SQL Validator
# ----------------------------------------------------------------------

ad_proc -public im_rest_valid_sql {
    -string:required
    {-variables {} }
    {-debug 0}
} {
    Returns 1 if "where_clause" is a valid where_clause or 0 otherwise.
    The validator is based on applying a number of rules using a rule engine.
    Return the validation result if debug=1.
} {
    ns_log Notice "im_rest_valid_sql: vars=$variables, sql=$string"

    # An empty string is a valid SQL...
    if {"" == $string} { return 1 }

    # ------------------------------------------------------
    # Massage the string so that it suits the rule engine.

    # Add spaces around the string
    set string " $string "

    # Replace ocurrences of double (escaped) single-ticks with "quote"
    regsub -all {''} $string { quote } string

    # Add an extra space between all "funky" characters in the where clause
    regsub -all {([\>\<\=\!]+)} $string { \1 } string

    # Add an extra space around parentesis
    regsub -all {([\(\)]+)} $string { \1 } string

    # Add an extra space around kommas
    regsub -all {(,)} $string { \1 } string

    # Replace multiple spaces by a single one
    regsub -all {\s+} $string { } string


    # ------------------------------------------------------
    # Rules have a format LHS <- RHS (Left Hand Side <- Right Hand Side)
    set rules {
	cond {cond and cond}
	cond {cond or cond}
	cond {\( cond \)}
	cond {val = val}
	cond {val like val}
	cond {val > val}
	cond {val >= val}
	cond {val < val}
	cond {val <= val}
	cond {val <> val}
	cond {val != val}
	cond {val is null}
	cond {val is not null}
	cond {val in \( val \)}
	val  {val , val}
	val {[0-9]+}
	val {\'[^\']*\'}
    }

    # Add rules for every variable saying that it's a var.
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
		append debug_result "$lhs -> rhs=$rhs: '$string'\n"
	    }
	}
    }

    # Show the application of rules for debugging
    if {$debug} { return $debug_result }

    set string [string trim $string]
    if {"" == $string || "cond" == $string} { return 1 }
    return 0
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
<request>[ns_quotehtml $url]</request>
<message>$message</message>
</error>
"
    return
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
