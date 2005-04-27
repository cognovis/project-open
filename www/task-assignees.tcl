ad_page_contract {
    Remove one or more assignees for a task.
} {
    task_id:integer
    {return_url ""}
} -properties {
    context
    task:onerow
    assignees:multirow
    effective_assignees:multirow
    done_action_url
    done_export_vars
}

array set task [wf_task_info $task_id]

set party_id [ad_conn user_id]
set sub_return_url "[ns_conn url]?[export_vars -url {task_id return_url}]"
set task(add_assignee_url) "assignee-add?[export_vars -url {task_id {return_url $sub_return_url}}]"
set task(assign_yourself_url) "assignee-add-2?[export_vars -url {task_id party_id {return_url $sub_return_url}}]"


set context [list [list "case?[export_vars -url {{case_id $task(case_id)}}]" "$task(object_name) case"] [list "task?[export_vars -url {task_id}]" "$task(task_name)"] "Assignees"]

db_multirow assignees assignees {
    select p.party_id,
           acs_object.name(p.party_id) as name,
           p.email,
           '' as remove_url,
           o.object_type
    from   wf_task_assignments ta,
           parties p,
           acs_objects o
    where  ta.task_id = :task_id
    and    p.party_id = ta.party_id
    and    o.object_id = p.party_id
} {
    set remove_url "assignee-remove-2?[export_vars -url {task_id party_id {return_url $sub_return_url}}]"
    if { [string equal $object_type "user"] } {
	set url "/shared/community-member?[export_vars -url {{user_id $party_id}}]"
    }
}
set __i 0
db_multirow effective_assignees effective_assignees {
    select distinct u.user_id,
           acs_object.name(u.user_id) as name,
           p.email
    from   wf_task_assignments ta,
           party_approved_member_map m,
           parties p,
           users u
    where  ta.task_id = :task_id
    and    m.party_id = ta.party_id
    and    p.party_id = m.member_id
    and    u.user_id = p.party_id
} 

if { [empty_string_p $return_url] } {
    set return_url "task?[export_vars -url {task_id}]"
}
set done_export_vars [export_vars -form [wf_split_query_url_to_arg_spec $return_url]]
set done_action_url [lindex [split $return_url "?"] 0]

ad_return_template


