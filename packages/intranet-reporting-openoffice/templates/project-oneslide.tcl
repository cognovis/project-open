# /packages/intranet-reporting-openoffice/www/project-oneslide.tcl
#
# Copyright (C) 2003 - 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Return an OpenOffice document with one slide per project
    @author frank.bergmann@project-open.com
} {
    { template "project-oneslide.odp" }
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

set odt_filename "project-openslide.odt"

set asdf asdf
set sdfg sdfg

# ---------------------------------------------------------------
# Determine system pathes
# ---------------------------------------------------------------

# Determine the template
set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]
set template_base_path "$serverroot/packages/intranet-reporting-openoffice/templates"
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


# ---------------------------------------------------------------
# Perform substitutions etc.
# ---------------------------------------------------------------

# Get the container tag that contains various pages
set odt_container_node [$odt_root selectNodes "//office:presentation"]

# Get the list of pages in the document
set odt_page_nodes [$odt_root selectNodes "//draw:page"]

# Search for the page that contains "@project_name@"
set odt_template_page_node ""
foreach page_node $odt_page_nodes {
    set page_as_list [$page_node asList]
    if {[regexp {project_name} $page_as_list match]} { 
	set odt_template_page_node $page_node 
    }
}

# Format the page for every project and add to the document
set projects_sql "
	select	p.*,
		c.company_name,
		to_char(p.start_date, :date_format) as start_date_pretty,
		to_char(p.end_date, :date_format) as end_date_pretty
	from	im_projects p,
		im_companies c
	where	p.company_id = c.company_id and
		p.parent_id is null and
		p.project_status_id in (select * from im_sub_categories([im_project_status_open])) and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
	order by
		lower(p.project_name)
"

# Convert the tDom tree into XML for rendering
set odt_page_template_xml [$odt_template_page_node asXML]

db_foreach projects $projects_sql {

    # Insert a new XML page into OpenOffice document
    # Replace placeholders in the OpenOffice template row with values
    eval [template::adp_compile -string $odt_page_template_xml]
    set odt_page_xml $__adp_output

    # Parse the new page and insert into OOoo document
    set page_doc [dom parse $odt_page_xml]
    set new_page [$page_doc documentElement]

    ns_log Notice "project-oneslide: $odt_root insertBefore $new_page $odt_template_page_node"
    $odt_container_node insertBefore $new_page $odt_template_page_node

}



# ---------------------------------------------------------------
# Format as XML and perform substitutions
# ---------------------------------------------------------------

# Format document as XML
set odt_template_content [$odt_root asXML -indent none]

# Perform replacements
eval [template::adp_compile -string $odt_template_content]
set content $__adp_output

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

