# /packages/intranet-ganttproject/www/gantt-upload-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Save/Upload a GanttProject XML structure

    @author frank.bergmann@project-open.com
} {
    { expiry_date "" }
    project_id:integer 
    { security_token "" }
    { upload_gan ""}
    { upload_gif ""}
    { debug_p 0 }
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} { 
    ad_return_complaint 1 "You don't have permissions to see this page" 
    ad_script_abort
}

if {"" == $upload_gan && "" == $upload_gif} {
    ad_return_complaint 1 "You need to specify a file to upload"
}

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
set page_title [lang::message::lookup "" intranet-ganttproject.Import_Gantt_Tasks "Import Gantt Tasks"]
set context_bar [im_context_bar $page_title]
set reassign_title [lang::message::lookup "" intranet-ganttproject.Delete_Gantt_Tasks "Reassign Resources of Removed Tasks"]
set missing_resources_title [lang::message::lookup "" intranet-ganttproject.Missing_Resources_title "Missing Resources"]
set missing_resources_msg [lang::message::lookup "" intranet-ganttproject.Missing_Resources_msg "The following MS-Project resources could not be found in \]po\[. Please correct the resource names in your MS-Project plan or click on the links below in order to create new resources."]

# Write audit trail
im_project_audit -project_id $project_id -action before_update

db_1row project_info "
	select	project_id as org_project_id,
		project_name as org_project_name
	from	im_projects
	where	project_id = :project_id
"


# -------------------------------------------------------------------
# Get the file from the user.
# -------------------------------------------------------------------

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_gan.tmpfile]
ns_log Notice "upload-2: tmp_filename=$tmp_filename"
set file_size [file size $tmp_filename]

# Check for the extension of the uploaded file.
set gantt_file_extension [string tolower [lindex [split $upload_gan "."] end]]

if {"pod" == $gantt_file_extension} {
    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-ganttproject.Invalid_OpenProj_File_Type "Invalid OpenProj File Type"]</b>:<br>
	[lang::message::lookup "" intranet-ganttproject.Invalid_File_Type "
		You are trying to upload an OpenProj 'Serana (.pod)' file, which is not supported.<br>
		Please export your OpenProj file in format <b>'MS-Project 2003 XML (.xml)'</b>.
	"]
    "
    ad_script_abort
}

if {$max_n_bytes && ($file_size > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size: 
    [util_commify_number $max_n_bytes] bytes"
    return 0
}


# -------------------------------------------------------------------
# Determine the type of the file
# -------------------------------------------------------------------

set file_type [fileutil::fileType $tmp_filename]
if {[lsearch $file_type "ms-office"] >= 0} {
    # We've found a binary MS-Office file, probably MPP

    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-ganttproject.Invalid_XML "Invalid XML Format"]</b>:<br>&nbsp;<br>
	[lang::message::lookup "" intranet-ganttproject.Invalid_MS_Office_Document "
		You have uploaded a Microsoft Office document. This is not supported.<br>
		In MS-Project please choose:<br>
		<b>File -&gt; Save As -&gt; Save as type -&gt; XML Format (*.xml)</b><br>
		in order to save your file in XML format.
	"]
    "
    ad_script_abort

}

# -------------------------------------------------------------------
# Read the file from the HTTP session's TMP file
# -------------------------------------------------------------------

if {[catch {
    set fl [open $tmp_filename]
    fconfigure $fl -encoding "utf-8"
    set binary_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $tmp_filename:
    <br><pre>\n$err</pre>"
    return
}

# -------------------------------------------------------------------
# Parse the MS-Project/GanttProject XML
# -------------------------------------------------------------------

im_gp_save_xml \
    -debug_p $debug_p \
    -return_url $return_url \
    -project_id $project_id \
    -file_content $binary_content

# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]
set menu_label ""

set sub_navbar [im_sub_navbar \
		    -components \
		    -base_url [export_vars -base "/intranet/projects/view" {project_id}] \
		    $parent_menu_id \
		    $bind_vars \
		    "" \
		    "pagedesriptionbar" \
		    $menu_label \
		   ]

