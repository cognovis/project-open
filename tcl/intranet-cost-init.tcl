ad_library {

    Initialization for intranet-cost module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 November, 2006
    @cvs-id $Id$

}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_cost_sweeper sweeper_p 0

# Check for changed files every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-cost -parameter CostCacheSweeperInterval -default 57] im_cost_cache_sweeper

