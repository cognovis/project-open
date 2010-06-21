ad_library {
    Initialization for intranet-audit
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 August, 2009
    @cvs-id $Id$
}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_audit audit_sweep_semaphore 0


# Schedule the audit function (creates a copy of all active main projects...) every few hours
#
set sweeper_interval_hours [parameter::get_from_package_key -package_key intranet-core -parameter AuditProjectProgressIntervalHours -default 0]
if {0 != $sweeper_interval_hours} {
    ad_schedule_proc -thread t 10 im_audit_sweeper
}

# Schedule automatic generation of a project's history for demo servers
#
set fake_history_interval_hours [parameter::get_from_package_key -package_key intranet-audit -parameter "AuditProjectFakeHistoryIntervalHours" -default 0]
if {0 != $fake_history_interval_hours} {
    ad_schedule_proc -thread t 10 im_audit_fake_history
}
