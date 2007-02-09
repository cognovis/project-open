# /intranet-workflow/www/task-cancel.tcl

ad_page_contract {
    Cancel a specific task
    @author Frank Bergmann
} {
    task_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set reassign_perms_p [im_permission $user_id "wf_reassign_tasks"]
set user_name [db_string uname "select im_name_from_user_id(:user_id)"]

im_workflow_task_action \
	-task_id $task_id \
	-action "cancel" \
	-message "Canceling transition by request of $user_name"

# Old method: This doesn't work if the user isn't assigned himself
# set journal_id [wf_task_action $task_id "cancel"]

ad_returnredirect $return_url




