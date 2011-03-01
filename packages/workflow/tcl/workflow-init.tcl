ad_library {
    Initialization for workflow.
    
    @creation-date 18 November 2003
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id: workflow-init.tcl,v 1.1 2006/10/25 17:55:34 cvs Exp $
}

#----------------------------------------------------------------------
# Schedule the timed actions sweeper
#----------------------------------------------------------------------

set interval [parameter::get_from_package_key \
                  -package_key "workflow" \
                  -parameter "SweepTimedActionsFrequency" \
                  -default 300]

if { ![string is integer $interval] } {
    ns_log Error "Workflow parameter SweepTimedActionsFrequency is not an integer. Value is '$interval'."
    set interval 300
}

ad_schedule_proc -thread t $interval workflow::case::timed_actions_sweeper

