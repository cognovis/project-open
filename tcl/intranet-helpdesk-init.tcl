ad_library {

    Initialization for intranet-helpdesk module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 April, 2012
    @cvs-id $Id$
}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_helpdesk_sourceforge_sweeper sweeper_p 0

# Check for changed files every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-cost -parameter SourceForgeTrackerSweeperInterval -default 3600] im_helpdesk_sourceforge_tracker_import_sweeper

