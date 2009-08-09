# /packages/intranet-workflow/www/projects/rfc-delete-2.tcl
#

ad_page_contract {
    View all the info about a specific project.

    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { button_cancel "" }
    { button_confirm "" }
    { task_id:integer 0 }
    { project_id:integer 0 }
    return_url
    { place_key "tagged" }
    { action_pretty "" }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "RFC l&ouml;schen"
set date_format "YYYY-MM-DD"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# ---------------------------------------------------------------------
# Cancel all transitions and move to "rfc_cancel"
# ---------------------------------------------------------------------


if {"" != $button_confirm} {

    # Get the general case_id
    # "Cancel" all the task in the current case
    set case_id [db_string case "select case_id from wf_tasks where task_id = :task_id" -default 0]
    if {0 == $case_id} {
	set case_id [db_string case2 "select case_id from wf_cases where object_id = :project_id" -default 0]
    }

    # Reactivate...
    if {"before_fullfill_rfc" == $place_key} {
	db_dml delete_end_token "
		delete from wf_tokens
		where	case_id = :case_id
			and place_key = 'end'
	"

	db_dml update_cases "
		update wf_cases
		set state = 'active'
		where case_id = :case_id
        "
	
	db_dml update_projects "
		update im_projects
		set project_status_id = [im_project_status_open]
		where project_id = :project_id
        "
	
	im_project_audit -project_id $project_id

}

    ns_log Notice "new-rfc: case_id=$case_id"
    set journal_id ""
    
    # Delete all tokens of the case
    db_dml delete_tokens "
    	delete from wf_tokens
    	where case_id = :case_id
    	and state in ('free', 'locked')
    "
    
    set tasks_sql "
    	select task_id as wf_task_id
    	from wf_tasks
    	where case_id = :case_id
    	      and state in ('started')
    "
    db_foreach tasks $tasks_sql {
        ns_log Notice "new-rfc: canceling task $wf_task_id"
        set journal_id [im_workflow_task_action -task_id $wf_task_id -action "cancel" -message "Reassigning task"]
    }
  
    ns_log Notice "new-rfc: adding a token to place=$place_key"
    im_exec_dml add_token "workflow_case__add_token (:case_id, :place_key, :journal_id)"

    # enable the very first transition
    im_exec_dml sweep "workflow_case__sweep_automatic_transitions (:case_id, :journal_id)"
}

