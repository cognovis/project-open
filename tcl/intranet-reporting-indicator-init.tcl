ad_library {

    Initialization for intranet-reporting-indicators module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 November, 2006
    @cvs-id $Id$
}

# Initialize the search "semaphore" to 0.
# There should be only one thread sweeping at any time, even if the
# thread should be very slow...
nsv_set intranet_reporting_indicators sweeper_p 0

ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-reporting-indicators -parameter IndicatorSweeperSecondsInterval -default 59] im_indicator_timeline_component

