# /packages/intranet-ganttproject/www/gantt-upload-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
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
    { user_id:integer 0 }
    { expiry_date "" }
    project_id:integer 
    { security_token "" }
    { upload_gan ""}
    { upload_gif ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

if {"" == $upload_gan && "" == $upload_gif} {
    ad_return_complaint 1 "You need to specify a file to upload"
}


#ToDo: Security
set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
ad_return_top_of_page "[im_header]\n[im_navbar]"


# -------------------------------------------------------------------
# Get the file from the user.
# -------------------------------------------------------------------

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_gan.tmpfile]
ns_log Notice "upload-2: tmp_filename=$tmp_filename"
set file_size [file size $tmp_filename]

if { $max_n_bytes && ($file_size > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size: 
    [util_commify_number $max_n_bytes] bytes"
    return 0
}

if {[catch {
    set fl [open $tmp_filename]
    fconfigure $fl -encoding binary
    set binary_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $tmp_filename:
    <br><pre>\n$err</pre>"
    return
}

set doc [dom parse $binary_content]
set root_node [$doc documentElement]


# -------------------------------------------------------------------
# Save the new Tasks from GanttProject
# -------------------------------------------------------------------

# Save the tasks.
# The task_hash contains a mapping table from gantt_project_ids
# to task_ids.

ns_write "<h2>Pass 1: Saving Tasks</h2><ul>\n"
set task_hash_array [list]

set task_hash_array [im_gp_save_tasks \
	-enable_save_dependencies 0 \
	 -task_hash_array $task_hash_array \
	$root_node \
	$project_id \
]
array set task_hash $task_hash_array


#ns_write "<h2>Pass 2: Saving Dependencies</h2><ul>\n"
#set task_hash_array [im_gp_save_tasks \
#	-enable_save_dependencies 1 \
#	-task_hash_array $task_hash_array \
#	$root_node \
#	$project_id \
#]

# -------------------------------------------------------------------
# Process Resources
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

ns_write "<h2>Saving Resources</h2>\n"
ns_write "<ul>\n"

set resource_node [$root_node selectNodes /project/resources]
set resource_hash_array [im_gp_save_resources $resource_node]

ns_write "</ul>\n"

# -------------------------------------------------------------------
# Process Allocations
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

ns_write "<h2>Saving Allocations</h2>\n"
ns_write "<ul>\n"

set allocations_node [$root_node selectNodes /project/allocations]
im_gp_save_allocations \
	$allocations_node \
	$task_hash_array \
        $resource_hash_array


ns_write "</ul>\n"


# -------------------------------------------------------------------
# Delete the tasks that have been deleted in GanttProject
# -------------------------------------------------------------------

ns_write "<h2>Deleting Deleted Tasks</h2>\n"

# Extract a tree of tasks from the Database
set xml_tree [im_gp_extract_xml_tree $root_node $task_hash_array]
set db_tree [im_gp_extract_db_tree $project_id]
set db_list [lsort -integer -unique [im_gp_flatten $db_tree]]
set xml_list [lsort -integer -unique [im_gp_flatten $xml_tree]]

ns_log Notice "task_hash_array: $task_hash_array"
ns_log Notice "gantt-upload-2: DB Tree: $db_tree\n"
ns_log Notice "gantt-upload-2: XML Tree: $xml_tree\n"
ns_log Notice "gantt-upload-2: DB List: $db_list\n"
ns_log Notice "gantt-upload-2: XML List: $xml_list\n"


# Now calculate the difference between the two lists
#
set diff_list [im_gp_difference $db_list [lappend xml_list $project_id]]

# Deal with the case of an empty diff_list
lappend diff_list 0

ns_log Notice "gantt-upload-2: Diff List: $diff_list\n"

set del_projects_sql "
	select	p.project_id
	from	im_projects p
	where	p.project_id in ([join $diff_list ","])
"
db_foreach del_projects $del_projects_sql {
    ns_write "<li>Nuking project# $project_id\n"
    im_project_nuke $project_id
}


set del_tasks_sql "
	select	p.task_id
	from	im_timesheet_tasks p
	where	p.task_id in ([join $diff_list ","])
"
db_foreach del_tasks $del_tasks_sql {
    ns_write "<li>Nuking task# $task_id\n"
    im_timesheet_task_nuke $task_id
}


ns_write [im_footer]
