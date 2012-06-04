ad_library {

    Mail-Tracking

    Core procs for tracking mails. Important concepts:
    <ul>
    <li> tracking: each message sent out by acs-mail-lite is tracked - if it was queued.
    <li> intervals: as soon as the email was sent and removed from the queue.
    <li> participation: Either through registering a package instance or by setting the verbose parameter: TrackAllTraffic
    </ul>

    @creation-date 2005-05-31
    @author Nima Mazloumi <mazloumi@uni-mannheim.de>
    @cvs-id $Id$

}

namespace eval mail_tracking {}

ad_proc -public mail_tracking::package_key {} {
    The package key
} {
    return "mail-tracking"
}

ad_proc -public mail_tracking::new {
    {-log_id ""}
    {-package_id:required}
    {-sender_id ""}
    {-from_addr ""}
    {-recipient_ids:required}
    {-cc_ids ""}
    {-bcc_ids ""}
    {-to_addr ""}
    {-cc_addr ""}
    {-bcc_addr ""}
    {-body ""}
    {-message_id:required}
    {-subject ""}
    {-object_id ""}
    {-context_id ""}
    {-file_ids ""}
} {
    Insert new log entry

    @param sender_id party_id of the sender
    @param from_addr e-mail address of the sender. At least party_id or from_addr should be given
    @param recipient_ids List of party_ids of recipients
    @param cc_ids List of party_ids for recipients in the "CC" field
    @param bcc_ids List of party_ids for recipients in the "BCC" field
    @param to_addr List of email addresses seperated by "," who recieved the email in the "to" field but got no party_id
    @param cc_addr List of email addresses seperated by "," who recieved the email in the "cc" field but got no party_id
    @param bcc_addr List of email addresses seperated by "," who recieved the email in the "bcc" field but got no party_id
    @param body Text of the message
    @param message_id Message_id of the email
    @param subject Subject of the email
    @param object_id Object for which this message was sent
    @param context_id Context in which this message was send. Will replace object_id
    @param file_ids Files send with this e-mail
} {
    set creation_ip "127.0.0.1"
    if {![string eq "" $context_id]} {
	set object_id $context_id
    }
    
    set log_id [db_nextval "acs_object_id_seq"]
    # First create the message entry 
    db_dml insert_mail_log {
	insert into acs_mail_log
	(log_id, message_id, sender_id, package_id, subject, body, sent_date, object_id, cc, bcc, to_addr, from_addr)
	values
	(:log_id, :message_id, :sender_id, :package_id, :subject, :body, now(), :object_id, :cc_addr, :bcc_addr, :to_addr, :from_addr)
    }

    ns_log Debug "Mail Traking OBJECT $object_id  CONTEXT $context_id FILES $file_ids LOGS $log_id"
    foreach file_id $file_ids {
	set item_id [content::revision::item_id -revision_id $file_id]
	if {$item_id eq ""} {
	    set item_id $file_id
	}
	db_dml insert_file_map "insert into acs_mail_log_attachment_map (log_id,file_id) values (:log_id,:file_id)"
    }

    # Now add the recipients to the log_id
    
    foreach recipient_id $recipient_ids {
	db_dml insert_recipient {insert into acs_mail_log_recipient_map (recipient_id,log_id,type) values (:recipient_id,:log_id,'to')}
    } 

    foreach recipient_id $cc_ids {
	db_dml insert_recipient {insert into acs_mail_log_recipient_map (recipient_id,log_id,type) values (:recipient_id,:log_id,'cc')}
    } 

    foreach recipient_id $bcc_ids {
	db_dml insert_recipient {insert into acs_mail_log_recipient_map (recipient_id,log_id,type) values (:recipient_id,:log_id,'bcc')}
    } 

    return $log_id
}	       
