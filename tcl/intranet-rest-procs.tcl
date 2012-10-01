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
    Please see www.project-open.org/en/rest_version_history
    <li>2.1	(2012-03-18):	Added new report and now deprecating single object calls
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
    {-format "xml" }
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

    if {[info exists query_hash(format)]} { set format $query_hash(format) }

    # Determine the authenticated user_id. 0 means not authenticated.
    array set auth_hash [im_rest_authenticate -format $format -query_hash_pairs [array get query_hash]]
    if {0 == [llength [array get auth_hash]]} { return [im_rest_error -format $format -http_status 401 -message "Not authenticated"] }
    set auth_user_id $auth_hash(user_id)
    set auth_method $auth_hash(method)
    if {0 == $auth_user_id} { return [im_rest_error -format $format -http_status 401 -message "Not authenticated"] }

    # Default format are:
    # - "html" for cookie authentication
    # - "xml" for basic authentication
    # - "xml" for auth_token authentication
    switch $auth_method {
	basic { set format "xml" }
	cookie { set format "html" }
	token { set format "xml" }
	default { return [im_rest_error -format $format -http_status 401 -message "Invalid authentication method '$auth_method'."] }
    }
    # Overwrite default format with explicitely specified format in URL
    if {[info exists query_hash(format)]} { set format $query_hash(format) }
    set valid_formats {xml html json}
    if {[lsearch $valid_formats $format] < 0} { return [im_rest_error -format $format -http_status 406 -message "Invalid output format '$format'. Valid formats include {xml|html|json}."] }

    # Call the main request processing routine
    if {[catch {

	im_rest_call \
	    -method $http_method \
	    -format $format \
	    -user_id $auth_user_id \
	    -rest_otype $rest_otype \
	    -rest_oid $rest_oid \
	    -query_hash_pairs [array get query_hash]

    } err_msg]} {

	ns_log Notice "im_rest_call_get: im_rest_call returned an error: $err_msg"
	return [im_rest_error -format $format -http_status 500 -message "Internal error: [ns_quotehtml $err_msg]"]

    }
    
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
    if {[lsearch $valid_rest_otypes $rest_otype] < 0} { return [im_rest_error -format $format -http_status 406 -message "Invalid object_type '$rest_otype'. Valid object types include {im_project|im_company|...}."] }

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
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_dynfield_attribute {
			return [im_rest_get_im_dynfield_attribute \
				    -format $format \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_invoice_item {
			return [im_rest_get_im_invoice_item \
				    -format $format \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -rest_oid $rest_oid \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_hour {
			return [im_rest_get_im_hour \
				    -format $format \
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
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_dynfield_attribute {
			return [im_rest_get_im_dynfield_attributes \
				    -format $format \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_invoice_item {
			return [im_rest_get_im_invoice_items \
				    -format $format \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    im_hour {
			return [im_rest_get_im_hours \
				    -format $format \
				    -user_id $user_id \
				    -rest_otype $rest_otype \
				    -query_hash_pairs $query_hash_pairs \
				   ]
		    }
		    default {
			# Return query from the object rest_otype
			return [im_rest_get_object_type \
				    -format $format \
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

		if {[catch {
		    # POST with object_id => Update operation on an object
		    ns_log Notice "im_rest_call: Found a POST operation on object_type=$rest_otype with object_id=$rest_oid"
		    im_rest_post_object \
			-format $format \
			-user_id $user_id \
			-rest_otype $rest_otype \
			-rest_oid $rest_oid \
			-query_hash_pairs $query_hash_pairs

		} err_msg]} {
		    ns_log Error "im_rest_call: Error during POST operation: $err_msg"
		}

	    } else {

		if {[catch {
		    # POST without object_id => Update operation on the "factory" object_type
		    ns_log Notice "im_rest_call: Found a POST operation on object_type=$rest_otype"
		    im_rest_post_object_type \
			-format $format \
			-user_id $user_id \
			-rest_otype $rest_otype \
			-query_hash_pairs $query_hash_pairs
		    
		} err_msg]} {
		    ns_log Error "im_rest_call: Error during POST operation: $err_msg"
		}
	    }
	}
	DELETE {
	    # Is the post operation performed on a particular object or on the object_type?
	    if {"" != $rest_oid && 0 != $rest_oid} {

		if {[catch {
		    # DELETE with object_id => delete operation
		    ns_log Notice "im_rest_call: Found a DELETE operation on object_type=$rest_otype with object_id=$rest_oid"
		    im_rest_delete_object \
			-format $format \
			-user_id $user_id \
			-rest_otype $rest_otype \
			-rest_oid $rest_oid \
			-query_hash_pairs $query_hash_pairs

		} err_msg]} {
		    ns_log Error "im_rest_call: Error during DELETE operation: $err_msg"
		}

	    } else {
		# DELETE without object_id is not allowed - you can only destroy a known object
		ns_log Error "im_rest_call: You have to specify an object to DELETE."
	    }
	}

	default {
	    return [im_rest_error -format $format -http_status 400 -message "Unknown HTTP request '$method'. Valid requests include {GET|POST|PUT|DELETE}."]
	}
    }
}


ad_proc -private im_rest_page {
    { -rest_otype "index" }
    { -format "xml" }
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

    # Permissions for the object type
    set current_user_id $user_id
    set rest_otype_read_none_p 0
    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$rest_otype'" -default 0]]
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $current_user_id -privilege "read"]
    if {!$rest_otype_read_all_p} {
        # There are "view_xxx_all" permissions allowing a user to see all objects:
        switch $rest_otype {
            bt_bug              { }
            im_company          { set rest_otype_read_all_p [im_permission $current_user_id "view_companies_all"] }
            im_cost             { set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
            im_conf_item        { set rest_otype_read_all_p [im_permission $current_user_id "view_conf_items_all"] }
            im_invoices         { set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
            im_project          { set rest_otype_read_all_p [im_permission $current_user_id "view_projects_all"] }
            im_user_absence     { set rest_otype_read_all_p [im_permission $current_user_id "view_absences_all"] }
            im_office           { set rest_otype_read_all_p [im_permission $current_user_id "view_offices_all"] }
            im_ticket           { set rest_otype_read_all_p [im_permission $current_user_id "view_tickets_all"] }
            im_timesheet_task   { set rest_otype_read_all_p [im_permission $current_user_id "view_timesheet_tasks_all"] }
            im_timesheet_invoices { set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
            im_trans_invoices   { set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
            im_translation_task { }
            user                { }
            default {
                # No read permissions?
                # Well, no object type except the ones above has a custom procedure,
                # so we can deny access here:
                set rest_otype_read_none_p 1
                ns_log Notice "im_rest_get_object_type: Denying access to $rest_otype"
            }
        }
    }

    # Aggregate permissions into a single read_p
    set read_p $rest_otype_read_all_p
    if {!$read_p} {
	catch {
	    eval "${rest_otype}_permissions $current_user_id $rest_oid view_p read_p write_p admin_p"
	}
    }
    if {$rest_otype_read_none_p} { set read_p 0 }
    if {!$read_p} {
	return [im_rest_error -format $format -http_status 401 -message "No permission on object '$rest_oid' of type '$rest_otype'."]
    }


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
		set result_hash($var) $val
	    }
	}
    }
    db_release_unused_handles

    if {{} == [array get result_hash]} { 
	return [im_rest_error -format $format -http_status 404 -message "Generic: Did not find object '$rest_otype' with the ID '$rest_oid'."] 
    }

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
	    doc_return 200 "text/html" "{object_type: \"$rest_otype\",\n$result\n}" 
	}
	default {
	     ad_return_complaint 1 "Invalid format1: '$format'"
	}
    }
  
    ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"

}


ad_proc -private im_rest_get_im_category {
    { -format "xml" }
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

    if {{} == [array get result_hash]} { return [im_rest_error -format $format -http_status 404 -message "Category: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    doc_return 200 "text/html" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format2: '$format'"
	}
    }
  
    # ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"
    return

}


ad_proc -private im_rest_get_im_dynfield_attribute {
    { -format "xml" }
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

    if {{} == [array get result_hash]} { return [im_rest_error -format $format -http_status 404 -message "Dynfield Attribute: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    doc_return 200 "text/html" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format3: '$format'"
	}
    }
  
    return

}

ad_proc -private im_rest_get_im_invoice_item {
    { -format "xml" }
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

    if {{} == [array get result_hash]} { return [im_rest_error -format $format -http_status 404 -message "Invoice Item: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    doc_return 200 "text/html" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format4: '$format'"
	}
    }
  
    # ad_return_complaint 1 "<pre>sql=$sql\nhash=[join [array get result_hash] "\n"]</pre>"
    return

}

ad_proc -private im_rest_get_im_hour {
    { -format "xml" }
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

    if {{} == [array get result_hash]} { return [im_rest_error -format $format -http_status 404 -message "Timesheet Hour: Did not find object '$rest_otype' with the ID '$rest_oid'."] }

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
	    doc_return 200 "text/html" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format5: '$format'"
	}
    }
  
    return

}


ad_proc -private im_rest_get_object_type {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for GET rest calls on a whole object type -
    mapped to queries on the specified object type
} {
    set current_user_id $user_id
    ns_log Notice "im_rest_get_object_type: format=$format, user_id=$current_user_id, rest_otype=$rest_otype, rest_oid=$rest_oid, query_hash=$query_hash_pairs"
    array set query_hash $query_hash_pairs
    set rest_otype_id [util_memoize [list db_string otype_id "select object_type_id from im_rest_object_types where object_type = '$rest_otype'" -default 0]]
    set rest_columns [im_rest_get_rest_columns $query_hash_pairs]
    foreach col $rest_columns { set rest_columns_hash($col) 1 }

    # -------------------------------------------------------
    # Get some more information about the current object type
    db_1row rest_otype_info "
	select	*
	from	acs_object_types
	where	object_type = :rest_otype
    "

# !!!
    if {"" == $table_name} {
	im_rest_error -format $format -http_status 500 -message "Invalid DynField configuration: Object type '$rest_otype' doesn't have a table_name specified in table acs_object_types."
    }

    set base_url "[im_rest_system_url]/intranet-rest"

    # -------------------------------------------------------
    # Check for generic permissions to read all objects of this type
    set rest_otype_read_all_p [im_object_permission -object_id $rest_otype_id -user_id $current_user_id -privilege "read"]

    # Deny completely access to the object type?
    set rest_otype_read_none_p 0

    if {!$rest_otype_read_all_p} {
	# There are "view_xxx_all" permissions allowing a user to see all objects:
	switch $rest_otype {
	    bt_bug		{ }
	    im_company		{ set rest_otype_read_all_p [im_permission $current_user_id "view_companies_all"] }
	    im_cost		{ set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
	    im_conf_item	{ set rest_otype_read_all_p [im_permission $current_user_id "view_conf_items_all"] }
	    im_invoices		{ set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
	    im_project		{ set rest_otype_read_all_p [im_permission $current_user_id "view_projects_all"] }
	    im_user_absence	{ set rest_otype_read_all_p [im_permission $current_user_id "view_absences_all"] }
	    im_office		{ set rest_otype_read_all_p [im_permission $current_user_id "view_offices_all"] }
	    im_ticket		{ set rest_otype_read_all_p [im_permission $current_user_id "view_tickets_all"] }
	    im_timesheet_task	{ set rest_otype_read_all_p [im_permission $current_user_id "view_timesheet_tasks_all"] }
	    im_timesheet_invoices { set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
	    im_trans_invoices	{ set rest_otype_read_all_p [im_permission $current_user_id "view_finance"] }
	    im_translation_task	{ }
	    user		{ }
	    default { 
		# No read permissions? 
		# Well, no object type except the ones above has a custom procedure,
		# so we can deny access here:
		set rest_otype_read_none_p 1
		ns_log Notice "im_rest_get_object_type: Denying access to $rest_otype"
	    }
	}
    }

    # -------------------------------------------------------
    # Check if there is a where clause specified in the URL
    # and validate the clause.
    set where_clause ""
    set where_clause_list [list]
    set where_clause_unchecked_list [list]
    if {[info exists query_hash(query)]} { set where_clause $query_hash(query)}
    if {"" != $where_clause} { lappend where_clause_list $where_clause }
    ns_log Notice "im_rest_get_object_type: where_clause=$where_clause"


    # -------------------------------------------------------
    # Check if there are "valid_vars" specified in the HTTP header
    # and add these vars to the SQL clause
    set valid_vars [util_memoize [list im_rest_object_type_columns -rest_otype $rest_otype]]
    foreach v $valid_vars {
	if {[info exists query_hash($v)]} { lappend where_clause_list "$v=$query_hash($v)" }
    }

    # -------------------------------------------------------
    # Transform the database table to deal with exceptions
    #
    switch $rest_otype {
	user - person - party {
	    set table_name "(
		select	*
		from	users u, parties pa, persons pe
		where	u.user_id = pa.party_id and u.user_id = pe.person_id and
			u.user_id in (
				SELECT  o.object_id
				FROM    acs_objects o,
				        group_member_map m,
				        membership_rels mr
				WHERE   m.member_id = o.object_id AND
				        m.group_id = acs__magic_object_id('registered_users'::character varying) AND
				        m.rel_id = mr.rel_id AND
				        m.container_id = m.group_id AND
				        m.rel_type::text = 'membership_rel'::text AND
				        mr.member_state = 'approved'
			)
		)"
	}
	file_storage_object {
	    # file storage object needs additional security
	    lappend where_clause_unchecked_list "'t' = acs_permission__permission_p(o.object_id, $current_user_id, 'read')"
	}
	im_ticket {
	    # Testing per-ticket permissions
	    set read_sql [im_ticket_permission_read_sql -user_id $current_user_id]
	    lappend where_clause_unchecked_list "o.object_id in ($read_sql)"
	}
    }

    # Check that the where_clause elements are valid SQL statements
    foreach where_clause $where_clause_list {
	set valid_sql_where [im_rest_valid_sql -string $where_clause -variables $valid_vars]
	if {!$valid_sql_where} {
	    im_rest_error -format $format -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
	    return
	}
    }

    # Build the complete where clause
    set where_clause_list [concat $where_clause_list $where_clause_unchecked_list]
    if {"" != $where_clause && [llength $where_clause_list] > 0} { append where_clause " and " }
    append where_clause [join $where_clause_list " and\n\t\t"]
    if {"" != $where_clause} { set where_clause "and $where_clause" }
    # ad_return_complaint 1 "<pre>$where_clause</pre>"


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

    # Append sorting "ORDER BY" clause to the sql.
    append sql [im_rest_object_type_order_sql -query_hash_pairs $query_hash_pairs]

    # Append pagination "LIMIT $limit OFFSET $start" to the sql.
    set unlimited_sql $sql
    append sql [im_rest_object_type_pagination_sql -query_hash_pairs $query_hash_pairs]

#    ad_return_complaint 1 "<pre>$sql</pre>"


    # -------------------------------------------------------
    # Loop through all objects of the specified type
    set obj_ctr 0
    set result ""
    db_foreach objects $sql {

	# Skip objects with empty object name
	if {"" == $object_name} { 
	    ns_log Error "im_rest_get_object_type: Skipping object #$object_id because object_name is empty."
	    continue
	}

	# -------------------------------------------------------
	# Permissions

	# Denied access?
	if {$rest_otype_read_none_p} { continue }

	# Check permissions
	set read_p $rest_otype_read_all_p

	if {!$read_p} {
	    # This is one of the "custom" object types - check the permission:
	    # This may be quite slow checking 100.000 objects one-by-one...
	    catch {
		eval "${rest_otype}_permissions $current_user_id $rest_oid view_p read_p write_p admin_p"
	    }
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
		foreach v $valid_vars {

		    # Skip the column unless it is explicitely mentioned in the rest_columns list
		    if {{} != $rest_columns} { if {![info exists rest_columns_hash($v)]} { continue } }

		    eval "set a $$v"
		    regsub -all {\n} $a {\n} a
		    regsub -all {\r} $a {} a
		    append dereferenced_result ", \"$v\": \"[ns_quotehtml $a]\""
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
	    im_rest_doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  
	    im_rest_doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    # Calculate the total number of objects
	    set total [db_string total "select count(*) from ($unlimited_sql) t" -default 0]
	    set result "{\"success\": true,\n\"total\": $total,\n\"message\": \"im_rest_get_object_type: Data loaded\",\n\"data\": \[\n$result\n\]\n}"
	    im_rest_doc_return 200 "text/html" $result
	    return
	}
	default {
	     ad_return_complaint 1 "Invalid format5: '$format'"
	     return
	}
    }
}


ad_proc -private im_rest_get_im_invoice_items {
    { -format "xml" }
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
	im_rest_error -format $format -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
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
	    im_rest_doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    im_rest_doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    im_rest_doc_return 200 "text/html" "{object_type: \"$rest_otype\",\n$result\n}"
	    return
	}
    }

    return
}


ad_proc -private im_rest_get_im_hours {
    { -format "xml" }
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
	im_rest_error -format $format -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
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
	    im_rest_doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    im_rest_doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    im_rest_doc_return 200 "text/html" "\[$result\]\n"
	    return
	}
    }

    return
}


ad_proc -private im_rest_get_im_categories {
    { -format "xml" }
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
	im_rest_error -format $format -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
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

    set value ""
    set result ""
    set obj_ctr 0
    db_foreach objects $sql {

	set category_key "intranet-core.[lang::util::suggest_key $category]"
        set category_translated [lang::message::lookup $locale $category_key $category]

        # Calculate indent
        set indent [expr [string length tree_sortkey] - 8]
        # for {set i 0} {$i < $indent} {incr i} { set category_translated "&nbsp;$category_translated" }

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
	    im_rest_doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	    return
	}
	xml {  
	    im_rest_doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	    return
	}
	json {  
	    # Deal with different JSON variants for different AJAX frameworks
	    set result "{\"success\": true,\n\"message\": \"im_rest_get_im_categories: Data loaded\",\n\"data\": \[\n$result\n\]\n}"
	    im_rest_doc_return 200 "text/html" $result
	    return
	}
    }
    return
}


ad_proc -private im_rest_get_im_dynfield_attributes {
    { -format "xml" }
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
	im_rest_error -format $format -http_status 403 -message "The specified query is not a valid SQL where clause: '$where_clause'"
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
	    im_rest_doc_return 200 "text/html" "
		[im_header $page_title [im_rest_header_extra_stuff]][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>object_id</td><td class=rowtitle>Link</td></tr>$result
		</table>[im_footer]
	    " 
	}
	xml {  
	    im_rest_doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_list>\n$result</object_list>\n" 
	}
	json {  
	    im_rest_doc_return 200 "text/html" "\[\n$result\n\]\n"
	}
    }

    return
}



# --------------------------------------------------------
# POST
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type {
    { -format "xml" }
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
	
	ns_log Notice "im_rest_post_object_type: Before calling im_rest_post_object_type_$rest_otype"
	array set hash_array [eval [list im_rest_post_object_type_$rest_otype \
		  -format $format \
		  -user_id $user_id \
		  -content $content \
		  -rest_otype $rest_otype \
	]]

	# Extract the object's id from the return array and write into object_id in case a client needs the info
	if {![info exists hash_array(rest_oid)]} {
	    # Probably after an im_rest_error
	    ns_log Error "im_rest_post_object_type: Didn't find hash_array(rest_oid): This should never happened"
	}
	set rest_oid $hash_array(rest_oid)
	set hash_array(object_id) $rest_oid
	ns_log Notice "im_rest_post_object_type: After calling im_rest_post_object_type_$rest_otype: rest_oid=$rest_oid, hash_array=[array get hash_array]"

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
	    json {
		# Return a JSON structure with all fields of the object.
		set data_list [list]
		foreach key [array names hash_array] {
		    set value $hash_array($key)
		    lappend data_list "\"$key\": \"[im_quotejson $value]\""
		}
		
		set data "\[{[join $data_list ", "]}\]"
		set result "{\"success\": \"true\",\"message\": \"Object updated\",\"data\": $data}"
		doc_return 200 "text/html" $result
	    }
	    xml {  
		doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id id=\"$rest_oid\">$rest_oid</object_id>\n" 
	    }
	    default {
		ad_return_complaint 1 "Invalid format6: '$format'"
	    }
	}

    } else {
	ns_log Notice "im_rest_post_object_type: Create for '$rest_otype' not implemented yet"
	im_rest_error -format $format -http_status 404 -message "Object creation for object type '$rest_otype' not implemented yet."
    }
    return
}

ad_proc -private im_rest_delete_object {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for DELETE rest calls to an individual object:
    Update the specific object using a generic update procedure
} {
    ns_log Notice "im_rest_delete_object: rest_otype=$rest_otype, rest_oid=$rest_oid, user_id=$user_id, format='$format', query_hash=$query_hash_pairs"

    # Get the content of the HTTP DELETE request
    set content [im_rest_get_content]
    ns_log Notice "im_rest_delete_object: content=$content"

    # Only administrators have the right to DELETE
    if {![im_user_is_admin_p $user_id]} {
	im_rest_error -format $format -http_status 401 -message "User #$user_id is not a system administrator. You need admin rights to perform a DELETE."
    }

    # Deal with certain subtypes
    switch $rest_otype {
	im_ticket {
	    set nuke_otype "im_project"
	}
	default {
	    set nuke_otype $rest_otype
	}
    }

    if {[catch {
	set nuke_tcl [list "${nuke_otype}_nuke" -current_user_id $user_id $rest_oid]
	ns_log Notice "im_rest_delete_object: nuke_tcl=$nuke_tcl"
	eval $nuke_tcl

    } err_msg]} {
	im_rest_error -format $format -http_status 404 -message "DELETE for object #$rest_oid of type '$rest_otype' returned an error: $err_msg"
    }

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
	json {
	    # Empty data: The empty array is necessary for Sencha in order to call callbacks
	    # without error. However, adding data here will create empty records in the store later,
	    # so the array needs to be empty.
	    set data_list [list]
	    foreach key [array names hash_array] {
		set value $hash_array($key)
		lappend data_list "\"$key\": \"[im_quotejson $value]\""
	    }

	    set data "\[{[join $data_list ", "]}\]"
	    set result "{\"success\": \"true\",\"message\": \"Object updated\",\"data\": $data}"
	    doc_return 200 "text/html" $result
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id id=\"$rest_oid\">$rest_oid</object_id>\n" 
	}
    }
    return
}

ad_proc -private im_rest_post_object {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid 0 }
    { -query_hash_pairs {} }
    { -debug 0 }
} {
    Handler for POST rest calls to an individual object:
    Update the specific object using a generic update procedure
} {
    ns_log Notice "im_rest_post_object: rest_otype=$rest_otype, rest_oid=$rest_oid, user_id=$user_id, format='$format', query_hash=$query_hash_pairs"

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
    # Extract a key-value list of variables from XML or JSON POST request
    array set hash_array [im_rest_parse_xml_json_content -rest_otype $rest_otype -format $format -content $content]

    # Audit + Callback before updating the object
    im_audit -user_id $user_id -object_type $rest_otype -object_id $rest_oid -action before_update

    # Update the object. This routine will return a HTTP error in case 
    # of a database constraint violation
    ns_log Notice "im_rest_post_object: Before im_rest_object_type_update_sql"
    im_rest_object_type_update_sql \
	-format $format \
	-rest_otype $rest_otype \
	-rest_oid $rest_oid \
	-hash_array [array get hash_array]
    ns_log Notice "im_rest_post_object: After im_rest_object_type_update_sql"

    # Audit + Callback after updating the object
    im_audit -user_id $user_id -object_type $rest_otype -object_id $rest_oid -action after_update


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
	json {
	    # Empty data: The empty array is necessary for Sencha in order to call callbacks
	    # without error. However, adding data here will create empty records in the store later,
	    # so the array needs to be empty.
	    set data_list [list]
	    foreach key [array names hash_array] {
		set value $hash_array($key)
		lappend data_list "\"$key\": \"[im_quotejson $value]\""
	    }

	    set data "\[{[join $data_list ", "]}\]"
	    set result "{\"success\": \"true\",\"message\": \"Object updated\",\"data\": $data}"
	    doc_return 200 "text/html" $result
	}
	xml {  
	    doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id id=\"$rest_oid\">$rest_oid</object_id>\n" 
	}
    }
    return
}

