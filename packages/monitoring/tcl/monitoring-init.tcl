# /packages/monitoring/tcl/monitoring-init.tcl
ad_library {
    Initialization code
    @author jbank@arsdigita.com [jbank@arsdigita.com]
    @creation-date Tue Jan 30 16:33:58 2001
    @cvs-id $Id: monitoring-init.tcl,v 1.1.1.2 2006/08/24 14:41:36 alessandrol Exp $
}

# TopFrequency determines how often this proc is run, in minutes.
# If this is run too often, it occasionally runs into memory
# allocation trouble when trying to exec top... 

set top_frequency [ad_parameter -package_id [monitoring_pkg_id] TopFrequency monitoring 0]
ns_log Debug "monitoring: top_frequency is $top_frequency"

if { $top_frequency > 0 } {
    set top_frequency_in_seconds [expr 60 * $top_frequency]
    ad_schedule_proc $top_frequency_in_seconds ad_monitor_top
}

set df_frequency [ad_parameter -package_id [monitoring_pkg_id] DfFrequency monitoring 0]

if { $df_frequency > 0 } {
    set df_frequency_in_hour [expr 3600 * $df_frequency]
    ad_schedule_proc $df_frequency_in_hour ad_monitor_df
}


set db_frequency [ad_parameter -package_id [monitoring_pkg_id] DbFrequency monitoring 0]

if { $db_frequency > 0 } {
    set db_frequency_in_hour [expr 3600 * $db_frequency]
    ad_schedule_proc $db_frequency_in_hour ad_monitor_db_pgsql
}





# Turning this off since it doesn't work properly - vinodk
# see http://openacs.org/sdm/one-baf.tcl?baf_id=1453

#ns_schedule_daily -thread 20 48  ad_monitoring_analyze_tables
