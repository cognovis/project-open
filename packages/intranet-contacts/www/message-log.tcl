ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
    {message_id:integer,notnull}
} -validate {
    message_exists  -requires {message_id} {
	if { ![db_0or1row message_exists_p { select 1 from contact_message_log where message_id = :message_id}] } {
	    ad_complain "[_ intranet-contacts.lt_The_message_specified_does_not_exist]"
	}
    }
}

db_1row get_message_data {
    select message_type,
           sender_id,
           recipient_id,
           sent_date,
           title,
           description,
           content,
           content_format
      from contact_message_log
     where message_id = :message_id

}

set timestamp     [lindex [split $sent_date "."] 0]
set date          [lc_time_fmt $timestamp "%q"]
set time          [string trimleft [lc_time_fmt $timestamp "%r"] "0"]

if { $message_type == "email" } {
    set content "<pre style=\"background-color: \#eee; padding: .5em;\">[_ intranet-contacts.Date]:    $date $time
[_ intranet-contacts.From]:    [contact::link -party_id $sender_id]
[_ intranet-contacts.To]:      [contact::link -party_id $recipient_id]
[_ intranet-contacts.Subject]: $description
</pre>
[ad_convert_to_html $content]
"
} else {
   set return_url "[contact::url -party_id $recipient_id]history"
}
set party_id $recipient_id
ad_return_template
