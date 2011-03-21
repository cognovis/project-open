ad_page_contract {
    Remove assignee from task.
} {
    task_id:integer
    party_id:integer
    {return_url "task-assignees?[export_vars -url {task_id}]"}
}

# should add some check that you aren't deleting an assignment 
# if the person has actually started the task.

wf_case_remove_task_assignment \
	-task_id $task_id \
	-party_id $party_id \
	-permanent

ad_returnredirect $return_url
