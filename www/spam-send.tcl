ad_page_contract {
    insert a spam message into spam_messages table.  Message will 
    be queued for sending by a sweeper procedure when the spam is confirmed.
} { 
    subject:notnull
    {body_plain:trim ""}
    {body_html:allhtml,trim ""}
    send_date_ansi:notnull
    send_time_12hr:notnull
    spam_id:naturalnum
    sql_query
    object_id
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set context [list "confirm"]

set user_id [ad_get_user_id]

#double-click protection
set already_there [db_string spam_check_double_click " select count(1) from spam_messages where spam_id=:spam_id"]

if {$already_there} {
    ad_return_complaint 1 "This message has already been queued for sending.
    You can <a href=\"spam-edit?spam_id=$spam_id\">edit it</a> if you wish."
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


# ------------------------------------------------------
# Send message
# ------------------------------------------------------


db_foreach spam_full_sql "" {

    set message [subst $body_plain]
    set subject [subst $subject]
    set party_from [ad_get_user_id]
    set party_to $party_id

    db_list acs_mail_post_request ""
}
    
    

