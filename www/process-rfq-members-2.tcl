# /packages/intranet-freelance-rfqs/www/process-rfq-members-2.tcl
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Process the Invite/Confirm/Decline action on one or more RFQ candidates

    @param user_id user_id to add
    @param rfq_id RFQ to which to add 
    @param return_url Return URL

    @author frank.bergmann@project-open.com
} {
    { user_ids:integer,multiple "" }
    { notify_asignee 1 }
    rfq_action
    email_header
    email_body
    rfq_id:integer
    return_url
}

# --------------------------------------------------------
# 
# --------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

set project_id [db_string pid "select rfq_project_id from im_freelance_rfqs where rfq_id = :rfq_id" -default 0]
im_project_permissions $current_user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You have no rights to add members to this object."
    return
}

# No users selected - return to main page
if {0 == [llength $user_ids]} {
    ad_returnredirect $return_url
    return
}

# --------------------------------------------------------
# Defaults & Variables
# --------------------------------------------------------

set system_name [ad_system_name]
set rfq_action_upper "[string toupper [string range $rfq_action 0 0]][string range $rfq_action 1 end]"
set rfq_action_upper_l10n [lang::message::lookup "" intranet-freelance-rfqs.$rfq_action $rfq_action_upper]
set project_name [db_string project_name "select acs_object__name(:project_id)"]
set object_name $project_name
set page_title [lang::message::lookup "" intranet-freelance-rfqs.${rfq_action_upper}_Users "$rfq_action_upper Users"]
set context [list $page_title]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set export_vars [export_form_vars rfq_id return_url]
set current_user_name [db_string cur_user "select im_name_from_user_id(:current_user_id)"]

set object_rel_url [db_string object_url "select url from im_biz_object_urls where url_type = 'view' and object_type = 'im_project'"]

# Get the SystemUrl without trailing "/"
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set sysurl_len [string length $system_url]
set last_char [string range $system_url [expr $sysurl_len-1] $sysurl_len]
if {[string equal "/" $last_char]} {
    set system_url "[string range $system_url 0 [expr $sysurl_len-2]]"
}


set object_url "$system_url$object_rel_url$project_id"
set user_url "/intranet/users/view"

set return_to_previous_page_html [lang::message::lookup "" intranet-freelance-rfqs.Return_to_previous_page "Return to <a href=\"%return_url%\">previous page</a>."]

set answer_type_id 4400
set answer_status_id 4450
	
# Where to preset the WF for confirmation/declination?
set declined_place_key "before_decline"
set confirmed_place_key "before_confirm"

set error_count 0

# ---------------------------------------------------------------
# Get everything about the RFQ and the project
# ---------------------------------------------------------------

db_1row rfq_info "
	select	*,
		im_category_from_id(r.rfq_type_id) as rfq_type,
		rfq_type_cat.aux_string1 as rfq_org_workflow_key
	from
		im_freelance_rfqs r,
		im_projects p,
		im_categories rfq_type_cat
	where
		r.rfq_id = :rfq_id
		and r.rfq_project_id = p.project_id
		and r.rfq_type_id = rfq_type_cat.category_id
"

db_1row current_user_info "
        select  im_name_from_user_id(:current_user_id) as current_user_name,
		first_names as current_user_first_names,
		last_name as current_user_last_name,
		email as current_user_email
        from    cc_users
        where   user_id = :current_user_id
"

set rfq_url [export_vars -base "${system_url}/intranet-freelance-rfqs/new" {{form_mode display} {rfq_id $rfq_id}} ]


# ---------------------------------------------------------------
# Send out emails
# ---------------------------------------------------------------

set result_html "<h2>Sending Emails</h2>\n"
append result_html "<ul>\n"

foreach uid $user_ids {

    set user_id [lindex $user_ids 0]
    db_1row user_info "
        select  user_id,
		first_names,
		last_name,
		email,
		im_name_from_user_id(user_id) as user_name
        from    cc_users
        where   user_id = :uid
    "

    if {[regexp {\ } $email match]} {
	append result_html "<li><a href=[export_vars -base $user_url {user_id}]>$user_name</a>: Found invalid characters in email: '$email' - skipping\n"
	incr error_count
	continue
    }

    db_1row rfq_info "
		select	r.*,
			a.*,
			c.*,
			im_category_from_id(r.rfq_type_id) as rfq_type
		from
			im_freelance_rfqs r
			LEFT OUTER JOIN im_freelance_rfq_answers a ON (
				answer_rfq_id = r.rfq_id
				and answer_user_id = :uid
			)
			LEFT OUTER JOIN wf_cases c ON (a.answer_id = c.object_id)
		where
			r.rfq_id = :rfq_id
    "

    append result_html "</ul>\n<ul>\n<li>$user_name: Started processing: rfq_action=$rfq_action, answer_id=$answer_id\n"

    switch $rfq_action {
	invite {

	    # ---------------------------------------------------------------
	    # Invitation

	    if {"" == $answer_id } {
	
		if [catch {
#		    append result_html "<li>$user_name: Sending email: <pre>ns_sendmail $email $current_user_email \"$email_header\" ... </pre>\n"
		    ns_sendmail $email $current_user_email $email_header $email_body
		} errmsg] {
		    append result_html "<li>$user_name: Problem sending email:<br><pre>$errmsg</pre>\n"
		    incr error_count
	    	} else {
		    append result_html "<li>$user_name: Successfully sent out email:<br><pre>$email_header\n\n$email_body</pre>\n"
		}
	
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
			:answer_type_id,
			:answer_status_id
		    )
	        "]
	
		db_dml update_answer "
			update im_freelance_rfq_answers set
				answer_start_date = now()
			where answer_id = :answer_id
		"
	    } else {
		append result_html "<li>$user_name: No Email sent. The user was already invited.\n"
		incr error_count
	    }
	
	
	    if {0 == $answer_id} {
		ad_return_complaint 1 "Unable to create a base answer object for user $user_name"
		ad_script_abort
	    }



	    # Start workflow case
	    # Context_key not used aparently...
	    set context_key ""
	    set case_id [db_string caseid "select case_id from wf_cases where object_id = :answer_id" -default ""]
	    if {"" == $case_id} {
		set case_id [wf_case_new \
			 $rfq_org_workflow_key \
			 $context_key \
			 $answer_id \
	        ]
	    } else {
		append result_html "<li>$user_name: There is already a workflow for this user.\n"
		incr error_count
	    }
	
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
	
	    if {[llength $enabled_tasks] == 1} {
	
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

	    # Skip sending email at the end
	    continue
	}


	confirm {

	    if [catch {
#	        append result_html "<li>$user_name: Sending email: <pre>ns_sendmail $email $current_user_email \"$email_header\" ... </pre>\n"
		ns_sendmail $email $current_user_email $email_header $email_body
	    } errmsg] {
		append result_html "<li>$user_name: Problem sending email:<br><pre>$errmsg</pre>\n"
		incr error_count
	    } else {
		append result_html "<li>$user_name: Successfully sent out email:<br><pre>$email_header\n\n$email_body</pre>\n"
	    }

	    # Delete all tokens of the case
	    db_dml delete_tokens "delete from wf_tokens where case_id = :case_id and state in ('free', 'locked')"
	
	    # Cancel all active tasks    
	    set tasks_sql "select task_id as wf_task_id from wf_tasks where case_id = :case_id and state in ('started')"
	    db_foreach tasks $tasks_sql { set journal_id [im_workflow_task_action -task_id $wf_task_id -action "cancel" -message "Reassign task"] }
	  
	    set journal_id [db_string journal "
		select journal_entry__new(
			null, 
			:case_id,
			:confirmed_place_key, 
			:confirmed_place_key, 
			now(), 
			:current_user_id, 
			'0.0.0.0', 
			:confirmed_place_key)
	    "]
	
	    # Adding a new token
	    im_exec_dml add_token "workflow_case__add_token (:case_id, :confirmed_place_key, :journal_id)"
	    
	    # Enable the next (cancel) transition
	    im_exec_dml sweep "workflow_case__sweep_automatic_transitions (:case_id, :journal_id)"

	}


	decline {
	    append result_html "<li>$user_name: Declining RFQ: case_id=$case_id\n"

	    if [catch {
#		append result_html "<li>$user_name: Sending email: <pre>ns_sendmail $email $current_user_email \"$email_header\" ... </pre>\n"
		ns_sendmail $email $current_user_email $email_header $email_body
	    } errmsg] {
		incr error_count
		append result_html "<li>$user_name: Problem sending email:<br><pre>$errmsg</pre>\n"
	    } else {
		append result_html "<li>$user_name: Successfully sent out email:<br><pre>$email_header\n\n$email_body</pre>\n"
	    }
	
	    # Delete all tokens of the case
	    db_dml delete_tokens "
	    	delete from wf_tokens
	    	where case_id = :case_id
	    	and state in ('free', 'locked')
	    "
	
	    # Cancel all active tasks    
	    set tasks_sql "
	    	select task_id as wf_task_id
	    	from wf_tasks
	    	where case_id = :case_id
	    	      and state in ('started')
	    "
	    db_foreach tasks $tasks_sql {
	        ns_log Notice "new-rfc: canceling task $wf_task_id"
	        set journal_id [im_workflow_task_action -task_id $wf_task_id -action "cancel" -message "Reassigning task"]
	    }
	  
	    set journal_id [db_string journal "
		select journal_entry__new(
			null, 
			:case_id,
			:declined_place_key, 
			:declined_place_key, 
			now(), 
			:current_user_id, 
			'0.0.0.0', 
			:declined_place_key)
	    "]
	
	    # Adding a new token
	    im_exec_dml add_token "workflow_case__add_token (:case_id, :declined_place_key, :journal_id)"
	    
	    # Enable the next (cancel) transition
	    im_exec_dml sweep "workflow_case__sweep_automatic_transitions (:case_id, :journal_id)"
	
	
	}

    }

}


append result_html "</ul>\n"


if {$error_count == 0} {
    ad_returnredirect $return_url
}

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_freelance_rfqs"]

