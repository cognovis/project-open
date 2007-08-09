ad_library {

    notifications reply init - sets up scheduled procs

    @cvs-id $Id$
    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-27

}

# Roberto Mello (12/2002): Added parameter and check for qmail queue scanning

set scan_replies_p [parameter::get \
			-package_id [apm_package_id_from_key notifications] \
			-parameter EmailQmailQueueScanP -default 0]

set scan_interval [parameter::get \
     -package_id [apm_package_id_from_key notifications] \
     -parameter EmailQmailQueueScanInterval -default 300]

if { $scan_replies_p == 1 } {
    ad_schedule_proc -thread t $scan_interval notification::reply::sweep::scan_all_replies
    ad_schedule_proc -thread t $scan_interval notification::reply::sweep::process_all_replies
}
