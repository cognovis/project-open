# /packages/intranet-freelance-rfqs/www/invite
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Invite one or more users to a RFQ

    @param user_id user_id to add
    @param rfq_id RFQ to which to add 
    @param return_url Return URL

    @author frank.bergmann@project-open.com
} {
    { user_id:integer,multiple "" }
    { notify_asignee 1 }
    rfq_id:integer
    project_id:integer
    { role_id:integer 0 }
    return_url
    { also_add_to_group_id:integer "" }
}

# --------------------------------------------------------
# 
# --------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

im_project_permissions $current_user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You have no rights to add members to this object."
    return
}

# No users selected - return to main page
if {0 == [llength $user_id]} {
    ad_returnredirect $return_url
    return
}

# --------------------------------------------------------
# Defaults & Variables
# --------------------------------------------------------

set system_name [ad_system_name]
set project_name [db_string project_name "select acs_object__name(:project_id)"]
set object_name $project_name
set page_title [lang::message::lookup "" intranet-freelance-rfqs.Invite_Users "Invite Users"]
set context [list $page_title]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set export_vars [export_form_vars user_id project_id role_id return_url]
set current_user_name [db_string cur_user "select im_name_from_user_id(:current_user_id)"]

set object_rel_url [db_string object_url "select url from im_biz_object_urls where url_type = 'view' and object_type = 'im_project'"]
set role_name [db_string role_name "select im_category_from_id(:role_id)" -default "Member"]

# Get the SystemUrl without trailing "/"
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set sysurl_len [string length $system_url]
set last_char [string range $system_url [expr $sysurl_len-1] $sysurl_len]
if {[string equal "/" $last_char]} {
    set system_url "[string range $system_url 0 [expr $sysurl_len-2]]"
}

set object_url "$system_url$object_rel_url$project_id"


# ---------------------------------------------------------------
# Get everything about the RFQ
# ---------------------------------------------------------------

db_1row rfq_info "
	select	*
	from	im_freelance_rfqs r
	where	r.rfq_id = :rfq_id
"

# ---------------------------------------------------------------
# Create a new RFQ Answer (base object for workflow)
# ---------------------------------------------------------------

foreach uid $user_id {

    set answer_type_id 4400
    set answer_status_id 4450

    # Check if there is already an "RFQ Answer" for this rfq/project/user
    # The user could "stop" them using the GUI...
    set exists_p [db_string answer_exists "
	select count(*) 
	from im_freelance_rfq_answers a
	where 	a.answer_rfq_id = :rfq_id 
		and a.answer_project_id = :project_id 
		and a.answer_user_id = :uid
    "]
    if {$exists_p > 0} { continue }


    set answer_id [db_string new_answer "
	select im_freelance_rfq_answer__new (
		null,
		'im_freelance_rfq_answer',
		now(),
		:current_user_id,
		'[ad_conn peeraddr]',
		null,
		:uid,
		:rfq_id,
		:project_id,
		:answer_type_id,
		:answer_status_id
	)
    "]

    if {0 == $answer_id} {
	ad_return_complaint 1 "Unable to create a base answer object"
	ad_script_abort
    }

    # ---------------------------------------------------------------
    # Start workflow case

    # Context_key not used aparently...
    set context_key ""
    
    set case_id [wf_case_new \
		 $rfq_workflow_key \
		 $context_key \
		 $answer_id \
    ]

    # ---------------------------------------------------------------
    # Determine the first task in the case to be executed
    # Please note that there can be potentially more then
    # one of such tasks. However, that would be an error
    # of the particular WF design.vv

    # Get the first "enabled" task of the new case_id:
    set enabled_tasks [db_list enabled_tasks "
	select	task_id
	from	wf_tasks
	where	case_id = :case_id
		and state = 'enabled'	
    "]

    if {[llength $enabled_tasks] != 1} {
	ad_return_complaint 1 "Internal Error:<br>
	Didn't find the first task for workflow '$wf_key'<br>
	There are a total of [llength $enabled_tasks], but exactly 1 expected.<br>
	Please notify your system administrator"
	ad_script_abort
    }
    
    # Get the first one - shouldn't be more...
    set task_id [lindex $enabled_tasks 0]
    
    # Assign the first task to the user himself
    set wf_case_assig [db_string wf_case_assignment "
	select workflow_case__add_task_assignment (:task_id, :uid, 't')
    "]

    # Start the task.
    # This step saves the user the work to press the "Start Task" button.
    set action "start"
    set message ""
    set action_ip [ad_conn peeraddr]
    set journal_id [db_string wf_begin_task_start "
	select workflow_case__begin_task_action (
		:task_id,
		:action,
		:action_ip,
		:uid,
		:message
	)
    "]

    set journal_id [db_string wf_start_task "
	select workflow_case__start_task (
		:task_id,
		:uid,
		:journal_id
	)
    "]
}


# ---------------------------------------------------------------
# Where to go now?
# ---------------------------------------------------------------

ad_returnredirect $return_url

