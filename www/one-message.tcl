# /packages/mail-tracking/lib/one-message.tcl
ad_page_contract {
    Displays one message that was send to a user

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-09-30
} {
    log_id:notnull
    {return_url ""}
} -validate {
    message_exists  -requires {log_id} {
        if { ![db_0or1row message_exists_p { }] } {
            ad_complain "<b>[_ mail-tracking.The_specified_message_does_not_exist]</b>"
        }
    }
}

# We need to figure out a way to detect which contacts package a party_id belongs to

set page_title "[_ mail-tracking.One_message]"
set context [list]
set sender ""
set receiver ""

if { [empty_string_p $return_url] } {
    set return_url [get_referrer]
}

# Get the information of the message
db_1row get_message_info { }

if {![exists_and_not_null cc]} {
    set cc ""
}

if {[exists_and_not_null sender_id]} {
    set contacts_package_id [contact::package_id -party_id $sender_id]
    if {$contacts_package_id} {
	set sender "<a href=\"[contact::url -party_id $sender_id  -package_id $contacts_package_id]\">[party::name -party_id $sender_id]</a>"
    } else {
	set sender [party::name -party_id $sender_id]
    }
} else {
    set sender "Unknown"
}

set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='to' and log_id = :log_id and recipient_id is not null} {
    if {$contacts_package_id} {
	lappend reciever_list "<a href=\"[contact::url -party_id $recipient_id  -package_id $contacts_package_id]\">[party::name -party_id $recipient_id]</a>"
    } else {
	lappend reciever_list "[party::name -party_id $recipient_id]"
    }
}
if {![string eq "" $to_addr]} {
    lappend reciever_list $to_addr
}
set recipient [join $reciever_list ","]

# Now the CC users
set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='cc' and log_id = :log_id and recipient_id is not null} {
    if {$contacts_package_id} {
	lappend reciever_list "<a href=\"[contact::url -party_id $recipient_id  -package_id $contacts_package_id]\">[party::name -party_id $recipient_id]</a>"
    } else {
	lappend reciever_list "[party::name -party_id $recipient_id]"
    }
}
if {![string eq "" $cc]} {
    lappend reciever_list $cc
}
set cc_string [join $reciever_list ","]

# And the BCC ones
set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='bcc' and log_id = :log_id and recipient_id is not null} {
    if {$contacts_package_id} {
	lappend reciever_list "<a href=\"[contact::url -party_id $recipient_id  -package_id $contacts_package_id]\">[party::name -party_id $recipient_id]</a>"
    } else {
	lappend reciever_list "[party::name -party_id $recipient_id]"
    }
}
if {![string eq "" $bcc]} {
    lappend reciever_list $bcc
}
set bcc_string [join $reciever_list ","]

# We get the related files
set tracking_url [apm_package_url_from_key "mail-tracking"]
set download_files [list]
set files [db_list files {}]
foreach file_id $files {
    set title [content::item::get_title -item_id $file_id]
    lappend download_files "<a href=\"[export_vars -base "${tracking_url}download/$title" -url {file_id}]\">$title</a><br>"
}

set download_files [join $download_files ", "]

if {![ad_looks_like_html_p $body]} {
    set body "<pre>$body</pre>"
}
