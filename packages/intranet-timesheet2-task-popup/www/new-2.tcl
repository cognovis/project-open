# /www/intranet-timesheet2-task-popup/www/new-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes a single task_id from timesheet2 and determines the 
    time that the user has worked on this task

    @param project_task_id project_id-task-id in a single variable.
           Ugly, but we need to pass on variables from a drop-down
           box, and there may be elements with project_id but with
           no task_id
    @author frank.bergmann@project-open.com
} {
    project_task_id
    { note "" }
    { return_url "/intranet/" }
}


# ----------------------------------------------------------
# Default & Security
# ----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set date_format "YYYY-MM-DD"

# Extract project_id and task_id from input variable
regexp {([0-9]+)\-([0-9]+)} $project_task_id match project_id timesheet_task_id
# ad_return_complaint 1 "$project_id - $timesheet_task_id"

# ----------------------------------------------------------
# Log the event
# ----------------------------------------------------------

# Check if this entry is coming from a project without a
# timesheet task already defined:
if {"" == $timesheet_task_id || 0 == $timesheet_task_id} {
    set timesheet_task_id [db_string existing_default_task "
                select  task_id
                from    im_timesheet_tasks_view
                where   project_id = :project_id
                        and task_nr = 'default'
            " -default 0]
}

if {"" == $timesheet_task_id || 0 == $timesheet_task_id} {
    
    # Create a default timesheet task for this project
    set task_id [im_new_object_id]
    set task_nr "default"
    set task_name "Default Task"
    set material_id [db_string default_material "select material_id from im_materials where material_nr='default'" -default 0]
    if {!$material_id} {
	ad_return_complaint 1 "Configuration Error:<br>Error during the creation of a default timesheet task for project \#$project_id: We couldn't find any default material with the material_nr 'default'. <br>Please inform your system administrator."
    }
    set cost_center_id ""
    set uom_id [im_uom_hour]
    set task_type_id [im_timesheet_task_type_standard]
    set task_status_id [im_timesheet_task_status_active]
    set description "Default task for timesheet logging convenience - please update"
    
    db_exec_plsql task_insert ""
    set timesheet_task_id $task_id
}


# ----------------------------------------------------------
# Log the event
# ----------------------------------------------------------

db_dml popup_insert "
	insert into im_timesheet_popups (
	    popup_id, 
	    user_id, task_id, 
	    log_time, log_duration, note
	) values (
	    nextval('im_timesheet_popup_seq'), 
	    :user_id, :timesheet_task_id, 
	    now(), interval '15 minutes', :note
	)
"

# ----------------------------------------------------------
# Redirect back to calling page
#
db_release_unused_handles
ad_returnredirect $return_url
