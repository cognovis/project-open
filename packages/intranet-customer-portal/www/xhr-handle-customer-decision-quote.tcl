# /packages/intranet-customer-portal/www/xhr-handle-customer-decision-quote.tcl
#
# Copyright (C) 2011 ]project-open[
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    @param 
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    inquiry_id:integer 
    project_id:integer 
    {decision ""}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

if { "rejected" != $decision && "accept" != $decision } {
    ns_return 406 text/html 0
}

set user_id [ad_maybe_redirect_for_registration]

set project_status_quote_rejected 77 
set project_status_quote_accepted 380 

if { "rejected" == $decision  } {
    db_dml update "update im_projects set project_status_id = $project_status_quote_rejected where project_id = :project_id"
    db_dml update "update im_inquiries_customer_portal set status_id = $project_status_quote_rejected where inquiry_id = :inquiry_id"
    set attribute_value f
} else {
    db_dml update "update im_projects set project_status_id = $project_status_quote_accepted where project_id = :project_id"
    db_dml update "update im_inquiries_customer_portal set status_id = $project_status_quote_accepted where inquiry_id = :inquiry_id"
    set attribute_value t
}


set workflow_key [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "KeyRFQWorkflow" -default "project_approval3_wf"]
set case_id [db_string get_case_id "select case_id from wf_cases where workflow_key='$workflow_key' and object_id=:project_id" -default 0]

set enabled_tasks [db_list enabled_tasks "
	select task_id
	from wf_tasks
	where case_id = :case_id
	and state = 'enabled'
    "]

ns_log NOTICE "Number Tasks found: [db_string get_view_id "select count(*) from wf_tasks where case_id = :case_id and state = 'enabled'" -default 0]"


foreach task_id $enabled_tasks {

    ns_log NOTICE "Loop entry for task_id: $task_id, case_id: $case_id"

    # Assign the first task to the user himself and start the task

    ns_log NOTICE "Now assigning task_id: $task_id to user: $user_id"
    set wf_case_assig [db_string wf_assig "select workflow_case__add_task_assignment (:task_id, :user_id, 'f')"]

    # Start the task. Saves the user the work to press the "Start Task" button.
    ns_log NOTICE "Now set task action to 'start' for task_id: $task_id"
    set journal_id [db_string wf_action "select workflow_case__begin_task_action (:task_id,'start','[ad_conn peeraddr]',:user_id,'')"]

    ns_log NOTICE "Now starting task_id: $task_id"
    set journal_id2 [db_string wf_start "select workflow_case__start_task (:task_id,:user_id,:journal_id)"]

    # Set attribute name 
    ns_log NOTICE "Now setting attribute value to: $attribute_value (journal_id: $journal_id, attribute: 'client_decision')"
    set ttt [db_string wf_start "select workflow_case__set_attribute_value(:journal_id,'client_decision','$attribute_value')"]

    # Finish the task. That forwards the token to the next transition.
    ns_log NOTICE "Now finishing taskd_id: $task_id, journal_id: $journal_id"
    set journal_id3 [db_string wf_finish "select workflow_case__finish_task(:task_id, :journal_id)"]
}


set enabled_tasks [db_list enabled_tasks "
        select task_id
        from wf_tasks
        where case_id = :case_id
        and state = 'enabled'
    "]

ns_log NOTICE "Number Tasks found: [db_string get_view_id "select count(*) from wf_tasks where case_id = :case_id and state = 'enabled'" -default 0]"


foreach task_id $enabled_tasks {

    ns_log NOTICE "Loop entry for task_id: $task_id, case_id: $case_id"

    # Assign the first task to the user himself and start the task

    ns_log NOTICE "Now assigning task_id: $task_id to user: $user_id"
    set wf_case_assig [db_string wf_assig "select workflow_case__add_task_assignment (:task_id, :user_id, 'f')"]

    # Start the task. Saves the user the work to press the "Start Task" button.
    ns_log NOTICE "Now set task action to 'start' for task_id: $task_id"
    set journal_id [db_string wf_action "select workflow_case__begin_task_action (:task_id,'start','[ad_conn peeraddr]',:user_id,'')"]

    ns_log NOTICE "Now starting task_id: $task_id"
    set journal_id2 [db_string wf_start "select workflow_case__start_task (:task_id,:user_id,:journal_id)"]

    # Finish the task. That forwards the token to the next transition.
    ns_log NOTICE "Now finishing taskd_id: $task_id, journal_id: $journal_id"
    set journal_id3 [db_string wf_finish "select workflow_case__finish_task(:task_id, :journal_id)"]
}

ns_return 200 text/html 1