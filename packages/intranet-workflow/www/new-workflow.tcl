# /packages/intranet-workflow/www/new-workflow
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Creates a new workflow for a given object
    @author frank.bergmann@project-open.com
} {
    object_id:integer,notnull
    workflow_key:notnull
    { self_assign_first_task_p 0}
    { return_url "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# ToDo: Check security.
# I any registered user allowed to start a workflow around any
# arbitrary object? We may argue yes, because security is dealt
# with on a per-workflow base.

set user_id [ad_maybe_redirect_for_registration]
set page_title "[lang::message::lookup "" intranet-workflow.New_Workflow "New Workflow"]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

# ---------------------------------------------------------------
# Check if the WF-Key is valid
# ---------------------------------------------------------------

# Check that the workflow_key is available
set wf_valid_p [db_string wf_valid_check "
	select count(*)
	from acs_object_types
	where object_type = :workflow_key
"]

if {!$wf_valid_p} {
    ad_return_complaint 1 "Workflow '$workflow_key' does not exist"
    ad_script_abort
}


# ---------------------------------------------------------------
# Check that the object is valid
# ---------------------------------------------------------------

set oname [db_string "select acs_object__name(:object_id)" -default ""]

if {"" == $oname} {
    ad_return_complaint 1 "Unknown object"
    ad_script_abort
}


# ---------------------------------------------------------------
# Start the workflow
# ---------------------------------------------------------------

# Context_key not used aparently...
# ?creation of case?
set context_key ""
set case_id [wf_case_new \
		$workflow_key \
		$context_key \
		$object_id
]



# ---------------------------------------------------------------
# Determine the first task in the case and assign to the current_user.
# Please note that there can be potentially more then
# one of such tasks. However, that would be an error
# of the particular WF design.
# ---------------------------------------------------------------

if {self_assign_first_task_p} {


    # Get the first "enabled" task of the new case_id:
    set enabled_tasks [db_list enabled_tasks "
	select	task_id
	from	wf_tasks
	where	case_id = :case_id
		and state = 'enabled'	
    "]

    if {[llength $enabled_tasks] != 1} {
	ad_return_complaint 1 "Internal Error:<br>
	Didn't find the first task for workflow '$workflow_key'<br>
	There are a total of [llength $enabled_tasks], but exactly 1 expected.<br>
	Please notify your system administrator"
	ad_script_abort
    }
    
    # Get the first one - shouldn't be more...
    set task_id [lindex $enabled_tasks 0]


    # Assign the first task to the user himself and start the task
    set wf_case_assig [db_string wf_case_assignment "
	select workflow_case__add_task_assignment (:task_id, :user_id, 'f')
    "]

    # Start the task. Saves the user the work to press the "Start Task" button.
    # No idea why we have to deal with journal_id. I guess it's been designed
    # into the code to force the users to create WF Journal entries?
    #
    set action "start"
    set message ""
    set action_ip [ad_conn peeraddr]
    set journal_id [db_string wf_begin_task_start "
	select workflow_case__begin_task_action (
		:task_id,
		:action,
		:action_ip,
		:user_id,
		:message
	)
     "]

    set journal_id [db_string wf_start_task "
	select workflow_case__start_task (
		:task_id,
		:user_id,
		:journal_id
	)
    "]

    # Where to go now?
    if {"" == $return_url} {
	set return_url [export_vars -base "/[im_workflow_url]/task" {task_id}]
    }

}

# ---------------------------------------------------------------
# Where to go now?
# => To the particular workflow case
# ---------------------------------------------------------------


if {"" == $return_url} {
    set return_url "/intranet/"
}

ad_returnredirect $return_url

