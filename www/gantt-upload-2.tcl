# /packages/intranet-ganttproject/www/gantt-upload-2.tcl
#
# Copyright (C) 2003-2006 Project/Open
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
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set debug 0

if {"" == $upload_gan && "" == $upload_gif} {
    ad_return_complaint 1 "You need to specify a file to upload"
}

#ToDo: Security
set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
#ad_return_top_of_page "[im_header]\n[im_navbar]"

set page_title [lang::message::lookup "" intranet-ganttproject.Import_Gantt_Tasks "Import Gantt Tasks"]

set reassign_title [lang::message::lookup "" intranet-ganttproject.Delete_Gantt_Tasks "Reassign Resources of Removed Tasks"]
set resource_title [lang::message::lookup "" intranet-ganttproject.Resource_Title "Resources not Found"]

# Write audit trail
im_project_audit $project_id

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
    fconfigure $fl -encoding "utf-8"
    set binary_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $tmp_filename:
    <br><pre>\n$err</pre>"
    return
}

# -------------------------------------------------------------------
# Save the new Tasks from GanttProject
# -------------------------------------------------------------------

set doc [dom parse $binary_content]
set root_node [$doc documentElement]

# Save the tasks.
# The task_hash contains a mapping table from gantt_project_ids
# to task_ids.

#ns_write "<h2>Pass 1: Saving Tasks</h2>\n"
set task_hash_array [list]
set task_hash_array [im_gp_save_tasks \
	-create_tasks 1 \
	-save_dependencies 0 \
	-task_hash_array $task_hash_array \
	-debug $debug \
	$root_node \
	$project_id \
]
array set task_hash $task_hash_array

#ns_write "<h2>Pass 2: Saving Dependencies</h2>\n"
set task_hash_array [im_gp_save_tasks \
	-create_tasks 0 \
	-save_dependencies 1 \
	-task_hash_array $task_hash_array \
	-debug $debug \
	$root_node \
	$project_id \
]

# -------------------------------------------------------------------
# Description
# -------------------------------------------------------------------

if {[set node [$root_node selectNodes /project/description]] != ""} {
    set description [$node text]

    db_dml project_update "
	    update im_projects set
              description = :description
	    where
		project_id = :project_id
    "
}

# -------------------------------------------------------------------
# Process Resources
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

if {[set resource_node [$root_node selectNodes /project/resources]] != ""} {
    #ns_write "<h2>Saving Resources</h2>\n"
    #ns_write "<ul>\n"

    set resource_hash_array [im_gp_save_resources -debug $debug $resource_node]
    array set resource_hash $resource_hash_array
    #ns_write "</ul>\n"
}

set resources_to_assign_p 0
set resource_html ""
foreach rid [array names resource_hash] {
    set v $resource_hash($rid)
    if {[string is integer $v]} { continue }

    set resources_to_assign_p 1
    append resource_html "$v\n"
}

# -------------------------------------------------------------------
# Process Allocations
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

if {[set allocations_node [$root_node selectNodes /project/allocations]] != ""} {

    #ns_write "<h2>Saving Allocations</h2>\n"
    #ns_write "<ul>\n"

    im_gp_save_allocations \
	-debug $debug \
	$allocations_node \
	$task_hash_array \
        $resource_hash_array
    
    #ns_write "</ul>\n"
}

# -------------------------------------------------------------------
# Check if we have to delete some tasks
# -------------------------------------------------------------------

# Get all the tasks about the current project
array set db_task_ids {} 
foreach i [im_gp_extract_db_tree $project_id] {
    set db_task_ids($i) 1
}

# we don't want to delete the project (which never is in the xml)
unset db_task_ids($project_id)

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
db_multirow delete_tasks delete_tasks "
  SELECT
    project_id as task_id,
    project_name,
    project_nr
  FROM
    im_projects
  WHERE 
    project_id IN ([join $ids ,])
"

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
        }
	assign_to {
	    label "[lang::message::lookup {} intranet-ganttproject.Reassign_Resources_To {Reassign Resources To}]"
	    display_template { <select name=\"assign_to.@delete_tasks.task_id@\">$reassign_tasks</select> }
	}
    }

