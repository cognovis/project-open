ad_library {

    Initialization for intranet-sla-management module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 November, 2006
    @cvs-id $Id$
}

# Initialize the search "semaphore" to 0.
# There should be only one thread sweeping at any time, even if the
# thread should be very slow...
nsv_set intranet_sla_management sweeper_p 0

# Re-calculate the "solution time" of open tickets every minute

ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-sla-management -parameter SLASolutionTimeSweeperInterval -default 59] im_sla_ticket_solution_time_sweeper


# Close all tickets that are in status "resolved" for more then a certain period
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-sla-management -parameter CloseResolvedTicketsSweeperInterval -default 179] im_sla_ticket_close_resolved_tickets_sweeper

