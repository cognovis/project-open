ad_library {

    Initialization for intranet-timesheet2 module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 November, 2006
    @cvs-id $Id$

}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_timesheet2 timesheet_synchronizer_p 0

# Check for imports of external im_hours entries every every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-timesheet2 -parameter SyncHoursInterval -default 59 ] im_timesheet2_sync_timesheet_costs

# Callbacks 
ad_proc -public -callback absence_on_change {
    {-absence_id:required}
    {-absence_type_id:required}
    {-user_id:required}
    {-start_date:required}
    {-end_date:required}
    {-duration_days:required}
    {-transaction_type:required}
} {
    Callback to be executed after an absence has been created
} -

