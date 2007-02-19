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


# -------------------------------------------------------------------
# Get a list of tasks from db (needed for deletion later)
# -------------------------------------------------------------------

array set db_task_ids {} 
foreach i [im_gp_extract_db_tree $project_id] {
    set db_task_ids($i) 1
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
    
    #ns_write "</ul>\n"
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
# find tasks to delete
# -------------------------------------------------------------------

# we don't want to delete the project (which never is in the xml)
unset db_task_ids($project_id)
foreach i $task_hash_array {
    if [info exists db_task_ids($i)] {
	unset db_task_ids($i)
    }
}

# return if we don't have to delete anything
if {[set ids [array names db_task_ids]]==""} {
    ad_returnredirect $return_url
}

set keep_tasks ""
db_foreach keep_tasks "
  SELECT
    project_id as task_id,
    project_name,
    project_nr
  FROM
    im_projects
  WHERE 
    project_id IN ([join $task_hash_array ,])
  ORDER BY 
    project_nr
" {
    append keep_tasks "<option value=\"$task_id\">$project_nr : $project_name</option>"
}

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
    -pass_properties {
	keep_tasks
    } \
    -name delete_tasks \
    -key task_id \
    -elements {
	task_id {
            label "task id"
        } 
        project_nr {
            label "Task NR"
        } 
        project_name {
            label "Task Name"
        }
	assign_to {
	    label "Assign to"
	    display_template { <select name=\"assign_to.@delete_tasks.task_id@\">$keep_tasks</select> }
	}
    } \
    -bulk_actions {
        "Delete" "/intranet-timesheet2-tasks/task-delete" "Delete selected tasks"
    } \
    -bulk_action_export_vars { return_url project_id } \
    -bulk_action_method post

