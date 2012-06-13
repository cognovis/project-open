# packages/mail-tracking/tcl/mail-tracking-callback-procs.tcl

ad_library {
    
    Callback procs for mail tracking
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-15
    @arch-tag: 9d6f99f7-cfec-40e6-8d3f-411f4d3c9b6c
    @cvs-id $Id$
}

ad_proc -public -callback acs_mail_lite::complex_send -impl mail_tracking {
    {-package_id:required}
    {-from_party_id:required}
    {-from_addr ""}
    {-to_party_ids ""}
    {-cc_party_ids ""}
    {-bcc_party_ids ""}
    {-to_addr ""}
    {-cc_addr ""}
    {-bcc_addr ""}
    {-body ""}
    {-message_id:required}
    {-subject ""}
    {-object_id ""}
    {-file_ids ""}
} {
    create a new entry in the mail tracking table
} {
    # We need to put lindex here since the value from
    # the swithc converts this "element element" to this
    # "{element element}"
    set file_ids [string trim $file_ids "{}"]

    foreach optional_param {cc_party_ids bcc_party_ids to_addr cc_addr bcc_addr body subject object_id file_ids to_party_ids} {
	if {![info exists $optional_param]} {
	    set $optional_param {}
	}
    }

    set log_id [mail_tracking::new -package_id $package_id \
		    -sender_id $from_party_id \
		    -from_addr $from_addr \
		    -recipient_ids $to_party_ids \
		    -cc_ids $cc_party_ids \
		    -bcc_ids $bcc_party_ids \
		    -to_addr $to_addr \
		    -cc_addr $cc_addr \
		    -bcc_addr $bcc_addr \
		    -body $body \
		    -message_id $message_id \
		    -subject $subject \
		    -file_ids $file_ids \
		    -object_id $object_id]

}

ad_proc -public -callback acs_mail_lite::send -impl mail_tracking {
    {-package_id:required}
    {-from_party_id:required}
    {-to_party_id:required}
    {-body:required}
    {-message_id:required}
    {-subject:required}
} {
    create a new entry in the mail tracking table
} {

    set log_id [mail_tracking::new -package_id $package_id \
		    -sender_id $from_party_id \
		    -recipient_ids $to_party_id \
		    -body $body \
		    -message_id $message_id \
		    -subject $subject]

}

ad_proc -public -callback fs::file_delete -impl mail-tracking {
    {-package_id:required}
    {-file_id:required}
} {
    Create a copy of the file and attach it to the mail-tracking entry, if the file is referenced
} {

    if {[db_string file_attached_p "select 1 from acs_mail_log_attachment_map where file_id = :file_id" -default 0]} {
	set package_id [apm_package_id_from_key mail-tracking]
	set new_file_id [fs::file_copy -file_id $file_id -target_folder_id $package_id]
	db_dml update_file "update acs_mail_log_attachment_map set file_id = :new_file_id where file_id = :file_id"
    }
}
    