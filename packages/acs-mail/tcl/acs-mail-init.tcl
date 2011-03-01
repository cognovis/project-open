ad_library {
    Scheduled proc setup for acs-mail

    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2001-01-19
    @cvs-id $Id: acs-mail-init.tcl,v 1.4 2007/08/09 17:01:33 podemo33 Exp $
}

# Schedule periodic mail send events.  Its own thread, since it does
# network activity.  If it ever takes longer than the interval,
# there'll be hell to pay.

# Default interval is 15 minutes.


set interval [parameter::get \
		       -package_id [apm_package_id_from_key "acs-mail"] \
		       -parameter ProcessMailQueueInterval -default 901]

ad_schedule_proc -thread t $interval acs_mail_process_queue


ad_proc -private acs_mail_check_uuencode { } {
	Check if ns_uuencode is properly encoding binary files
} {

	# expected result from ns_uuencode
	set expected_result "H4sICHH01DsAA2p1bmsAS8zPKU4tKkstAgCaYWMDCQAAAA=="

	set file "[file dirname [info script]]/test-binary-file"

	# open the binary file
	set fd [open $file r]
	fconfigure $fd -encoding binary
	set file_content [read $fd]
	close $fd

	# encode it
	set encoded_content [ns_uuencode $file_content]

	if { [string equal $encoded_content $expected_result] } {
		nsv_set acs_mail ns_uuencode_works_p 1
		ns_log debug "acs-mail: ns_uuencode works!!"
	} else {
		nsv_set acs_mail ns_uuencode_works_p 0
		ns_log Warning "acs-mail: ns_uuencode broken - will use the slow tcl version"
	}
}

acs_mail_check_uuencode
