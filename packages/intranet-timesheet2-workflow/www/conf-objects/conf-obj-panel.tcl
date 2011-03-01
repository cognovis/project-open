# /packages/intranet-timesheet2-workflow/www/conf-obj-panel.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# -----------------------------------------------------------
# Page Head
# 
# There are two different heads, depending whether it's called
# "standalone" (TCL-page) or as a Workflow Panel.
# -----------------------------------------------------------

if {[info exists task]} {

    # Workflow-Panel Head:
    # This code is called when this page is embedded in a WF "Panel"

    set task_id $task(task_id)
    set case_id $task(case_id)

    # Return-URL Logic
    set return_url ""
    if {[info exists task(return_url)]} { set return_url $task(return_url) }

    set conf_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]

} else {

    # Stand-Alone Head:
    # This code is called when the page is used as a normal "EditPage" or "NewPage".

    ad_page_contract {
        Purpose: form to add a new project or edit an existing one
    } {
        conf_id:integer
        { return_url "/intranet/" }
	{ task_id "" }
    }

    # Get the task_id if we've got the project
    if {"" == $task_id} { 
	set case_id [db_string case_id "select case_id from wf_cases where object_id = :conf_id" -default 0]
	set tasks [db_list tasks "select task_id from wf_tasks where case_id=:case_id and state in ('started', 'enabled')"]
	switch [llength $tasks] {
	    0 { ad_return_complaint 1 "Didn't find task for project \#$project_id" }
	    1 {
		set task_id [lindex $tasks 0]
	    }
	    default {
		# Multiple tasks found.
		# Take just any one assigned to the user, because the user needs to do
		# all of them anyway.
		foreach tid $tasks {
			array set task_info [wf_task_info $tid]
			if {$task_info(this_user_is_assigned_p)} { set task_id $tid}
		}

		if {"" == $task_id} {
		    ad_return_complaint 1 "You are not assigned to any task in project \#$project_id"
		}
	    }
	}
    }

    if {[catch {
	array set task [wf_task_info $task_id]
    } err_msg]} {
                ad_return_complaint 1 "<li><b>Task \#$task_id nicht gefunden</b>:<p>
			Dieser Fehler kann auftreten, wenn ein Administrator einen RFC
			'hart' gel&ouml;scht hat. Im normalen Betrieb sollte das nicht
			passieren.<p>
			Bitte kontaktieren Sie Ihren System Administrator.<p>
		"
		return
    }


    set page_title [lang::message::lookup "" intranet-cust-baselkb.Edit_RFC "Edit RFC"]
    set context_bar [im_context_bar [list /intranet-rfc/projects/ "[lang::message::lookup "" intranet-cust-baselkb.RFCs "RFCs"]"] $page_title]
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id" -default ""]
set current_user_id [ad_maybe_redirect_for_registration]
set object_name [db_string name "select acs_object__name(:conf_id)"]

# ---------------------------------------------------------------
# Get the included hours
# ---------------------------------------------------------------

set params [list \
		[list conf_id $conf_id] \
		[list return_url $return_url] \
		[list enable_master_p 0] \
		[list form_mode display] \
		[list panel_p 1] \
]
set html [ad_parse_template -params $params "/packages/intranet-timesheet2-workflow/www/conf-objects/new"]




