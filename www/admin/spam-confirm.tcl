ad_page_contract {
    spam confirmation page : displays spam body in plain text and HTML
    and prompts for confirmation 
} { 
    {body_plain ""}
    {{body_html:allhtml} ""}
    subject:notnull
    send_date:array,date
    send_time:array,time
    num_recipients
    spam_id:naturalnum
    {confirm_target "spam-send"}
} 

set sql_query [ad_get_client_property "spam" "sql_query"]
set object_id [ad_get_client_property "spam" "object_id"]
if [empty_string_p $object_id] {
    set object_id $spam_id
}

if {$sql_query == "" && $confirm_target == "spam-send"} { 
    ad_return_complaint 1 "No user query supplied.  You can't invoke this \
	    page directly."
    return 
}

ad_require_permission  $object_id write

if {$body_plain == "" && $body_html == ""} { 
    ad_return_complaint 1 "You must supply either a text or HTML body, or both"
    return
} 

set send_date_ansi $send_date(date)
set pretty_date [util_AnsiDatetoPrettyDate $send_date_ansi]
set send_time_12hr "$send_time(time) $send_time(ampm)"

if {$body_plain != ""}  {
    set escaped_body_plain [ad_convert_to_html $body_plain]
}

set export_vars [export_form_vars send_date_ansi send_time_12hr \
	subject body_plain body_html spam_id]





