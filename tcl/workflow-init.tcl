ad_library {
 Initialization code for the acs-workflow package 
 (to run once on server startup).

 @cvs-id $Id$
}

# normal rhythm: Every 15 minutes
# ad_schedule_proc -thread t 900 wf_sweep_time_events


set interval [parameter::get \
		       -package_id [apm_package_id_from_key "acs-workflow"] \
		       -parameter SweepTimeEventsInterval -default 303]


# for debugging: every 1 minute
ad_schedule_proc -thread t $interval wf_sweep_time_events
