# /packages/intranet-mail/lib/one-message.tcl
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
            ad_complain "<b>[_ intranet-mail.The_specified_message_does_not_exist]</b>"
        }
    }
}

# We need to figure out a way to detect which contacts package a party_id belongs to

set page_title "[_ intranet-mail.One_message]"
set context [list]
set sender ""
set receiver ""

if { [empty_string_p $return_url] } {
    set return_url [get_referrer]
}

# Forward and reply email
set forward_url [export_vars -base "forward" -url {log_id return_url}]
set reply_url [export_vars -base "reply" -url {log_id return_url}]

# Get the information of the message
db_1row get_message_info { }

if {![exists_and_not_null cc]} {
    set cc ""
}

if {[exists_and_not_null sender_id]} {
	set sender [party::name -party_id $sender_id]
} else {
    set sender "$from_addr"
}

set reciever_list [list]
db_foreach reciever_id {select recipient_id from acs_mail_log_recipient_map where type ='to' and log_id = :log_id and recipient_id is not null} {
	lappend reciever_list "[party::name -party_id $recipient_id]"
}
if {![string eq "" $to_addr]} {
    lappend reciever_list $to_addr
}
set recipient [join $reciever_list ","]

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
set tracking_url [apm_package_url_from_key "intranet-mail"]
set download_files [list]
db_foreach files {} {
    append download_files "<a href=\"[export_vars -base "${tracking_url}download/$title" -url {version_id}]\">$title</a><br>"
}

if {![ad_looks_like_html_p $body]} {
    set body "<pre>$body</pre>"
}
