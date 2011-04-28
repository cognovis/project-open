# packages/project-manager/www/send-mail.tcl

ad_page_contract {
    Use acs-mail-lite/lib/email chunk to send out going mail messages.
    
    party_ids: List of party_ids which will be appended to the assignee list
    party_id: A single party_id which will be used instead of anything else. Useful for sending the mail to only one person.
} {
    log_id:notnull
    {return_url ""}
} -validate {
    message_exists  -requires {log_id} {
        if { ![db_0or1row message_exists_p { }] } {
            ad_complain "<b>[_ intranet-mail.The_specified_message_does_not_exist]</b>"
        }
    }
}


set title [_ intranet-mail.Forward_message]
set context [list [list "one-message?log_id=$log_id" [_ intranet-mail.One_message]] $title]

if {$return_url eq ""} {
    set return_url "one-message?log_id=$log_id"
}

# Get the information of the message
db_1row get_message_info { }
if {$sender_id ne ""} {
    set sender [party::name -party_id $sender_id]
} else {
    set sender $from_addr
}

set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='to' and log_id = :log_id and recipient_id is not null} {
    lappend reciever_list "[party::name -party_id $recipient_id]"
}
if {![string eq "" $to_addr]} {
    lappend reciever_list $to_addr
}
set recipient [join $reciever_list ","]

set export_vars {log_id}

# Now the CC users
set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='cc' and log_id = :log_id and recipient_id is not null} {
    lappend reciever_list "[party::name -party_id $recipient_id]"
}
if {![string eq "" $cc]} {
    lappend reciever_list $cc
}
set cc_string [join $reciever_list ","]

# And the BCC ones
set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='bcc' and log_id = :log_id and recipient_id is not null} {
    lappend reciever_list "[party::name -party_id $recipient_id]"
}
if {![string eq "" $bcc]} {
    lappend reciever_list $bcc
}
set bcc_string [join $reciever_list ","]

# We get the related files
set download_files [list]
set files [db_list files {}]
foreach file_id $files {
    set title [content::item::get_title -item_id $file_id]
    lappend download_files $title
}

set download_files [join $download_files ", "]

if {![ad_looks_like_html_p $body]} {
    set body "<pre>$body</pre>"
}

set mime_type "text/html"

set content_body "<div style=\"background-color: #eee; padding: .5em;\">
<table>
<tr><td>
#intranet-mail.Sender#:</td><td>$sender</tr><td>
#intranet-mail.Recipient#:</td><td>$recipient</tr><td>
#intranet-mail.CC#:</td><td>$cc_string</tr><td>
#intranet-mail.BCC#:</td><td>$bcc_string</tr><td>
#intranet-mail.Subject#:</td><td>$subject</tr><td>
#intranet-mail.Attachments#:</td><td>$download_files</tr><td>
#intranet-mail.MessageID#:</td><td>$message_id</tr>
</table>
</div>
<p>
$body
"

set subject "FW: $subject"

# Set the cc_ids to all related object members
set cc_ids [list]
foreach member_id [im_biz_object_member_ids $object_id] {
    if {$member_id ne $sender_id} {
        lappend cc_ids $member_id
    }
}
