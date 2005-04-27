ad_library {
 Initialization code for the acs-workflow package 
 (to run once on server startup).

 @cvs-id $Id$
}

ad_schedule_proc -thread t 900 wf_sweep_time_events
