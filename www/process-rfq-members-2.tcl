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
    @param rfq_action_id Determines what should happend with the user. Values:
	invited		4470
	confirmed	4472
	declined	4474
	canceled	4476
	closed		4478
	deleted		4499
    @author frank.bergmann@project-open.com
} {
    { user_ids:integer,multiple "" }
    { send_me_a_copy_p 1 }
    { add_to_project_p 0 }
    { email_send "" }
    { email_nosend "" }
    rfq_action_id
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
set rfq_action [im_category_from_id $rfq_action_id]
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
		im_name_from_user_id(user_id) as user_name,
		im_name_from_user_id(user_id) as name
	from    cc_users
	where   user_id = :uid
    "

    if {[regexp {\ } $email match]} {
	append result_html "<li><font color=red><a href=[export_vars -base $user_url {user_id}]>$user_name</a>: Found invalid characters in email: '$email' - skipping</font>\n"
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

    # Create an answer object if not there already
    if {"" == $answer_id } {
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
			[im_freelance_rfq_answer_type_default],
			:rfq_action_id
		    )
	"]
	
	db_dml update_answer "
		update im_freelance_rfq_answers set
			answer_start_date = now()
		where answer_id = :answer_id
	"
    }

    # Update the status of the answer to the "rfq_action_id".
    db_dml update_answer "
		update im_freelance_rfq_answers set
			answer_status_id = :rfq_action_id
		where answer_id = :answer_id
    "


    # add the user to the current project?
    if {$add_to_project_p} {
	im_biz_object_add_role $uid $project_id [im_biz_object_role_full_member]
    }


    # ---------------------------------------------------------------
    # Substitute variables
    # ---------------------------------------------------------------

    set auto_login [im_generate_auto_login -user_id $user_id]
    set rfq_url [export_vars -base "${system_url}/intranet-freelance-rfqs/new-answer" {rfq_id user_id auto_login} ]

    set substitution_list [list \
	rfq_type $rfq_type \
	rfq_name $rfq_name \
	rfq_url $rfq_url \
	project_name $project_name \
	name $name \
	first_names $first_names \
	last_name $last_name \
	email $email \
	auto_login $auto_login \
	current_user_name $current_user_name \
	current_user_email $current_user_email \
	current_user_first_names $current_user_first_names \
	current_user_last_name $current_user_last_name \
    ]

    set email_header [lang::message::format $email_header $substitution_list]
    set email_body [lang::message::format $email_body $substitution_list]

    if {"" != $email_send} {

	# send out the email
	if [catch {
	    ns_sendmail $email $current_user_email $email_header $email_body
	} errmsg] {
	    append result_html "<li><font color=red>$user_name: Problem sending email:<br><pre>$errmsg</pre></font>\n"
	    incr error_count
	} else {
	    append result_html "<li>$user_name: Successfully sent out email:<br><pre>$email_header\n\n$email_body</pre>\n"
	}

    }
}


if {$send_me_a_copy_p} {

    # send out the email
    if [catch {
	ns_sendmail $current_user_email $current_user_email $email_header $email_body
    } errmsg] {
	# No action...
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

