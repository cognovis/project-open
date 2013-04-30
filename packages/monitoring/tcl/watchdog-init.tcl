# /packages/monitoring/tcl/watchdog-init.tcl
ad_library {
     
    @author jbank@arsdigita.com [jbank@arsdigita.com]
    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date Tue Jan 30 16:35:55 2001
    @cvs-id $Id: watchdog-init.tcl,v 1.1.1.2 2006/08/24 14:41:37 alessandrol Exp $
}

if { ![nsv_exists . wd_installed_p] } {
    nsv_set . wd_installed_p 0
}

if { ![nsv_get . wd_installed_p] } {
    if { [monitoring_pkg_id] != 0 } {
        
        set check_frequency [wd_email_frequency]
        if { $check_frequency > 0 } {
            
            # If we schedule Watchdog e.g. every 15 minutes, it will first
            # run 15 minutes after server start.  Which means that if we
            # have some nasty error which is causing the server to restart
            # every 2 minutes, Watchdog will never run.  Therefore, we also
            # run it once immediately at server startup:
            # --atp@piskorski.com, 2002/04/08 22:09 EDT
            
            ad_schedule_proc -once t 0 {wd_mail_errors}
            
            ad_schedule_proc [expr 60 * $check_frequency] {wd_mail_errors}
            ns_log Notice "Watchdog: wd_mail_errors scheduled to run every $check_frequency minutes."
        }
        nsv_set . wd_installed_p 1
    }
    
}
