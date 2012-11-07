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

set tuple [im_gp_save_xml \
    -debug_p $debug_p \
    -return_url $return_url \
    -project_id $project_id \
    -file_content $binary_content \
]

set task_hash_array [lindex $tuple 0]
set resources_to_assign_p [lindex $tuple 1]
set resource_html [lindex $tuple 2]

# -------------------------------------------------------------------
# Check if we have to delete some tasks
# -------------------------------------------------------------------

# Get all the tasks about the current project
array set db_task_ids {} 
foreach i [im_gp_extract_db_tree $project_id] {
	set db_task_ids($i) 1
}

# we don't want to delete the project (which never is in the xml)
if {[info exists db_task_ids($project_id)]} {
	unset db_task_ids($project_id)
}

# Remove all tasks from the GanttProject .gan file
array set task_hash $task_hash_array

set task_hash_tasks [list 0]
foreach task_hash_key [array names task_hash] {
	set task_hash_value $task_hash($task_hash_key)
	if [info exists db_task_ids($task_hash_value)] {
	    unset db_task_ids($task_hash_value)
	}
	lappend task_hash_tasks $task_hash_value
}

# Check if there are tasks to delete...
set tasks_to_delete_p 1
if {"" == [set ids [array names db_task_ids]]} { set tasks_to_delete_p 0}


# -------------------------------------------------------------------
# Check if there were no errors/decisions to take
# -------------------------------------------------------------------

if {!$tasks_to_delete_p && !$resources_to_assign_p} {
	ad_returnredirect $return_url
}


# -------------------------------------------------------------------
# Create task reassignation screen
# -------------------------------------------------------------------

# Create the list of candidate project to which we could reasonably reassign the resources:
set reassign_tasks ""
db_foreach reassign_tasks "
	SELECT	project_id as task_id,
		project_name,
		project_nr,
		tree_level(tree_sortkey)-1 as level
	FROM	im_projects
	WHERE	project_id IN (:project_id, [join $task_hash_tasks ","])
	ORDER BY tree_sortkey
" {
	set indent ""
	for {set i 0} {$i < $level} { incr i} { append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" }
	set selected ""
	if {$task_id == $project_id} { set selected "selected" }
	append reassign_tasks "<option value=\"$task_id\" $selected>$indent $project_nr : $project_name</option>"
}

lappend ids 0
db_multirow -extend {project_indent } delete_tasks delete_tasks "
	SELECT	project_id as task_id,
		project_name,
		project_nr,
		tree_level(tree_sortkey) as project_level
	FROM	im_projects
	WHERE 	project_id IN ([join $ids ,])
	ORDER by
	      tree_sortkey
" {
	set space "&nbsp; &nbsp; &nbsp; "
	set project_indent ""
	for {set i 0} {$i < $project_level} {incr i} { append project_indent $space }
}

template::list::create \
	-pass_properties { reassign_tasks } \
	-bulk_actions [list \
			   [lang::message::lookup {} intranet-ganttproject.Delete_and_Reassign {Delete Tasks and Reassign Resources}] \
			   "/intranet-timesheet2-tasks/task-delete" \
			   [lang::message::lookup {} intranet-ganttproject.Delete_selected_tasks {Delete the selected tasks and reassign their resources to the choosen task/project}] \
			  ] \
	-bulk_action_export_vars { return_url project_id } \
	-bulk_action_method post \
	-name delete_tasks \
	-key task_id \
	-elements {
	    project_nr {
		label "[lang::message::lookup {} intranet-ganttproject.Task_Nr {Task Nr.}]"
	    } 
	    project_name {
		label "[lang::message::lookup {} intranet-ganttproject.Task_Name {Task Name}]"
		display_template { <nobr>@delete_tasks.project_indent;noquote@ @delete_tasks.project_name@</nobr> }
	    }
	    assign_to {
		label "[lang::message::lookup {} intranet-ganttproject.Reassign_Resources_To {Reassign Resources To}]"
		display_template { <select name=\"assign_to.@delete_tasks.task_id@\">$reassign_tasks</select> }
	    }
	}

# Write audit trail
im_project_audit -project_id $project_id




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

