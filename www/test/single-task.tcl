# /packages/intranet-ganttproject/www/test/single-task.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Test the MS-Project import of a single task
    and check that all fields of the task are imported correctly.
    @author frank.bergmann@project-open.com
} {
    { test_filename "single-task.xml" }
    { project_name "Test Single Task" }
    { project_nr "single_task" }
    { customer_path "abc_consulting" }
    { format "ms" }
    { debug_p 0 }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "This page is only accessible for administrators"
    ad_script_abort
}


# ---------------------------------------------------------------
# Delete a project if it already exists
# ---------------------------------------------------------------

set project_id [db_string old_project "select project_id from im_projects where project_nr = :project_nr" -default ""]
if {"" != $project_id} {
    im_project_nuke $project_id
}

# ---------------------------------------------------------------
# Create a new project
# ---------------------------------------------------------------

set parent_project_id ""
set project_path $project_nr
set customer_id [db_string customer "select company_id from im_companies where company_path = :customer_path"]
set project_id [project::new \
		    -project_name	$project_name \
		    -project_nr		$project_nr \
		    -project_path	$project_path \
		    -company_id		$customer_id \
		    -parent_id		$parent_project_id \
		    -project_type_id	[im_project_type_consulting] \
		    -project_status_id	[im_project_status_open] \
		   ]


# -------------------------------------------------------------------
# Read and parse the file
# -------------------------------------------------------------------

set filename "[acs_root_dir]/packages/intranet-ganttproject/www/test/$test_filename"
set fl [open $filename]
fconfigure $fl -encoding "utf-8"
set binary_content [read $fl]
close $fl
set doc [dom parse $binary_content]
set root_node [$doc documentElement]
set task_hash_array [list]

set task_hash_array [im_gp_save_tasks \
			 -format $format \
			 -create_tasks 1 \
			 -save_dependencies 0 \
			 -task_hash_array $task_hash_array \
			 -debug_p $debug_p \
			 $root_node \
			 $project_id \
			]
array set task_hash $task_hash_array

set task_hash_array [im_gp_save_tasks \
			 -format $format \
			 -create_tasks 0 \
			 -save_dependencies 1 \
			 -task_hash_array $task_hash_array \
			 -debug_p $debug_p \
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

if {[set resource_node [$root_node selectNodes /project/resources]] == ""} {
    set resource_node [$root_node selectNodes -namespace { "project" "http://schemas.microsoft.com/project" } "project:Resources" ]
}

if {$resource_node != ""} {
    set resource_hash_array [im_gp_save_resources -debug_p $debug_p $resource_node]
    array set resource_hash $resource_hash_array
}

set resources_to_assign_p 0
set resource_html ""
foreach rid [array names resource_hash] {
    set v $resource_hash($rid)
    if {[string is integer $v]} { continue }
    set resources_to_assign_p 1
}


# -------------------------------------------------------------------
# Process Allocations
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

if {[set allocations_node [$root_node selectNodes /project/allocations]] == ""} {
    set allocations_node [$root_node selectNodes -namespace { "project" "http://schemas.microsoft.com/project" } "project:Assignments" ]
}

if {$allocations_node != ""} {
    im_gp_save_allocations \
	-debug_p $debug_p \
	$allocations_node \
	$task_hash_array \
        $resource_hash_array
}



# -------------------------------------------------------------------
# Check the created project
# -------------------------------------------------------------------

db_1row project_info "
	select	start_date::date as start_date,
		end_date::date as end_date
	from	im_projects
	where	project_id = :project_id
"

set checks {
    { start_date "2011-03-17" }
    { end_date "2011-03-21" }
}

ns_write "<li>single-task: Project Checks: Starting"
foreach check $checks {
    set var [lindex $check 0]
    set val [lindex $check 1]
    if {[set $var] != $val} {
	ns_write "<li>single-task: Project Checks: Error: Wrong '$var' with value '[set $var]' instead of '$val'\n"
    } else {
	ns_write "<li>single-task: Project Checks: OK: '$var' with value '$val'\n"
    }
}
ns_write "<li>single-task: Project Checks: Finished"


# -------------------------------------------------------------------
# Check the single task of the project
# -------------------------------------------------------------------

# There should be exactly one task below the project
db_1row task_info "
	select	p.*,
		p.start_date::date as start_date_date,
		p.end_date::date as end_date_date,
		t.*,
		gp.*
	from	im_projects p,
		im_timesheet_tasks t,
		im_gantt_projects gp
	where	t.task_id = p.project_id and
		gp.project_id = p.project_id and
		p.parent_id = :project_id
"

set checks {
    { project_name "Single Task" }
    { start_date_date "2011-03-17" }
    { end_date_date "2011-03-21" }
    { planned_units "24" }
    { percent_completed "12" }
    { priority "456" }
}

ns_write "<li>single-task: Task Checks: Starting"
foreach check $checks {
    set var [lindex $check 0]
    set val [lindex $check 1]
    if {[set $var] != $val} {
	ns_write "<li>single-task: Task Checks: Error: Wrong '$var' with value '[set $var]' instead of '$val'\n"
    } else {
	ns_write "<li>single-task: Task Checks: OK: '$var' with value '$val'\n"
    }
}
ns_write "<li>single-task: Task Checks: Finished"

