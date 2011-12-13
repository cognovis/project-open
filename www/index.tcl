# /packages/intranet-reporting-openoffice/www/report-portfolio.tcl
#
# Copyright (C) 2003 - 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Return a HTML or OpenOffice document with a list of programs
    and their parameters.
    @author frank.bergmann@project-open.com
} {
    { template "avance-accumulado-sor.odp" }
    { odt_filename "avance-accumulado-sor.odp" }
    { output_format "odp" }
    { report_start_date "2011-10-01" }
    { report_end_date "2011-11-01" }
    { report_customer_id "" }
    { report_program_id "" }
    { report_project_type_id "" }
    { report_area_id "" }
}


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
    {-sql ""}
    {-repeat "" }
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
    {-sql ""}
    {-repeat "" }
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

    # Check the sql statement and perform substitutions
    if {"" == $sql} { set sql "select 1 as one from dual" }
    if {[catch {
	eval [template::adp_compile -string $sql]
	set sql $__adp_output
	set sql [eval "set a \"$sql\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in SQL statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    # Check the repeat statement and perform substitutions
    if {"" == $repeat} { set repeat "select 1 as one from dual" }
    if {[catch {
	eval [template::adp_compile -string $repeat]
	set repeat $__adp_output
	set repeat [eval "set a \"$repeat\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in REPEAT statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    # Get the parent of the page
    set page_container [$page_node parentNode]

    # Convert the tDom tree into XML for rendering
    set template_xml [$page_node asXML]

    db_foreach repeat $repeat {

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
    {-sql ""}
    {-repeat "" }
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
    <li>The page also needs to provide a "sql" argument
        in the page comments that will be used to create
        the data to be shown.
    </ul>
} {
    # Constants
    set date_format "YYYY-MM-DD"
    array set param_hash $parameters
    foreach var [array names param_hash] { set $var $param_hash($var) }

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
        <pre>[im_oo_tdom_explore -node $page_node]</pre>"
	ad_script_abort
    }

    # Seach for the 2nd table:table-row tag that contains the template
    set row_nodes [im_oo_select_nodes $table_node "table:table-row"]
    set template_row_node ""
    set row_count 0
    foreach row_node $row_nodes {
        set row_as_list [$row_node asList]
        if {1 == $row_count} { set template_row_node $row_node }
        incr row_count
    }

#    ad_return_complaint 1 "<pre>[im_oo_tdom_explore -node $template_row_node]</pre>"

    if {"" == $template_row_node} {
        ad_return_complaint 1 "<b>im_oo_page_type_sql_list '$page_name': Table only has one row</b>"
        ad_script_abort
    }

    # Convert the tDom tree into XML for rendering
    set template_row_xml [$template_row_node asXML]

    # Perform substitutions on the SQL statement
    if {[catch {
	eval [template::adp_compile -string $sql]
	set sql $__adp_output
	set sql [eval "set a \"$sql\""]
    } err_msg]} {
        ad_return_complaint 1 "<b>'$page_name': Error substituting variables in SQL statement</b>:<pre>$err_msg</pre>"
        ad_script_abort
    }

    set table_body_xml ""
    db_foreach sql $sql {
	# Replace placeholders in the OpenOffice template row with values

	if {[catch {
	    ns_log Notice "template_row_xml=$template_row_xml"
	    eval [template::adp_compile -string $template_row_xml]
	    set row_xml $__adp_output
	} err_msg]} {
	    ad_return_complaint 1 "<b>'$page_name': Error substituting row template variables</b>:<pre>$err_msg\n[im_oo_tdom_explore -node $template_row_node]</pre>"
	    ad_script_abort
	}

	# Parse the new row and insert into OOoo document
	set row_doc [dom parse $row_xml]
	set new_row [$row_doc documentElement]
	$table_node insertBefore $new_row $template_row_node
    }

    # remove the template node
    $table_node removeChild $template_row_node

}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# Get user parameters
set user_id [ad_maybe_redirect_for_registration]
set user_locale [lang::user::locale]
set date_format "YYYY-MM-DD"

if {0} {
    ad_return_complaint 1 "<li>[lang::message::lookup $locale intranet-invoices.lt_You_need_to_specify_a]"
    return
}

set page_title [lang::message::lookup "" intranet-reporting-openoffice.Program_Overview "Program Overview"]
set context [list $page_title]
set sub_navbar_html ""
set left_navbar_html ""

# OpenOffice sometimes converts a normal dash into a "long dash"
set long_dash [format "%c" 8211]


# ---------------------------------------------------------------
# Determine system pathes
# ---------------------------------------------------------------

# Determine the template
set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]

set template_base_path "$serverroot/packages/intranet-reporting-openoffice/templates"
# set template_base_path "$serverroot/filestorage/home"

set template_path "$template_base_path/$template"
if {![file isfile $template_path] || ![file readable $template_path]} {
    ad_return_complaint "Unknown Template" "
        <li>Template '$template_path' doesn't exist or is not readable
        for the web server. Please notify your system administrator."
    ad_script_abort
}

# Create a temporary directory for our contents
set odt_tmp_path [ns_tmpnam]
ns_mkdir $odt_tmp_path



# ---------------------------------------------------------------
# Unzip the ODP template, update the "content.xml" file and zip again.
# ---------------------------------------------------------------

set odt_zip "${odt_tmp_path}.odt"
set odt_content "${odt_tmp_path}/content.xml"
set odt_styles "${odt_tmp_path}/styles.xml"

ns_cp $template_path $odt_zip

# Unzip the odt into the temorary directory
exec unzip -d $odt_tmp_path $odt_zip

# Read the content.xml file
set file [open $odt_content]
fconfigure $file -encoding "utf-8"
set odt_template_content [read $file]
close $file

# Parse the template XML document into a tree
set odt_doc [dom parse $odt_template_content]
set odt_root [$odt_doc documentElement]

# Get the container tag that contains various pages
# and the list of pages in the document
set odt_page_container_node [$odt_root selectNodes "//office:presentation"]
set odt_page_template_nodes [$odt_root selectNodes "//draw:page"]


# ---------------------------------------------------------------
# Loop through all pages
# and process each page depending on its type
# ---------------------------------------------------------------

array set parameter_hash {}
set parameter_hash(report_start_date) $report_start_date
set parameter_hash(report_end_date) $report_end_date
set parameter_hash(report_customer_id) $report_customer_id
set parameter_hash(report_program_id) $report_program_id
set parameter_hash(report_project_type_id) $report_project_type_id
set parameter_hash(report_project_type) [im_category_from_id $report_project_type_id]
set parameter_hash(report_area_id) $report_area_id
set parameter_hash(now) [db_string now "select to_char(now(), 'YYYY-MM-DD')"]
set parameter_hash(now_month_of_year) [db_string now "select to_char(now(), 'MM')"]
set parameter_hash(now_day_of_month) [db_string now "select to_char(now(), 'DD')"]
set parameter_hash(now_year) [db_string now "select to_char(now(), 'YYYY')"]
set parameter_hash(date_format) $date_format
set parameter_hash(report_start_date_pretty) [db_string report_start_date_pretty "select to_char(:report_start_date::date, :date_format) from dual"]
set parameter_hash(report_end_date_pretty) [db_string report_end_date_pretty "select to_char(:report_end_date::date, :date_format) from dual"]

set parameter_hash(program_id) 48944

set ttt {
set parameter_hash() $
set parameter_hash() $
set parameter_hash() $
set parameter_hash() $
set parameter_hash() $
set parameter_hash() $
set parameter_hash() $
}

#
set parameter_list [array get parameter_hash]


set debug ""
foreach page_node $odt_page_template_nodes {

    # Extract the "page name" from OOoo.
    # We use this field to determine the type of the page
    set page_name_list [$page_node getAttribute "draw:name"]
    set page_type [lindex $page_name_list 0]
    set page_name [lrange $page_name_list 1 end]

    set page_notes [im_oo_page_notes -page_node $page_node]
    set sql ""
    set repeat ""
    for {set i 0} {$i < [llength $page_notes]} {incr i 2} {
	set varname [lindex $page_notes $i]
	set varvalue [lindex $page_notes [expr $i+1]]

	# Substitute a "long dash" ("--") with a normal one
	regsub -all $long_dash $varvalue "-" varvalue

	switch [string tolower $varname] {
	    sql { set sql $varvalue }
	    repeat { set repeat $varvalue }
	}
    }

    append debug "<li>$page_type=$page_type, page_name=$page_name, sql=$sql, repeat=$repeat\n"

    switch $page_type {
	constant {
	    im_oo_page_type_constant -page_node $page_node -page_name $page_name -parameters $parameter_list -sql $sql -repeat $repeat
	}
	static {
	    im_oo_page_type_static -page_node $page_node -page_name $page_name -parameters $parameter_list -sql $sql -repeat $repeat
	}
	sql_list {
	    im_oo_page_type_sql_list -page_node $page_node -page_name $page_name -parameters $parameter_list -sql $sql -repeat $repeat
	}
	default {
	    ad_return_complaint 1 "<b>Found unknown page type '$page_type' in page '$page_name'</b>"
	    ad_script_abort
	}
    }
}

#ad_return_complaint 1 "<pre>$debug</pre>"


# ---------------------------------------------------------------
# Format as XML and perform substitutions
# ---------------------------------------------------------------

# Format document as XML
set content [$odt_root asXML -indent none]

# Save the content to a file.
set file [open $odt_content w]
fconfigure $file -encoding "utf-8"
puts $file $content
flush $file
close $file



# ---------------------------------------------------------------
# Process the styles.xml file
# ---------------------------------------------------------------

set file [open $odt_styles]
fconfigure $file -encoding "utf-8"
set style_content [read $file]
close $file

# Perform replacements
eval [template::adp_compile -string $style_content]
set style $__adp_output

# Save the content to a file.
set file [open $odt_styles w]
fconfigure $file -encoding "utf-8"
puts $file $style
flush $file
close $file


# ---------------------------------------------------------------
# Replace the files inside the odt file by the processed files
# ---------------------------------------------------------------

# The zip -j command replaces the specified file in the zipfile
# which happens to be the OpenOffice File.
exec zip -j $odt_zip $odt_content
exec zip -j $odt_zip $odt_styles

db_release_unused_handles


# ---------------------------------------------------------------
# Return the file
# ---------------------------------------------------------------

set outputheaders [ns_conn outputheaders]
ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${odt_filename}"
ns_returnfile 200 application/odt $odt_zip


# ---------------------------------------------------------------
# Delete the temporary files
# ---------------------------------------------------------------

# delete other tmpfiles
# ns_unlink "${dir}/$document_filename"
# ns_unlink "${dir}/$content.xml"
# ns_unlink "${dir}/$style.xml"
# ns_unlink "${dir}/document.odf"
# ns_rmdir $dir
ad_script_abort

