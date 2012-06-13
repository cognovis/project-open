# packages/acs-workflow/www/assign-yourself

ad_page_contract {

    This page assigns a task to the user accessing this page.  We do
    this by adding the user to the case level assignments, then
    cancelling the current task and creating a new one.  

    @author Kevin Scaldeferri (kevin@arsdigita.com)
    @creation-date 2000-12-15
    @cvs-id $Id$
} {
    task_id:integer,notnull
    {permanent_p 0}
    {return_url ""}
}

set user_id [ad_conn user_id]
set subsite_id [ad_conn subsite_id]
set reassign_p [permission::permission_p -party_id $user_id -object_id $subsite_id -privilege "wf_reassign_tasks"]
if {!$reassign_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_1]"
    return
}

if {$permanent_p} {
    wf_case_add_task_assignment \
	-task_id $task_id \
	-party_id $user_id \
	-permanent 
} else {
    wf_case_add_task_assignment \
	-task_id $task_id \
	-party_id $user_id
}

if [empty_string_p $return_url] {
    ad_returnredirect task?task_id=$task_id
    return
} 

ad_returnredirect $return_url 