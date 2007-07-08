ad_library {

    Initialization for intranet-reporting-dashboard module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 July, 2007
    @cvs-id $Id$

}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_reporting_dashboard dashboard_synchronizer_p 0


# Delete the DW cube cache every few hours

ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-reporting-dashboard -parameter DashboardSweeperInterval -default 86400] im_reporting_dashboard_sweeper
