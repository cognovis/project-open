# /packages/intranet-forum/www/intranet-forum/forum/new-tind-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    process a new topic form submission
    @param receive_updates: 
        all, none, major (=issue resolved, task done)
    @param actions: 
        accept, reject, clarify, close

    @action_type: 
        new_message, edit_message, undefined, reply_message

    @author frank.bergmann@project-open.com
} {
    action_type
    {actions ""}
    {comments:trim ""}
    owner_id:integer
    old_asignee_id:integer
    object_id:integer
    topic_id:integer
    parent_id:integer
    {topic_type_id 0}
    {topic_status_id 0}
    {old_topic_status_id 0}
    {scope "pm"}
    {subject:trim}
    {message:trim}
    {priority "5"}
    {asignee_id ""}
    {due_date:array,date ""}
    {receive_updates "major"}
    {read_p "f"}
    {folder_id "0"}
    return_url
    {submit_save ""}
    {submit_close ""}
    {submit_accept ""}
    {submit_reject ""}
    {submit_clarify ""}
}

# ------------------------------------------------------------------
# Security, Parameters & Default
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set exception_text ""
set exception_count 0

if { ![info exists subject] || $subject == "" } {
    append exception_text "<li>You must enter a subject line"
    incr exception_count
}

if { [info exists subject] && [string match {*\"*} $subject] } { 
    append exception_text "<li>Your topic name cannot include string quotes.  It makes life too difficult for this collection of software."
    incr exception_count
}

# check for not null start date
if { [info exists due_date(date) ] } {
   set due $due_date(date)
} else {
    set due ""
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# Only incidents and tasks have priority, status, asignees and 
# due_dates
#
set task_or_incident_p 0
if {$topic_type_id == 1102 || $topic_type_id == 1104} {
    set task_or_incident_p 1
}

if {"" != $comments} {

    set user_name [db_string get_user_name "select im_name_from_user_id(:user_id) from dual"]
    set today_date [db_string get_today_date "select sysdate from dual"]
    append message "\n\n\[Comment from $user_name on $today_date\]:\n$comments"
}

# ---------------------------------------------------------------------
# Reply to the topic
# ---------------------------------------------------------------------

if {[string equal $actions "reply"]} {

    ad_returnredirect "/intranet-forum/new-tind"

}



# ------------------------------------------------------------------
# Save the im_forum_topics record
# ------------------------------------------------------------------

if {[string equal $action_type "new_message"] || [string equal $action_type "reply_message"]} {

    # We are creating a new item

    db_transaction {
	db_dml topic_insert "
insert into im_forum_topics (
	topic_id, object_id, parent_id, topic_type_id, topic_status_id,
	posting_date, owner_id, scope, subject, message, priority, 
	asignee_id, due_date
) values (
	:topic_id, :object_id, :parent_id, :topic_type_id, :topic_status_id,
	sysdate, :owner_id, :scope, :subject, :message, :priority, 
        :asignee_id, :due
)"
    } on_error {
        ad_return_error "Error adding a new topic" "
	The database rejected the addition of discussion topic 
	\"$subject\". Here the error message: <pre>$errmsg\n</pre>\n"
    }

} else {

    # We are modifying an existing item
    db_transaction {
	db_dml topic_update "
update im_forum_topics set 
	object_id=:object_id, 
	parent_id=:parent_id,
	topic_type_id=:topic_type_id,
	topic_status_id=:topic_status_id,
	posting_date=sysdate,
	owner_id=:owner_id,
	scope=:scope, 
	subject=:subject,
	message=:message,
	priority=:priority, 
	asignee_id=:asignee_id, 
	due_date=:due
where topic_id=:topic_id"
    } on_error {
        ad_return_error "Error modifying a topic" "
	The database rejected the modification of a of discussion topic 
	\"$subject\". Here the error message: <pre>$errmsg\n</pre>\n"
    }
}

# ---------------------------------------------------------------------
# Save the im_forum_topic_user_map record
# ---------------------------------------------------------------------

# im_forum_topics_user_map may or may not exist for every user.
# So we create a record just in case, even if the SQL fails.

db_transaction {
    db_dml im_forum_topic_user_map_insert "
	insert into im_forum_topic_user_map 
	(topic_id, user_id, read_p, folder_id, receive_updates) values 
	(:topic_id, :user_id, :read_p, :folder_id, :receive_updates)"
} on_error {
    # nothing - may already exist...
}

# Now let's update the existing entry
db_transaction {
	db_dml im_forum_topic_user_map_update "
update im_forum_topic_user_map set 
	read_p=:read_p,
	folder_id=:folder_id, 
	receive_updates=:receive_updates
where 
	topic_id=:topic_id
	and user_id=:user_id"
} on_error {
        ad_return_error "Error modifying a im_forum_topic_user_map" "
	The database rejected the modification of a of discussion topic 
	\"$subject\". Here the error message: <pre>$errmsg\n</pre>\n"
}

# ---------------------------------------------------------------------
# Alert about asignee_changes
# ---------------------------------------------------------------------

ns_log Notice "new-tind-2: asignee_id=$asignee_id, old_asignee_id=$old_asignee_id"

# Inform the asignee that he has got a new task/incident
#
if {$asignee_id != $old_asignee_id} {

    # Always send a mail to a new asignee
    #
    set msg_url "[ad_parameter SystemUrl]"
    append msg_url "/intranet-forum/view?topic_id=$topic_id"
    set topic_type [db_string topic_type "select category from im_categories where category_id=:topic_type_id"]
    set msg_subject "New $topic_type: $subject"
#    im_send_alert $asignee_id "hourly" $msg_url $msg_subject $message
###!!! ToDo: enable alerts

    # Inform the owner about the change except if it iss a client
    # or if it is someone who 
}

# ---------------------------------------------------------------------
# Close the ticket
# ---------------------------------------------------------------------

if {[string equal $actions "close"]} {
    # ToDo: Security Check
    
    # Close the existing ticket.
    set topic_status_id [im_topic_status_id_closed]
    db_transaction {
	db_dml topic_close "
update im_forum_topics set topic_status_id = :topic_status_id
where topic_id=:topic_id"
    } on_error {
        ad_return_error "Error modifying a topic" "
	Error closing \"$subject\": <pre>$errmsg\n</pre>\n"
    }

    # Send a mail to all subscribed users
    #
    set stakeholder_sql "
select	user_id
from	im_forum_topic_user_map m
where	m.topic_id=:topic_id
	and receive_updates <> 'none'
"
    db_foreach update_stakeholders $stakeholder_sql {

        set msg_url "[ad_parameter SystemUrl]"
        append msg_url "/intranet-forum/view?topic_id=$topic_id"
        set topic_type [db_string topic_type "select category from im_categories where category_id=:topic_type_id"]
        set msg_subject "Closed $topic_type: $subject"
        im_send_alert $asignee_id "hourly" $msg_url $msg_subject $message
    }
}


# ---------------------------------------------------------------------
# Accept the ticket
# ---------------------------------------------------------------------

if {[string equal $actions "accept"]} {
    # ToDo: Security Check
    
    # Set the status to "accepted"
    set topic_status_id [im_topic_status_id_accepted]
    db_transaction {
	db_dml topic_close "
update im_forum_topics set topic_status_id = :topic_status_id
where topic_id=:topic_id"
    } on_error {
        ad_return_error "Error modifying a topic" "
	Error closing \"$subject\": <pre>$errmsg\n</pre>\n"
    }

    # Send email notifications only to "all changes".
    #
    set stakeholder_sql "
select	user_id
from	im_forum_topic_user_map m
where	m.topic_id=:topic_id
	and receive_updates='all'
"
    db_foreach update_stakeholders $stakeholder_sql {

        set msg_url "[ad_parameter SystemUrl]"
        append msg_url "/intranet-forum/view?topic_id=$topic_id"
        set topic_type [db_string topic_type "select category from im_categories where category_id=:topic_type_id"]
        set msg_subject "Accepted $topic_type: $subject"
        im_send_alert $asignee_id "hourly" $msg_url $msg_subject $message
    }
}


db_release_unused_handles 
ad_returnredirect $return_url

