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
    {return_url ""}
}

set user_id [ad_conn user_id]

wf_case_add_task_assignment \
	-task_id $task_id \
	-party_id $user_id \
	-permanent

if [empty_string_p $return_url] {
    ad_returnredirect task?task_id=$task_id
    return
} 

ad_returnredirect $return_url 