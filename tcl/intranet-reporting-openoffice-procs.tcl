# /packages/intranet-reporting-openoffice/www/intranet-reporting-openoffice-procs.tcl
#
# Copyright (C) 2003 - 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Auxillary Functions
# ----------------------------------------------------------------------

ad_proc im_oo_tdom_explore {
    {-level 0}
    -node:required
} {
    Returns a hierarchical representation of a tDom tree
    representing the content of an OOoo document in this case.
} {
    set name [$node nodeName]
    set type [$node nodeType]

    set indent ""
    for {set i 0} {$i < $level} {incr i} { append indent "    " }

    set result "${indent}$name"
    if {$type == "TEXT_NODE"} { return "$result=[$node nodeValue]\n" }
    if {$type != "ELEMENT_NODE"} { return "$result\n" }

    # Create a key-value list of attributes behind the name of the tag
    append result " ("
    foreach attrib [$node attributes] {
        # Pull out the attributes identified by name:namespace.
        set attrib_name [lindex $attrib 0]
        set ns [lindex $attrib 1]
	#       set value [$node getAttribute "$ns:$attrib_name"]
        set value ""
        append result "'$ns':'$attrib_name'='$value', "
    }
    append result ")\n"

    # Recursively descend to child nodes
    foreach child [$node childNodes] {
        append result [im_invoice_oo_tdom_explore -parent $child -level [expr $level + 1]]
    }
    return $result
}


ad_proc im_oo_to_text {
    -node:required
} {
    Returns a hierarchical representation of a tDom tree
    representing the content of an OOoo document in this case.
} {
    set name [$node nodeName]
    set type [$node nodeType]

    set result ""
    if {$name == "text:tab"} { set result "\t" }
    if {$type == "TEXT_NODE"} { return "[$node nodeValue]\n" }

    # Recursively descend to child nodes
    foreach child [$node childNodes] {
        append result [im_oo_to_text -node $child]
    }
    return $result
}



ad_proc im_oo_page_notes {
    -page_node:required
} {
    Returns the "notes" from a slide page.
    The notes are used to store parameters.
} {
    # Go through all <text:p> nodes in all "presentation:notes" sections
    # (there should be only one)

    set notes_nodes [im_oo_select_nodes $page_node "presentation:notes"]
    set notes ""
    foreach notes_node $notes_nodes {
	append notes [im_oo_to_text -node $notes_node]
    }
    return $notes
}


ad_proc im_oo_select_nodes {
    node
    xpath
} {
    Returns a list of nodes that match the xpath.
} {
    set result [list]
    set name [$node nodeName]
    if {$name == $xpath} { lappend result $node }

    # Recursively descend to child nodes
    foreach child [$node childNodes] {
        set sub_result [im_oo_select_nodes $child $xpath]
	set result [concat $result $sub_result]
    }
    return $result
}




# ----------------------------------------------------------------------
# Handle HTTP GET requests
# ----------------------------------------------------------------------

ad_proc -private im_oo_call_get {
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
# Page processession procs
# -------------------------------------------------------

ad_proc im_oo_page_type_constant {
    -page_node:required
    -parameters:required
    {-list_sql ""}
    {-page_sql "" }
    {-page_name "undefined"}
} {
    A "constant" page contains only static contents.
    No substitution whatsoever will take place.

    @param page_node A tDom node for a draw:page node
    @param sqlAn SQL statement that should return a single row.
		The returned columns are available as variables
		in the template.
    @param repeat An optional SQL statement.
		The template will be repated for every "repeat"
		row with the repeat columns available as variables
		for the SQL statement.
    @param page_name The name of the slide 
		(for debugging purposes)

} {
    # Do nothing
}

ad_proc im_oo_page_type_static {
    -page_node:required
    -parameters:required
    {-list_sql ""}
    {-page_sql "" }
    {-page_name "undefined"}
} {
    @param page_node A tDom node for a draw:page node
    @param sqlAn SQL statement that should return a single row.
		The returned columns are available as variables
		in the template.
    @param repeat An optional SQL statement.
		The template will be repated for every "repeat"
		row with the repeat columns available as variables
		for the SQL statement.
    @param page_name The name of the slide 
		(for debugging purposes)

    The procedure will replace the template's @varname@
    variables by the values returned from the SQL statement.
} {
    # Write global parameters into local variables
    array set param_hash $parameters
    foreach var [array names param_hash] { set $var $param_hash($var) }

    # Check the page_sql statement and perform substitutions
    if {"" == $page_sql} { set page_sql "select 1 as one from dual" }
    if {[catch {
	eval [template::adp_compile -string $page_sql]
	set page_sql $__adp_output
	set page_sql [eval "set a \"$page_sql\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in page_sql statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    # Get the parent of the page
    set page_container [$page_node parentNode]

    # Convert the tDom tree into XML for rendering
    set template_xml [$page_node asXML]

    db_foreach page_sql $page_sql {

	# Replace placeholders in the OpenOffice template row with values
	if {[catch {
	    eval [template::adp_compile -string $template_xml]
	    set xml $__adp_output
	} err_msg]} {
	    ad_return_complaint 1 "<b>'$page_name': Error substituting variables</b>:<pre>$err_msg</pre>"
	    ad_script_abort
	}
	
	# Parse the new slide and insert into OOoo document
	set doc [dom parse $xml]
	set doc_doc [$doc documentElement]
	$page_container insertBefore $doc_doc $page_node
    }
	
    # remove the template node
    $page_container removeChild $page_node

}


ad_proc im_oo_page_type_sql_list {
    -page_node:required
    -parameters:required
    {-list_sql ""}
    {-page_sql "" }
    {-page_name "undefined"}
} {
    Takes as input a page node from the template with
    a table and a sql parameter in the "notes".
    It interprets the second row of the first table as
    a template and replaces this row with lines for 
    each of the SQL results.<br>
    Expected data structures: The "sql_list" page type 
    requires a table with two rows:
    <ul>
    <li>The title row and
    <li>The data row with @var_name@ variables
    <li>The page also needs to provide a "list_sql" argument
        in the page comments that will be used to create
        the data to be shown.
    </ul>
} {
    # ------------------------------------------------------------------
    # Constants & Arguments

    # Default number of table rows per page, may be overwritten by list_max_rows parameter
    set list_max_rows 10

    # Initialize counters
    set counters {}

    array set param_hash $parameters
    foreach var [array names param_hash] { set $var $param_hash($var) }

    if {"" == $list_sql} {
        ad_return_complaint 1 "<b>'$page_name': No list_sql specified in list page</b>."
        ad_script_abort
    }

    # Check the page_sql statement and perform substitutions
    if {"" == $page_sql} { set page_sql "select 1 as one from dual" }
    if {[catch {
	eval [template::adp_compile -string $page_sql]
	set page_sql $__adp_output
	set page_sql [eval "set a \"$page_sql\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in page_sql statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    # Perform substitutions on the list_sql statement
    if {[catch {
	eval [template::adp_compile -string $list_sql]
	set list_sql $__adp_output
	set list_sql [eval "set a \"$list_sql\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in SQL statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    # Get the parent of the page.
    # This is where we later have to add new pages as children.
    set page_container [$page_node parentNode]

    # Make a copy of the entire page.
    # We may have to generate more then one page
    set template_xml [$page_node asXML]

    # Set the "content row" variable to default values.
    # Normally the content row should contain the table row to be repeated...
    set content_row_node ""
    set content_row_xml ""
    set page_total_node ""
    set list_total_node ""

    # ------------------------------------------------------------------
    # Start processing the template

    # Loop through all repetitions
    db_foreach page_sql $page_sql {

	# Parse the template in order to create a "fresh" XML tree.
	# We are going to use this tree to insert rows into the first list.
        set page_doc [dom parse $template_xml]
        set page_root [$page_doc documentElement]

	set row_cnt 0
	set first_page_p 1
	db_foreach list_sql $list_sql {

	    # ------------------------------------------------------------------
	    # Setup a new page.
	    # Execute this code either if we are on the very first page or
	    # if we have to start a new page because of a long table.
	    if {$row_cnt >= $list_max_rows || $first_page_p} {

		# Close the previous page, add it to the Impress document and start a new one.
		if {0 == $first_page_p} {

		    # Remove the content_row
		    if {"" != $content_row_node} { $table_node removeChild $content_row_node }

		    # Remove the 4th line from the list in all but the last page
		    if {"" != $list_total_node} { $table_node removeChild $list_total_node }

		    # Render the new page with the additional table rows as XML
		    # and apply the OpenACS template engine in order to replace variables.
		    set page_xml [$page_root asXML]
		    if {[catch {
			eval [template::adp_compile -string $page_xml]
			set xml $__adp_output
		    } err_msg]} {
			ad_return_complaint 1 "<b>'$page_name': Error substituting variables</b>:<pre>$err_msg</pre>"
			ad_script_abort
		    }
		    
		    # Parse the new slide and insert into OOoo document
		    set result_doc [dom parse $xml]
		    set result_root [$result_doc documentElement]
		    $page_container insertBefore $result_root $page_node		
		}

		# Now we are not on the first page anymore...
		set first_page_p 0

		# Create a fresh XML tree again for the next page and reset the row counter
		set page_doc [dom parse $template_xml]
		set page_root [$page_doc documentElement]
		set row_cnt 0

		# Get the list of all tables in the page and count them
		set table_nodes [im_oo_select_nodes $page_root "table:table"]
		set table_node [lindex $table_nodes 0]
		set cnt [llength $table_nodes]
		if {$cnt == 0} { 
		    ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Did not found a table in the slide</b>" 
		    ad_script_abort
		}
		if {$cnt > 1} {
		    ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Found more the one table ($cnt)</b>:<br>
        <pre>[im_oo_tdom_explore -node $page_root]</pre>"
		    ad_script_abort
		}

		# Extract the 2nd row ("table:table-row" tag) that contains the 
		# content row to be repeated for every row of the list_sql
		set row_nodes [im_oo_select_nodes $table_node "table:table-row"]
		set content_row_node [lindex $row_nodes 1]
		set page_total_node [lindex $row_nodes 2]
		set list_total_node [lindex $row_nodes 3]
		set content_row_xml [$content_row_node asXML]
		if {"" == $content_row_node} {
		    ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Table only has one row</b>"
		    ad_script_abort
		}
	    }

	    # ------------------------------------------------------------------
	    # Update Counters
	    # Counters allow to sum up values in a list column.
	    # A counter consists of a list with two values:
	    #	- counter_var: The name of the counter variables
	    #	- counter_expr: A numeric expression that defines 
	    #	  the value to be added to the counter.
	    # The counter expression may contain any parameters 
	    # of the static page or values returned from the list_sql.
	    # The counter value can be used in the page_total and 
	    # total lines of a list just like a normal variable.
	    #
	    foreach counter $counters {
		set counter_var [lindex $counter 0]
		set counter_expr [lindex $counter 1]

		if {![info exists $counter_var]} { set $counter_var 0 }
		set val ""
		if {[catch {
		    set val [expr $counter_expr]
		} err_msg]} {
		    ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Error updating counter</b>:<br>
			Counter name: '$counter_var'<br>
			Counter expressions: '$counter_expr'<br>
			Error:<br><pre>$err_msg</pre>"
		    ad_script_abort
		}
		if {"" != $val && [string is double $val]} {
		    set $counter_var [expr "\$$counter_var + $val"]
		}
	    }

	    # ------------------------------------------------------------------
	    # Replace placeholders in the OpenOffice template row with values
	    if {[catch {
		eval [template::adp_compile -string $content_row_xml]
		set row_xml $__adp_output
	    } err_msg]} {
		ad_return_complaint 1 "<b>'$page_name': Error substituting row template variables</b>:
		<pre>$err_msg\n[im_oo_tdom_explore -node $content_row_node]</pre>"
		ad_script_abort
	    }

	    # Parse the new row and insert into OOoo document
	    set new_row_doc [dom parse $row_xml]
	    set new_row_root [$new_row_doc documentElement]
	    $table_node insertBefore $new_row_root $content_row_node

	    incr row_cnt
	}


	# ------------------------------------------------------------------
	# The last page of the list. This can also be the very first page with short lists.

	# Remove the content_row
	if {"" != $content_row_node} { $table_node removeChild $content_row_node }

	# Apply the OpenACS template engine
	set page_xml [$page_root asXML]
        if {[catch {
            eval [template::adp_compile -string $page_xml]
            set xml $__adp_output
        } err_msg]} {
            ad_return_complaint 1 "<b>'$page_name': Error substituting variables</b>:<pre>$err_msg</pre>"
            ad_script_abort
        }

        # Parse the new slide and insert into OOoo document
        set result_doc [dom parse $xml]
        set result_root [$result_doc documentElement]
        $page_container insertBefore $result_root $page_node

	# End looping through multiple pages
    }

    # remove the template page
    $page_container removeChild $page_node

}




ad_proc im_oo_page_type_gantt {
    -page_node:required
    -parameters:required
    {-list_sql ""}
    {-page_sql "" }
    {-page_name "undefined"}
} {
    @param page_node A tDom node for a draw:page node
    @param sqlAn SQL statement that should return a single row.
		The returned columns are available as variables
		in the template.
    @param repeat An optional SQL statement.
		The template will be repated for every "repeat"
		row with the repeat columns available as variables
		for the SQL statement.
    @param page_name The name of the slide 
		(for debugging purposes)

    The procedure will replace the template's @varname@
    variables by the values returned from the SQL statement.
} {
    # Write global parameters into local variables
    array set param_hash $parameters
    foreach var [array names param_hash] { set $var $param_hash($var) }

    # Check the page_sql statement and perform substitutions
    if {"" == $page_sql} { set page_sql "select 1 as one from dual" }
    if {[catch {
	eval [template::adp_compile -string $page_sql]
	set page_sql $__adp_output
	set page_sql [eval "set a \"$page_sql\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in page_sql statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    # Get the parent of the page
    set page_container [$page_node parentNode]

    # Convert the tDom tree into XML for rendering
    set template_xml [$page_node asXML]

    db_foreach page_sql $page_sql {

	# Replace placeholders in the OpenOffice template row with values
	if {[catch {
	    eval [template::adp_compile -string $template_xml]
	    set xml $__adp_output
	} err_msg]} {
	    ad_return_complaint 1 "<b>'$page_name': Error substituting variables</b>:<pre>$err_msg</pre>"
	    ad_script_abort
	}
	
	# Parse the new slide and insert into OOoo document
	set doc [dom parse $xml]
	set doc_doc [$doc documentElement]
	$page_container insertBefore $doc_doc $page_node
    }
	
    # remove the template node
    $page_container removeChild $page_node

}
