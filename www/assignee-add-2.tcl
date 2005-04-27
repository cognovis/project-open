ad_page_contract {
    Add assignee to task.
} {
    task_id:integer
    party_id:integer
    {return_url "task?[export_url_vars task_id]"}
}
wf_case_add_task_assignment \
	-task_id $task_id \
	-party_id $party_id \
	-permanent

ad_returnredirect $return_url

