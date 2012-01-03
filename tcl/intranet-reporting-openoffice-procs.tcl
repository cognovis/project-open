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

	# execute the SQL statement in order to load variables
	if {[catch {
	    db_1row "sql_statement $page_name" $sql
	} err_msg]} {
	    ad_return_complaint 1 "<b>Error executing SQL statement in slide '$page_name'</b>:<pre>$err_msg</pre>"
	    ad_script_abort
	}
	
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

    set date_format "YYYY-MM-DD"
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



    # ------------------------------------------------------------------
    # Search for the content row in the template

    # Get the list of all tables in slide
    set table_nodes [im_oo_select_nodes $page_node "table:table"]

    set cnt 0
    set table_node ""
    foreach node $table_nodes { 
	set table_node $node
	incr cnt 
    }
    if {$cnt == 0} { 
	ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Did not found a table in the slide</b>" 
	ad_script_abort
    }
    if {$cnt > 1} {
	ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Found more the one table ($cnt)</b>:<br>
        <pre>[im_oo_tdom_explore -node $page_root]</pre>"
	    ad_script_abort
    }
    
    # Seach for the 2nd row ("table:table-row" tag) that contains the 
    # content row to be repeated for every row of the list_sql
    set row_nodes [im_oo_select_nodes $table_node "table:table-row"]
    set content_row_node ""
    set row_count 0
    foreach row_node $row_nodes {
	set row_as_list [$row_node asList]
	if {1 == $row_count} { set content_row_node $row_node }
	incr row_count
    }
    # ad_return_complaint 1 "<pre>[im_oo_tdom_explore -node $content_row_node]</pre>"
    
    if {"" == $content_row_node} {
	ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Table only has one row</b>"
	ad_script_abort
    }
    
    # Convert the tDom tree into XML for rendering
    set content_row_xml [$content_row_node asXML]




    # ------------------------------------------------------------------
    # Start processing the template

    # Loop through all repetitions
    db_foreach page_sql $page_sql {

	# Parse the template in order to create a "fresh" XML tree
        set page_doc [dom parse $template_xml]
        set page_root [$page_doc documentElement]

	# Get the list of all tables in the instance
	set table_nodes [im_oo_select_nodes $page_root "table:table"]
	set cnt 0
	set table_node ""
	foreach node $table_nodes { 
	    set table_node $node
	    incr cnt 
	}

	# Seach for the 2nd row again
	set row_nodes [im_oo_select_nodes $table_node "table:table-row"]
	set content_row_node ""
	set row_count 0
	foreach row_node $row_nodes {
	    set row_as_list [$row_node asList]
	    if {1 == $row_count} { set content_row_node $row_node }
	    incr row_count
	}

	set table_body_xml ""
	db_foreach list_sql $list_sql {
	    # Replace placeholders in the OpenOffice template row with values
	    
	    if {[catch {
		ns_log Notice "content_row_xml=$content_row_xml"
		eval [template::adp_compile -string $content_row_xml]
		set row_xml $__adp_output
	    } err_msg]} {
		ad_return_complaint 1 "<b>'$page_name': Error substituting row template variables</b>:<pre>$err_msg\n[im_oo_tdom_explore -node $content_row_node]</pre>"
		ad_script_abort
	    }
	    
	    # Parse the new row and insert into OOoo document
	    set new_row_doc [dom parse $row_xml]
	    set new_row_root [$new_row_doc documentElement]
	    $table_node insertBefore $new_row_root $content_row_node
	}

	# remove the template node
	#$table_node removeChild $content_row_node

        # Replace placeholders in the OpenOffice template row with values
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

	# End looping through repetitions
    }

    # remove the template page
    $page_container removeChild $page_node

}

