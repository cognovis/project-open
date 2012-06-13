ad_library {
    Initialization for intranet-funambol package
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 November, 2010
    @cvs-id $Id$
}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_funambol sync_p 0

# Check for changed files every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-funambol -parameter SyncInterval -default 30 ] im_funambol_sync

