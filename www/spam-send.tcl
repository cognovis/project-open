ad_page_contract {
    insert a spam message into spam_messages table.  Message will 
    be queued for sending by a sweeper procedure when the spam is confirmed.
} { 
    subject:notnull
    {body_plain:trim ""}
    {{body_html:allhtml,trim} ""}
    send_date_ansi:notnull
    send_time_12hr:notnull
    spam_id:naturalnum
    sql_query
    object_id
}

if {$object_id == ""} {
    set object_id $spam_id
}

# ad_require_permission $object_id write

#double-click protection
set already_there [db_string spam_check_double_click "
  select count(1) from spam_messages where spam_id=:spam_id"]
if {$already_there} {
    ad_return_complaint 1 "This message has already been queued for sending.
    You can <a href=\"spam-edit?spam_id=$spam_id\">edit it</a> if you wish."
    return
}

if {$sql_query == ""} { 
    ad_return_complaint 1 "No user query supplied.  You can't invoke this \
	    page directly."
    return 
}

# make sure spam cannot be sent by regular user
set approved_p "f"

# consider a user to be an admin if he is an admin for the object_id
# or if he is an admin for the spam package

if {$object_id != "" && [ad_permission_p $object_id "admin"]} {
    set approved_p "t"
} elseif {$object_id == "" && [ad_permission_p [ad_conn package_id] "admin"]} {
    set approved_p "t"
} 

set date "$send_date_ansi $send_time_12hr"

spam_new_message \
	-context_id $object_id \
	-send_date $date \
	-spam_id $spam_id \
	-subject $subject \
	-plain $body_plain \
	-html $body_html  \
	-sql $sql_query \
	-approved_p $approved_p

# spam is now in database but is not queued.
# there will be a "sweeper" that spam to the outgoing
# acs-messaging queue when spam is confirmed.

# inserted and in the queue; now display a message to the user 
# telling them how to link, etc.

set context {queued}

ad_return_template


    
    

