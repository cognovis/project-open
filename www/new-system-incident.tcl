# /packages/intranet-forum/www/intranet/forum/new-system-error.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Creates a new system error from a "Report this error" button.
    Works as an inteface between the request procesor generating
    the incident and the forum module that works differntly then
    the old ACS ticket tracker.

    So there are several difficulties:
    - This page is publicly accessible, so it may be used for
      denial of service attacks by flooding the system with
      incidents
    - We have to route the incidents to 

    @author frank.bergmann@project-open.com
} {
    error_url:trim
    error_info:trim
    error_first_names:trim
    error_last_name:trim
    error_user_email:trim
    core_version:trim
    system_url:trim
    publisher_name
}

ns_log Notice "new-system-incident: error_url=$error_url"
ns_log Notice "new-system-incident: error_info=$error_info"
ns_log Notice "new-system-incident: error_first_names=$error_first_names"
ns_log Notice "new-system-incident: error_last_name=$error_last_name"
ns_log Notice "new-system-incident: error_user_email=$error_user_email"
ns_log Notice "new-system-incident: core_version=$core_version"

# Maximum number of incidents per day per IP address
# Designed to avoid denial or service attacks
set max_dayily_incidents 3

# -----------------------------------------------------------------
# Lookup user_id or create entry
# -----------------------------------------------------------------
# Keep in mind that the email and other data might be completely fake.

ns_log Notice "Check if the user already has an account: $error_user_email"
set error_user_id [db_string user_id "select party_id from parties where lower(email) = lower(:error_user_email)" -default 0]

if {0 != $error_user_id} {
    # The user already exists:
    # Make sure there are no more then $max_incidents today from the same IP
    
    # ToDo: Implement !!!

} else {

    # Doesn't exist yet - let's create it
    ns_log Notice "new-system-incident: creating new user '$error_user_email'"
    array set creation_info [auth::create_user \
	-email $error_user_email \
	-url $error_url \
	-verify_password_confirm \
	-first_names $error_first_names \
	-last_name $error_last_name \
	-screen_name "$error_first_names $error_last_name" \
	-username "$error_first_names $error_last_name" \
	-password $error_first_names \
	-password_confirm $error_first_names \
    ]

    ns_log Notice "new-system-incident: checking for '$error_user_email' after creation"
    set error_user_id [db_string user_id "select party_id from parties where lower(email) = lower(:error_user_email)" -default 0]

}

if {!$error_user_id} {
    # create user didn't succeed...
    # ToDo!!!
    ad_return_complaint 1 "<li>Error accepted"
    return
}

# -----------------------------------------------------------------
# Create an incident (without mail alert)
# -----------------------------------------------------------------

set topic_id [db_nextval "im_forum_topics_seq"]
set parent_id ""
set owner_id $error_user_id
set scope "group"
set subject $error_url
set message $error_info
set priority 3
set asignee_id ""
set due [db_string tomorrow "select sysdate+1 from dual"]

# 1102 is "Incident"
set topic_type_id 1102

# 1202 is "Open"
set topic_status_id 1202


db_transaction {
        db_dml topic_insert "
INSERT INTO im_forum_topics (
        topic_id, group_id, parent_id, topic_type_id, topic_status_id,
        posting_date, owner_id, scope, subject, message, priority,
        asignee_id, due_date
) VALUES (
        :topic_id, :report_group_id, :parent_id, :topic_type_id, :topic_status_id,
        sysdate, :owner_id, :scope, :subject, :message, :priority,
        :asignee_id, :due
)"
} on_error {
    ad_return_error "Error adding a new topic" "
    <LI>There was an error adding your ticket to our system.<br>
    Please send an email to <A href=\"mailto:[ad_parameter "SystemOwner" "" ""]\">
    our webmaster</a>, thanks."
}


set page_body "
<H1>Incident Received</H1>

Your incident hast been received.<br>
You will be notified as soon as possible.
"


doc_return  200 text/html [im_return_template]








