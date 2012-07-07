ad_page_contract {
    update a spam message that's already in the database... used
    when the user wants to change spam text before it gets sent out
} {
    {{body_plain:trim} ""}
    {{body_html:allhtml,trim} ""}
    subject:notnull
    send_date_ansi:notnull
    send_time_12hr:notnull
    spam_id:naturalnum
} 

set date "$send_date_ansi $send_time_12hr"

set sql_query [ad_get_client_property spam sql_query]

spam_update_message \
	-sql $sql_query \
	-send_date $date \
	-spam_id $spam_id \
	-subject $subject \
	-plain $body_plain \
	-html $body_html


#ns_return 200 text/html $date
set context [list "Spam Updated"]
ad_return_template

