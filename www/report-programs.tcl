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
    { template "report-programs-template.111204b.odp" }
    { odt_filename "project-openslide.odt" }
    { output_format "odp" }
}


ad_proc im_oo_sql_list {
    -page_node:required
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
    set date_format "YYYY-MM-DD"


    # Get the list of all tables in slide
    set table_nodes [$page_node selectNodes "//table:table"]

    set cnt 0
    set table_node ""
    foreach node $table_nodes { 
	set table_node $node
	incr cnt 
    }
    if {$cnt == 0} { 
	ad_return_complaint 1 "<b>im_oo_sql_list: Did not found a table in the slide</b>" 
	ad_script_abort
    }
    if {$cnt > 1} { 
	ad_return_complaint 1 "<b>im_oo_sql_list: Found more the one table</b>" 
	ad_script_abort
    }

    # Seach for the 2nd table:table-row tag that contains the template
    set row_nodes [$table_node selectNodes "//table:table-row"]
    set template_row_node ""
    set row_count 0
    foreach row_node $row_nodes {
        set row_as_list [$row_node asList]
        if {2 == $row_count} { set template_row_node $row_node }
        incr row_count
    }

    if {"" == $template_row_node} {
        ad_return_complaint 1 "<b>Table only has one row</b>"
        ad_script_abort
    }

    # Convert the tDom tree into XML for rendering
    set template_row_xml [$template_row_node asXML]

    # ------------------------------------------------------------
    # Construct the SQL
    set derefs "
	,im_category_from_id(prog.project_status_id) as project_status
	,im_category_from_id(prog.project_status_id) as area
    "

    set program_sql "
	select	t.*,
		percent_completed_calendar_advance - program_percent_completed as percent_completed_calendar_deviation
	from	(select	prog.*,
			to_char(prog.start_date, :date_format) as start_date_pretty,
			to_char(prog.end_date, :date_format) as end_date_pretty,
			(	select	round(10.0 * avg(percent_completed)) / 10.0
				from	im_projects p
				where	p.program_id = prog.project_id and
					p.project_status_id in (select * from im_sub_categories([im_project_status_open]))
			) as program_percent_completed,
	
			-- Calculate the advance according to calendar time passed
			CASE 
			WHEN now() < prog.start_date THEN 0.0
			WHEN now() > prog.end_date THEN 100.0
			WHEN prog.start_date is null THEN 0.0
			WHEN prog.end_date is null THEN 0.0
			WHEN to_char(prog.end_date,'J')::float <= to_char(prog.start_date,'J')::float THEN 0.0
			WHEN now() >= prog.start_date and now() <= prog.end_date THEN
				100.0 * (to_char(now(),'J')::float - to_char(prog.start_date,'J')::float) / (to_char(prog.end_date,'J')::float - to_char(prog.start_date,'J')::float)
			END as percent_completed_calendar_advance,
	
			cust.company_name,
			cust.company_path as company_nr,
			cust.company_id
	
			$derefs 
		from	im_projects prog,
			im_companies cust
		where	prog.company_id = cust.company_id and
			prog.project_type_id = [im_project_type_program]
		) t
	order by
		lower(project_name)
    "

    set table_body_xml ""
    db_foreach programs $program_sql {
	# Replace placeholders in the OpenOffice template row with values
	eval [template::adp_compile -string $template_row_xml]
	set row_xml $__adp_output

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

# Get the container tag that contains various pages
# and the list of pages in the document
set odt_page_container_node [$odt_root selectNodes "//office:presentation"]
set odt_page_template_nodes [$odt_root selectNodes "//draw:page"]


# ---------------------------------------------------------------
# Loop through all pages
# and process each page depending on its type
# ---------------------------------------------------------------

foreach template_page_node $odt_page_template_nodes {
    set page_type [string tolower "sql_list"]
    switch $page_type {
	sql_list {
	    im_oo_sql_list -page_node $template_page_node
	}
    }
}


# ---------------------------------------------------------------
# Format as XML and perform substitutions
# ---------------------------------------------------------------

# Format document as XML
set content [$odt_root asXML]

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

