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
    { template "test-list.odp" }
    { odt_filename "test-list.odp" }
    { output_format "odp" }
    { report_start_date "2011-10-01" }
    { report_end_date "2011-11-01" }
    { report_customer_id "" }
    { report_program_id "" }
    { report_project_type_id "" }
    { report_area_id "" }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# Get user parameters
set user_id [ad_maybe_redirect_for_registration]
set user_locale [lang::user::locale]
set date_format "YYYY-MM-DD"

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

# Debugging Sample Parameters
set parameter_hash(program_id) 48944

# Make a copy of the parameter_hash as a list
set base_parameter_list [array get parameter_hash]


set debug ""
array unset parameter_hash
array set parameter_hash $base_parameter_list
foreach page_node $odt_page_template_nodes {

    # Extract the "page name" from OOoo.
    # We use this field to determine the type of the page
    set page_name_list [$page_node getAttribute "draw:name"]
    set page_type [lindex $page_name_list 0]
    set page_name [lrange $page_name_list 1 end]

    set page_notes [im_oo_page_notes -page_node $page_node]
    set page_sql ""
    set list_sql ""
    set counters ""
    for {set i 0} {$i < [llength $page_notes]} {incr i 2} {
	set varname [string tolower [lindex $page_notes $i]]
	set varvalue [lindex $page_notes [expr $i+1]]

	# Substitute a "long dash" ("--") with a normal one
	regsub -all $long_dash $varvalue "-" varvalue

	switch $varname {
	    page_sql { set page_sql $varvalue }
	    list_sql { set list_sql $varvalue }
	    default {
		set parameter_hash($varname) $varvalue
	    }
	}
    }

    append debug "<li>$page_type=$page_type, page_name=$page_name, page_sql=$page_sql, list_sql=$list_sql\n"

    switch $page_type {
	constant {
	    im_oo_page_type_constant \
		-page_node $page_node \
		-page_name $page_name \
		-parameters [array get parameter_hash] \
		-list_sql $list_sql \
		-page_sql $page_sql
	}
	static {
	    im_oo_page_type_static \
		-page_node $page_node \
		-page_name $page_name \
		-parameters [array get parameter_hash] \
		-list_sql $list_sql \
		-page_sql $page_sql
	}
	list {
	    im_oo_page_type_sql_list \
		-page_node $page_node \
		-page_name $page_name \
		-parameters [array get parameter_hash] \
		-list_sql $list_sql \
		-page_sql $page_sql
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

