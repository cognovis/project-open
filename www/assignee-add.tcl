ad_page_contract {
    Add assignee
} {
    task_id:integer
    return_url:optional
} -properties {
    context
    export_vars
    party_widget
    return_url
    focus
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

array set task [wf_task_info $task_id]
set context [list [list "case?[export_vars -url {{case_id $task(case_id)}}]" "$task(object_name) case"] [list "task?[export_vars -url {task_id}]" "$task(task_name)"] "Add assignee"]
set export_vars [export_vars -form {task_id return_url}]
set focus "assign.party_id"
set party_widget "<select name=\"party_id\">\n"

set count 0
db_foreach unassigned_parties {
    select p.party_id,
           acs_object.name(p.party_id) as name,
           p.email
      from parties p
	   groups g
     where p.party_id = g.group_id
	   and not exists (
		select 1 
		from wf_task_assignments ta 
		where ta.task_id = :task_id and ta.party_id = p.party_id
	   )
    	   and 0 < (
		select count(*)
                from   users u, party_approved_member_map m
                where  m.party_id = p.party_id
                and    u.user_id = m.member_id
	   )
} {
    incr count
    append party_widget "<option value=\"$party_id\">$name [ad_decode $email "" "" "(<a href=\"mailto:$email\">$email</a>)"]</option>\n"
}
append party_widget "</select>"

if { $count == 0 } {
    set party_widget ""
    set focus ""
}

ad_return_template

