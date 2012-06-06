# /packages/intranet-translation/www/trans-tasks/task-assignments-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Takes commands from the /intranet/projects/view
    page and saves changes, deletes tasks and scans for Trados
    files.

    @param return_url the url to return to
    @param project_id group id
} {
    return_url
    project_id:integer

    task_status_id:array
    task_trans:array
    task_edit:array
    task_proof:array
    task_other:array
    trans_end:array
    proof_end:array
    edit_end:array
    other_end:array
}

set user_id [ad_maybe_redirect_for_registration]

set task_list [array names task_status_id]

foreach task_id $task_list {
    
    set trans $task_trans($task_id)
    set edit $task_edit($task_id)
    set proof $task_proof($task_id)
    set other $task_other($task_id)
    set trans_end_date $trans_end($task_id)
    set edit_end_date $edit_end($task_id)
    set proof_end_date $proof_end($task_id)
    set other_end_date $other_end($task_id)

    set task_workflow_update_sql "
update im_trans_tasks set
	trans_id=:trans,
	edit_id=:edit,
	proof_id=:proof,
	other_id=:other,
        trans_end_date=:trans_end_date,
        edit_end_date=:edit_end_date,
        proof_end_date=:proof_end_date,
        other_end_date=:other_end_date
where
	task_id=:task_id
"
    db_dml update_workflow $task_workflow_update_sql

    # Notify system about the joyful act
    im_user_exit_call trans_task_assign $task_id
    im_audit -object_type "im_trans_task" -action after_update -object_id $task_id

}

db_release_unused_handles
ad_returnredirect $return_url

