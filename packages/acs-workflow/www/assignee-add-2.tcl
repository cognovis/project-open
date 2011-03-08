ad_page_contract {
    Add assignee to task.
} {
    task_id:integer
    party_id:integer
    {return_url "task?[export_url_vars task_id]"}
}

# ------------------------------------------------------------
# Check Permissions		

set user_id [ad_conn user_id]
set subsite_id [ad_conn subsite_id]
set reassign_p [permission::permission_p -party_id $user_id -object_id $subsite_id -privilege "wf_reassign_tasks"]
if {!$reassign_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_1]"
    return
}

# ------------------------------------------------------------

wf_case_add_task_assignment \
	-task_id $task_id \
	-party_id $party_id \
	-permanent

ad_returnredirect $return_url

