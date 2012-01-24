# /packages/intranet-sla-management/tcl/intranet-sla-management-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_sla_parameter_status_active {} { return 72000 }
ad_proc -public im_sla_parameter_status_deleted {} { return 72002 }

ad_proc -public im_sla_parameter_type_default {} { return 72100 }


# ----------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------

ad_proc -public im_sla_parameter_permissions {
    user_id 
    param_id 
    view_var 
    read_var 
    write_var 
    admin_var
} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $ticket_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    # Get the SLA for the parameter.
    # We want to cache the query, so we have to use a "dollar variable" and
    # so we need to check security before doing so...
    im_security_alert_check_integer -location "im_sla_parameter_permissions" -value $param_id
    set sla_id [util_memoize "db_string param_sla {select param_sla_id from im_sla_parameters where param_id = $param_id} -default {}"]

    # Permissions on parameters are permission on the parameter's container project
    im_project_permissions $user_id $sla_id view read write admin
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_sla_parameter_component {
    -object_id
} {
    Returns a HTML component to show a list of SLA parameters with the option
    to add more parameters
} {
    set project_id $object_id
    if {![im_project_has_type $project_id "Service Level Agreement"]} { 
	ns_log Notice "im_sla_parameter_component: Project \#$project_id is not a 'Service Level Agreement'"
	return "" 
    }

    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/sla-parameter-list-component"]
    return [string trim $result]
}


ad_proc -public im_sla_parameter_list_component {
    {-project_id ""}
    {-param_id ""}
} {
    Returns a HTML component with a mix of SLA parameters and indicators.
    The component can be used both on the SLAViewPage and the ParamViewPage.
} {
    if {![im_project_has_type $project_id "Service Level Agreement"]} { 
	ns_log Notice "im_sla_parameter_list_component: Project \#$project_id is not a 'Service Level Agreement'"
	return "" 
    }

    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list project_id $project_id] \
		    [list param_id $param_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/sla-parameter-indicator-component"]
    return [string trim $result]
}


ad_proc -public im_sla_service_hours_component {
    {-project_id ""}
} {
    Returns a HTML component with a component to display and modify working hours
    for the 7 days of the week.
} {
    if {![im_project_has_type $project_id "Service Level Agreement"]} { 
	ns_log Notice "im_sla_service_hours_component: Project \#$project_id is not a 'Service Level Agreement'"
	return "" 
    }

    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list project_id $project_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/service-hours-component"]
    return [string trim $result]
}


ad_proc -public im_ticket_priority_map_component {
    {-project_id ""}
} {
    Returns a HTML component with a component containing a list of
    ticket_type x ticket_severity => ticket_priority tuples.
} {
    if {![im_project_has_type $project_id "Service Level Agreement"]} { 
	ns_log Notice "im_sla_service_hours_component: Project \#$project_id is not a 'Service Level Agreement'"
	return "" 
    }

    set params [list \
		    [list project_id $project_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/ticket-priority-component"]
    return [string trim $result]
}




ad_proc -public im_ticket_priority_lookup {
    -sla_id:required
    -ticket_type_id:required
    -ticket_status_id:required
    -map:required
} {
    Takes ticket_type and ticket_status to lookup
    the ticket priority in the "map".
    "Map" contains triples of {type_id severity_id prio_id}
    Returns the mapped value or "" if no match has been found.
} {
    set result ""
    foreach tuple $map {
	set t0 [lindex $tuple 0]
	set t1 [lindex $tuple 1]
	set t2 [lindex $tuple 2]
	if {$t0 == $ticket_type_id && $t1 == $ticket_status_id} {
	    set result $t2
	}
    }
    return $result
}



ad_proc -callback im_ticket_after_create -impl im_sla_management {
    -object_id
    -status_id 
    -type_id
} {
    Callback to be executed after the creation of any ticket.
    The callback performs a lookup of certain ticket properties
    (ticket_type_id and ticket_severity_id) and assigns a suitable
    priority to the ticket.
    The assigned priority overwrites the possibly user-defined priority.
} {
    ns_log Notice "im_ticket_after_create -impl im_sla_management: Entering callback code"
    
    set found_p [db_0or1row ticket_info "
	select	t.*,
		p.*,
		sla.project_id as sla_id,
		sla.sla_ticket_priority_map
	from	im_tickets t,
		im_projects p,
		im_projects sla
	where	t.ticket_id = p.project_id and
		t.ticket_id = :object_id and
		p.parent_id = sla.project_id
    "]
    
    if {!$found_p} {
	ns_log Error "im_ticket_after_create -impl im_sla_management -object_id=$object_id: Didn't find object, skipping"
	return ""
    }

    set priority_id [im_ticket_priority_lookup \
			 -sla_id $sla_id \
			 -ticket_type_id $ticket_type_id \
			 -ticket_status_id $ticket_status_id \
			 -map $sla_ticket_priority_map \
    ]

    # Update the ticket if the mapping was successfull
    if {"" != $priority_id} {
	db_dml update_ticket "
		update im_tickets
		set ticket_prio_id = :priority_id
		where ticket_id = :object_id
	"
	ns_log Notice "im_ticket_after_create -impl im_sla_management: Updated ticket \#$ticket_id with prio_id=$priority_id"
    }

}

ad_proc -callback im_ticket_after_update -impl im_sla_management {
    -object_id
    -status_id 
    -type_id
} {
    Callback to be executed after the update of any ticket.
    The callback resets the "ticket_resolution_time_dirty"
    field, indicating to the resolution time sweeper that
    this ticket needs to be recalculated.
} {
    ns_log Notice "im_ticket_after_update -impl im_sla_management: Entering callback code"

    # tell the resolution time sweeper to recalculate this ticket    
    db_dml reset_restime_dirty "
	update im_tickets
	set ticket_resolution_time_dirty = null
	where ticket_id = :object_id
    "

}




ad_proc -public im_sla_day_of_week_list {
} {
    Returns a list with weekday names from 0=Su to 6=Sa
} {
    set dow_list [list]
    lappend dow_list [lang::message::lookup "" intranet-core.Sunday Sunday]
    lappend dow_list [lang::message::lookup "" intranet-core.Monday Monday]
    lappend dow_list [lang::message::lookup "" intranet-core.Tuesday Tuesday]
    lappend dow_list [lang::message::lookup "" intranet-core.Wednesday Wednesday]
    lappend dow_list [lang::message::lookup "" intranet-core.Thursday Thursday]
    lappend dow_list [lang::message::lookup "" intranet-core.Friday Friday]
    lappend dow_list [lang::message::lookup "" intranet-core.Saturday Saturday]
    return $dow_list
}


ad_proc -public im_sla_check_time_in_service_hours {
    time
    service_hours_list
} {
    Returns 1 if the time (example: "09:55") falls within service hours 
    (example: {09:00 20:00})
} {
    foreach tuple $service_hours_list {
	set start [lindex $tuple 0]
	set end   [lindex $tuple 1]
	if {$time >= $start && $time <= $end} { return 1 }
    }
    return 0
}



ad_proc -public im_sla_management_epoch_in_service_hours {
    epoch
    service_hours_list
} {
    Returns 1 if the epoch falls within service hours
    ToDo:: Implement
} {
    return 1
}




# ----------------------------------------------------------------------
# Close all tickets that are in status "resolved" for more then a certain period
# ---------------------------------------------------------------------

ad_proc -public im_sla_ticket_close_resolved_tickets_sweeper {
    {-debug_p 0}
    {-ticket_id ""}
} {
    Set ticket statatus to "closed" after the ticket is in status "resolved"
    for a certain time.
} {
    # Make sure that only one thread is calculating at a time
#    if {[nsv_incr intranet_sla_management sweeper_p] > 1} {
#        nsv_incr intranet_sla_management sweeper_p -1
#        ns_log Notice "im_sla_ticket_solution_time: Aborting. There is another process running"
#        return
#    }

    ns_log Notice "im_sla_ticket_close_resolved_tickets_sweeper: debug_p=$debug_p"

    # Check whether to resolved tickets after some time.
    # Set parameter to 0 to disable this feature.
    set close_after_seconds [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter CloseResolvedTicketAfterSeconds -default 0]
    if {"" == $close_after_seconds || 0 == $close_after_seconds} { return }

    # Get the tickets that are already "resolved" more then X seconds.
    set resolved_tickets_sql "
	select	t.*
	from	im_tickets t
	where	t.ticket_status_id = [im_ticket_status_resolved] and
		t.ticket_done_date + :close_after_seconds 'seconds' < now()
    "
    set resolved_tickets [db_list resolved_tickets $resolved_tickets_sql]
    lappend resolved_tickets 0

    db_dml set_resolved "
	update im_tickets
	set ticket_status_id = [im_ticket_status_closed]
	where ticket_id in ([join $resolved_tickets])
    "
}



# ----------------------------------------------------------------------
# Calculate the Solution time for every ticket
# ---------------------------------------------------------------------

ad_proc -public im_sla_ticket_solution_time_sweeper {
    {-debug_p 0}
    {-ticket_id ""}
    {-limit 100}
} {
    Calculates "resolution time" for all open tickets.
    The procedure takes about a second per ticket, so 
    the limit is set to 100 by default.
} {
    ns_log Notice "im_sla_ticket_solution_time_sweeper: starting"

    # Make sure that only one thread is calculating at a time
    if {[nsv_incr intranet_sla_management sweeper_p] > 1} {
        nsv_incr intranet_sla_management sweeper_p -1
        ns_log Error "im_sla_ticket_solution_time_sweeper: Aborting. There is another process running"
        return
    }

    # Catch possible errors in order to make sure the semaphore gets
    # set correctly.
    set result ""
    if {[catch {
	set result [im_sla_ticket_solution_time_sweeper_helper -debug_p $debug_p -ticket_id $ticket_id -limit $limit]
    } err_msg]} {
	ns_log Error "im_sla_ticket_solution_time_sweeper: Found error: $err_msg"
	set result "<pre>$err_msg</pre>"
    }

    # De-block the execution of this procedure for a 2nd thread
    nsv_incr intranet_sla_management sweeper_p -1

    if {$debug_p} {
	ad_return_complaint 1 $result
    }
    return $result
}

ad_proc -public im_sla_ticket_solution_time_sweeper_helper {
    {-debug_p 0}
    {-ticket_id ""}
    {-limit 100}
} {
    Calculates "resolution time" for all open tickets.
    The procedure takes about a second per ticket, so 
    the limit is set to 100 by default.
} {
    ns_log Notice "im_sla_ticket_solution_time_sweeper_helper: starting"

    # Deal with timezone offsets for epoch calculation...
    set tz_offset_seconds [util_memoize "db_string tz_offset {select extract(timezone from now())}"]

    # User to act as
    set current_user_id [db_string cuid "select min(user_id) from users where user_id > 0"]

    set limit_to_ticket_id $ticket_id
    
    # Calculate the list of "open" ticket states (when to advance the restime counter)
    # Exclude the status "customer_review" (no work to be done by the helpdesk)
    set ticket_open_states [db_list ostate "
	select	*
	from	im_sub_categories([im_ticket_status_open])
	where	im_sub_categories not in (
			[im_ticket_status_customer_review]
		)
    "]

    # SISLA code: ToDo: remove for production
    # Add "rejected" to "open" states
    lappend ticket_open_states [im_ticket_status_rejected]

    set debug_html ""
    set time_html ""

    # Returns a list with weekday names from 0=Su, 1=Mo to 6=Sa:
    # {Sunday Monday Tuesday Wednesday Thursday Friday Saturday}
    set dow_list [im_sla_day_of_week_list]

    # Count the number of tickets processed
    set total_tickets_processed 0

    # Calculate a list of groups for storing resolution times per group
    set group_list [db_list group_list "select group_id from groups where group_id > 0 order by group_id"]

    # ----------------------------------------------------------------
    # Get the group's labour time start and end dates during the week
    # ToDo: Setup a link between SLAs and group's labour time.
    # SISLA: "Developers" work from 9:00 until 17:00. 
    # Time from 17:00 to service end doesn't count.
    set developer_group_id [db_string developer_gid "select group_id from groups where group_name = 'Linux Admins'" -default 0]
    set employee_labour_hours {0 {} 1 {{09:00 17:00}} 2 {{09:00 17:00}} 3 {{09:00 17:00}} 4 {{09:00 17:00}} 5 {{09:00 17:00}} 6 {}}
    array set employee_labour_hours_dow_hash $employee_labour_hours
    set employee_labour_hours_list [list]
    foreach dow [lsort [array names employee_labour_hours_dow_hash]] {
	lappend employee_labour_hours_list $employee_labour_hours_dow_hash($dow)
    }
    set labour_hours_hash($developer_group_id) $employee_labour_hours_list

    set labour_hours_hash(463) $employee_labour_hours_list


    # ----------------------------------------------------------------
    # Get the list of SLAs to work with.
    # Include all open tickets or tickets with dirty resolution_time.
    #
    set slas_with_open_tickets [db_list sla_list "
	select	p.project_id
	from	im_projects p
	where	p.project_type_id = [im_project_type_sla] and
		exists (
			select	*
			from	im_tickets t,
				im_projects tp
			where	t.ticket_id = tp.project_id and
				tp.parent_id = p.project_id and
				(	ticket_status_id in ([join [im_sub_categories [im_ticket_status_open]] ","])
				OR 	ticket_resolution_time_dirty is NULL
				)
		)
    "]

    # Debugging: Only calculate a single ticket
    if {"" != $limit_to_ticket_id} {
        set slas_with_open_tickets [db_list sla_list "
                select  p.parent_id
                from    im_projects p
                where   p.project_id = :limit_to_ticket_id
        "]
    }


    # ----------------------------------------------------------------
    # Loop through all SLAs

    ns_log Notice "im_sla_ticket_solution_time_sweeper: Looping through all SLAs with open tickets"
    foreach sla_id $slas_with_open_tickets {

	if {$debug_p} { 
	    ns_log Notice "im_sla_ticket_solution_time: sla_id=$sla_id" 
	    append debug_html "</ul><h1>SLA=$sla_id</h1><ul>"
	    append time_html "</ul><h1>SLA=$sla_id</h1><ul>"
	}

	# ----------------------------------------------------------------
	# Define the service hours per weekday.
	# (0 {} 1 {09:00 21:00} 2 {09:00 21:00} 3 {09:00 21:00} 4 {09:00 21:00} 5 {09:00 21:00} 6 {})
	#
	set service_hours_sql "
	        select  *
	        from    im_sla_service_hours
	        where   sla_id = :sla_id
		order by dow
	"
	set service_hours_list [list]
	db_foreach service_hours $service_hours_sql {
	    lappend service_hours_list $service_hours
	}

	if {$debug_p} { ns_log Notice "im_sla_ticket_solution_time: sla_id=$sla_id, service_hours=$service_hours_list" }

	# ----------------------------------------------------------------
	# Get the list of all selected ticket (open or dirty ones)
	#
	set extra_where "and (
		t.ticket_status_id in ([join [im_sub_categories [im_ticket_status_open]] ","])
		OR t.ticket_resolution_time_dirty is NULL
		)
	"
	if {"" != $limit_to_ticket_id} { set extra_where "and t.ticket_id = :limit_to_ticket_id" }
	set ticket_sql "
		select	*,
			extract(epoch from t.ticket_creation_date) as ticket_creation_epoch,
			to_char(t.ticket_creation_date, 'J') as ticket_creation_julian,
			to_char(t.ticket_creation_date, 'YYYY') as ticket_creation_year,
			extract(epoch from now()) as now_epoch,
			to_char(now(), 'J') as now_julian
		from	im_tickets t,
			im_projects p
		where	t.ticket_id = p.project_id and
			p.parent_id = :sla_id
			$extra_where
		order by
			coalesce(t.ticket_resolution_time_dirty, to_date('2000-01-01', 'YYYY-MM-DD'))
		LIMIT $limit
	"

	db_foreach tickets $ticket_sql {

	    # Skip tickets with empty creation date
	    if {"" == $ticket_creation_julian} { 
		ns_log Error "im_sla_ticket_solution_time_sweeper: Skipping ticket #$ticket_id because ticket_creation_date is null"
		continue 
	    }

	    ns_log Notice "im_sla_ticket_solution_time_sweeper: Processing ticket_id=$ticket_id"
	    if {$debug_p} {
		append debug_html "
			<li><b>sla_id=$sla_id, $ticket_id : $project_name</b>
			<li>ticket_creation_date: $ticket_creation_date
			<li>ticket_creation_julian: $ticket_creation_julian
			<li>ticket_creation_epoch: $ticket_creation_epoch
		"
	    }
	    set name($ticket_id) $project_name
	    set start_julian($ticket_id) $ticket_creation_julian
	    set start_epoch($ticket_id) $ticket_creation_epoch
	    set end_julian($ticket_id) $now_julian
	    set epoch_{$ticket_id}([expr $ticket_creation_epoch - 0.0003]) "creation"
	    set julian_{$ticket_id}($ticket_creation_julian) "creation"
	    set epoch_{$ticket_id}([expr $now_epoch + 0.0003]) "now"
	    set julian_{$ticket_id}($now_julian) "now"
	    
	    if {$debug_p} { append time_html "<li>sla_id=$sla_id, $ticket_id: ticket_creation_epoch=$ticket_creation_epoch" }
	    
	    # ----------------------------------------------------------------------------------------
	    # Loop through all days between start and end and add the start
	    # and end of the business hours this day.
	    if {$debug_p} { 
		append debug_html "<li>Starting to loop through julian dates from ticket_creation_julian=$ticket_creation_julian to now_julian=$now_julian ([im_date_julian_to_ansi $ticket_creation_julian] to [im_date_julian_to_ansi $now_julian])\n" 
	    }
	    for {set j $ticket_creation_julian} {$j <= $now_julian} {incr j} {

		# ----------------------------------------------------------------------------------------
		# Get the service hours per Day Of Week (0=Su, 1=mo, 6=Sa)
		# service_hours are like {09:00 18:00}
		set dow [expr ($j + 1) % 7]
		set service_hours [lindex $service_hours_list $dow]
		if {$debug_p} { append debug_html "<li>Ticket: $ticket_id, julian=$j, ansi=[im_date_julian_to_ansi $j], dow=$dow: [lindex $dow_list $dow], service_hours=$service_hours\n" }
		
		foreach sh $service_hours {
		    if {$debug_p} { append debug_html "<li>Ticket: $ticket_id, julian=$j, ansi=[im_date_julian_to_ansi $j], sh=$sh\n" }
		    
		    # Calculate service start	    
		    # Example: service_start = '09:00'. Add 0.01 to avoid overwriting.
		    set service_start [lindex $sh 0]
		    # On weekends there may be no service hours at all...
		    if {"" == $service_start} { continue }
		    set service_start_list [split $service_start ":"]
		    set service_start_hour [string trimleft [lindex $service_start_list 0] "0"]
		    set service_start_minute [string trimleft [lindex $service_start_list 1] "0"]
		    if {"" == $service_start_hour} { set service_start_hour 0 }
		    if {"" == $service_start_minute} { set service_start_minute 0 }
		    set service_start_epoch [expr [im_date_julian_to_epoch $j] + 3600.0*$service_start_hour + 60.0*$service_start_minute + 0.01]
		    set epoch_{$ticket_id}($service_start_epoch) "service_start"
		    if {$debug_p} { 
			ns_log Notice "im_sla_ticket_solution_time: ticket_id=$ticket_id, service_start=$service_start, hour=$service_start_hour, min=$service_start_minute"
			set service_start_epoch2 [db_string epoch "select extract(epoch from to_timestamp('$j $service_start', 'J HH24:MM')) + 0.01"]
			ns_log Notice "im_sla_ticket_solution_time: diff=[expr $service_start_epoch - $service_start_epoch2]"
			append debug_html "<li>Start: julian=$j, ansi=[im_date_julian_to_ansi $j], service_start=$service_start, service_start_epoch=$service_start_epoch\n"
		    }

		    # Calculate service end
		    # Example: service_end = '18:00'. Add 0.01 to avoid overwriting.
		    set service_end [lindex $sh 1]
		    # On weekends there may be no service hours at all...
		    if {"" == $service_end} { continue }
		    set service_end_list [split $service_end ":"]
		    set service_end_hour [string trimleft [lindex $service_end_list 0] "0"]
		    set service_end_minute [string trimleft [lindex $service_end_list 1] "0"]
		    if {"" == $service_end_hour} { set service_end_hour 0 }
		    if {"" == $service_end_minute} { set service_end_minute 0 }
		    set service_end_epoch [expr [im_date_julian_to_epoch $j] + 3600.0*$service_end_hour + 60.0*$service_end_minute + 0.01]
		    set epoch_{$ticket_id}($service_end_epoch) "service_end"
		    if {$debug_p} { 
			ns_log Notice "im_sla_ticket_solution_time: ticket_id=$ticket_id, service_end=$service_end, hour=$service_end_hour, min=$service_end_minute"
			set service_end_epoch2 [db_string epoch "select extract(epoch from to_timestamp('$j $service_end', 'J HH24:MM')) + 0.01"]
			ns_log Notice "im_sla_ticket_solution_time: diff=[expr $service_end_epoch - $service_end_epoch2]"
			append debug_html "<li>End: julian=$j, ansi=[im_date_julian_to_ansi $j], service_end=$service_end, service_end_epoch=$service_end_epoch\n"
		    }		
		}
		# End of looping through service hour start-end tuples


		# ----------------------------------------------------------------------------------------
		# Check the queue's labour time during the day
		# and create events
		foreach gid $group_list {
		    # Pull out the list of labour hours for each group
		    if {![info exists labour_hours_hash($gid)]} { continue }
		    set labour_hours_list $labour_hours_hash($gid)

		    # The labour hours's list ist ordered according to DoW, so we can use lindex.
		    set labour_hours [lindex $labour_hours_list $dow]
		    
		    foreach sh $labour_hours {
			set labour_start [lindex $sh 0]
			if {"" == $labour_start} { continue }
			set labour_start_list [split $labour_start ":"]
			set labour_start_hour [string trimleft [lindex $labour_start_list 0] "0"]
			set labour_start_minute [string trimleft [lindex $labour_start_list 1] "0"]
			if {"" == $labour_start_hour} { set labour_start_hour 0 }
			if {"" == $labour_start_minute} { set labour_start_minute 0 }
			set labour_start_epoch [expr [im_date_julian_to_epoch $j] + 3600.0*$labour_start_hour + 60.0*$labour_start_minute + 0.04]
			set epoch_{$ticket_id}($labour_start_epoch) "labour_start"

			# Write the affected groups into a hash
			set groups [list]

			if {$debug_p} {
			    ns_log Notice "sweeper: [array get labour_start_groups_{$ticket_id} $labour_start_epoch]"
			    ns_log Notice "sweeper: [array get labour_start_groups_{$ticket_id}]"
			}

			if {[info exists labour_start_groups_{$ticket_id}($labour_start_epoch)]} { set groups [array get labour_start_groups_{$ticket_id} $labour_start_epoch] }
			lappend groups $gid
			set labour_start_groups_{$ticket_id}($labour_start_epoch) $groups
			if {$debug_p} {
			    ns_log Notice "im_sla_ticket_solution_time: ticket_id=$ticket_id, labour_start=$labour_start, hour=$labour_start_hour, min=$labour_start_minute"
			    set labour_start_epoch2 [db_string epoch "select extract(epoch from to_timestamp('$j $labour_start', 'J HH24:MM')) + 0.04"]
			    ns_log Notice "im_sla_ticket_solution_time: diff=[expr $labour_start_epoch - $labour_start_epoch2]"
			    append debug_html "<li>Labour Start: julian=$j, ansi=[im_date_julian_to_ansi $j], labour_start=$labour_start, labour_start_epoch=$labour_start_epoch\n"
			}

			# Calculate service end
			# Example: labour_end = '18:00'. Add 0.04 to avoid overwriting.
			set labour_end [lindex $sh 1]
			# On weekends there may be no service hours at all...
			if {"" == $labour_end} { continue }
			set labour_end_list [split $labour_end ":"]
			set labour_end_hour [string trimleft [lindex $labour_end_list 0] "0"]
			set labour_end_minute [string trimleft [lindex $labour_end_list 1] "0"]
			if {"" == $labour_end_hour} { set labour_end_hour 0 }
			if {"" == $labour_end_minute} { set labour_end_minute 0 }
			set labour_end_epoch [expr [im_date_julian_to_epoch $j] + 3600.0*$labour_end_hour + 60.0*$labour_end_minute + 0.04]
			set epoch_{$ticket_id}($labour_end_epoch) "labour_end"
			# Write the affected groups into a hash
			set groups [list]
			if {[info exists labour_end_groups_{$ticket_id}($labour_end_epoch)]} { set groups [array get labour_end_groups_{$ticket_id} $labour_end_epoch] }
			lappend groups $gid
			set labour_end_groups_{$ticket_id}($labour_end_epoch) $groups
			if {$debug_p} {
			    ns_log Notice "im_sla_ticket_solution_time: ticket_id=$ticket_id, labour_end=$labour_end, hour=$labour_end_hour, min=$labour_end_minute"
			    set labour_end_epoch2 [db_string epoch "select extract(epoch from to_timestamp('$j $labour_end', 'J HH24:MM')) + 0.04"]
			    ns_log Notice "im_sla_ticket_solution_time: diff=[expr $labour_end_epoch - $labour_end_epoch2]"
			    append debug_html "<li>Labour End: julian=$j, ansi=[im_date_julian_to_ansi $j], labour_end=$labour_end, labour_end_epoch=$labour_end_epoch\n"
			}		
		    }
		}
	    }
	}

	# ----------------------------------------------------------------
	# Get all audit records for the open tickets of this SLA
	#
	set audit_sql "
		select	*,
			a.audit_object_id as ticket_id,
			extract(epoch from a.audit_date) as audit_date_epoch,
			to_char(a.audit_date, 'J') as audit_date_julian,
			im_category_from_id(audit_object_status_id) as audit_object_status,
			substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as audit_ticket_queue_id,
			substring(audit_value from 'ticket_assignee_id\\t(\[^\\n\]*)') as audit_ticket_assignee_id
		from	im_audits a
		where	audit_object_id in (
				select	t.ticket_id
				from	im_tickets t,
					im_projects p
				where	p.project_id = t.ticket_id and
					p.parent_id = :sla_id
					$extra_where
			)
		order by
			ticket_id,
			a.audit_date
	"
	db_foreach audit $audit_sql {
	    if {"" == $audit_object_status} { set audit_object_status "NULL" }
	    if {$debug_p} { append debug_html "<li>sla_id=$sla_id, $ticket_id: $audit_date: $audit_object_status" }
	    set epoch_{$ticket_id}($audit_date_epoch) $audit_object_status_id
	    set julian_{$ticket_id}($audit_date_julian) $audit_object_status_id

	    set queue_id $audit_ticket_queue_id
	    if {"" == $queue_id} { set queue_id $audit_ticket_assignee_id }
	    set queue_{$ticket_id}($audit_date_epoch) $queue_id
	}

	# Loop through all open tickets
	ns_log Notice "im_sla_ticket_solution_time_sweeper: ticket_list=[array names name]"
	foreach ticket_id [array names name] {
	    
	    incr total_tickets_processed
	    if {$total_tickets_processed > $limit} { 
		return "
			<ul>$debug_html</ul><br>
			<ul>$time_html</ul><br>
		"
	    }

	    # Ticket name
	    set ticket_name $name($ticket_id)
	    ns_log Notice "im_sla_ticket_solution_time_sweeper: #$total_tickets_processed: Processing events for ticket_id=$ticket_id name=$ticket_name"
    
	    if {$debug_p} { 
		append time_html "<li><b>sla_id=$sla_id, $ticket_id : $ticket_name</b>" 
		append time_html "<table cellspacing=1 cellpadding=1>
			<tr class=rowtitle>
			<td class=rowtitle>Epoch</td>
			<td class=rowtitle>Date</td>
			<td class=rowtitle>Event</td>
			<td class=rowtitle>Duration<br>Seconds</td>
			<td class=rowtitle>Count<br>Duration?</td>
			<td class=rowtitle>Last<br>Queue</td>
			<td class=rowtitle>Queue</td>
			<td class=rowtitle>Resolution<br>Seconds</td>
			<td class=rowtitle>Resolution<br>Minutes</td>
			<td class=rowtitle>Resolution<br>Hours</td>
			<td class=rowtitle>Resolution time per Group</td>
			</tr>\n"
	    }

	    # Copy the epoc_12345 hash into "hash" for easier access.
	    array unset hash
	    array set hash [array get epoch_{$ticket_id}]

	    # Copy assignments hash into "assig" for easier access.
	    array unset queue_hash
	    array set queue_hash [array get queue_{$ticket_id}]

	    # Copy labour_start and labour_end hashes
	    array unset labour_start_hash
	    array unset labour_end_hash
	    array set labour_start_hash [array get labour_start_groups_{$ticket_id}]
	    array set labour_end_hash [array get labour_end_groups_{$ticket_id}]

	    # Array of counters per assigned queue or group
	    array unset queue_resolution_time

	    # Loop through the hash in time order and process the various events.
	    set resolution_seconds 0.000
	    
	    # --------------------------------------------------------------------
	    # Lifetime: Set to 1 by "creation" event and set to 0 by "now" event

	    # Status variable: True between creation_date and now()
	    set ticket_lifetime_p 0

	    # Status variable: True during service hours
	    set ticket_service_hour_p 0

	    # Status variable: True during queue labour time
	    # This variable is true by default.
	    set ticket_labour_hour_p 1

	    # Status variable: True while the ticket status is "open"
	    set ticket_open_p 0

	    # Status variable: Does the last interval count for resolution time?
	    set count_duration_p 0

	    # Counter from last, reset by "creation" event, this is just a default.
	    set last_epoch $start_epoch($ticket_id)

	    # Initialize counter for different queues
	    set queue_id ""
	    set queue_name ""
	    set last_queue_id ""
	    set last_queue_name ""
	    
	    # Loop through events per ticket
	    ns_log Notice "im_sla_ticket_solution_time_sweeper: Looping through events for ticket_id=$ticket_id"
	    foreach e [lsort [array names hash]] {

		set event_full $hash($e)
		set event [lindex $event_full 0]
		
		# Calculate duration since last event
		set duration_epoch [expr $e - $last_epoch]

		# Which queue is responsible for the time passed?
		if {[info exists queue_hash($e)]} { 
		    set last_queue_id $queue_id
		    set queue_id $queue_hash($e)
		    if {"" != $queue_id} { set queue_name [util_memoize [list db_string queue "select group_name from groups where group_id = $queue_id" -default ""]] }
		    if {"" != $last_queue_id} { set last_queue_name [util_memoize [list db_string queue "select group_name from groups where group_id = $last_queue_id" -default ""]] }

		    # After a change in queues we have to check if the new queue is working now.
		    if {$queue_id != $last_queue_id} {
			# By default set the labour flag to 1 as there default unless there is an exception for this queue
			set ticket_labour_hour_p 1
			# Check if the new guys are working at the moment
			if {[info exists labour_hours_hash($queue_id)]} {
			    set e_julian [im_date_epoch_to_julian $e]
			    set e_dow [expr ($e_julian + 1) % 7]
			    set e_time [string range [im_date_epoch_to_time $e] 0 4]
			    set labour_hours_list $labour_hours_hash($queue_id)
			    set labour_hours [lindex $labour_hours_list $e_dow]
			    set ticket_labour_hour_p 0
			    foreach sh $labour_hours {
				    set labour_start [lindex $sh 0]
				    set labour_end [lindex $sh 1]
				if {[string compare $labour_start $e_time] <= 0 && [string compare $e_time $labour_end] <= 0} {
				    # The event's time ($e_time) is between start and end time
				    set ticket_labour_hour_p 1
				}
			    }
			}
		    }
		}

		# Event can be a ticket_status_id or {creation service_start service_end now}
		switch $event {
		    creation {
			# Creation of ticket. Assume that it's open now and that it's created
			# during service hours (otherwise the taximeter will run until the next day...)
			set resolution_seconds 0.000
			set count_duration_p 0
			set last_epoch $e
			set ticket_lifetime_p 1
			set ticket_service_hour_p [im_sla_management_epoch_in_service_hours $e $service_hours_list]
			set ticket_open_p 1	
		    }
		    service_start {
			# Check if we were to count the duration until now
			set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p && $ticket_labour_hour_p]
			# Start counting the time from now on.
			set ticket_service_hour_p 1
		    }
		    service_end {
			# Check if we were to count the duration until now
			set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p && $ticket_labour_hour_p]
			# Don't count time from now on until the next service_start
			set ticket_service_hour_p 0
		    }
		    labour_start {
			# Check if the currently assigned queue is affected
			set affected_groups [list]
			if {[info exists labour_start_hash($e)]} { set affected_groups $labour_start_hash($e) }
			if {-1 == [lsearch $affected_groups $queue_id]} { continue }

			# Check if we were to count the duration until now
			set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p && $ticket_labour_hour_p]
			# Start counting the time from now on.
			set ticket_labour_hour_p 1
		    }
		    labour_end {
			# Check if the currently assigned queue is affected
			set affected_groups [list]
			if {[info exists labour_end_hash($e)]} { set affected_groups $labour_end_hash($e) }
			if {-1 == [lsearch $affected_groups $queue_id]} { continue }

			# Check if we were to count the duration until now
			set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p && $ticket_labour_hour_p]
			# Don't count time from now on until the next labour_start
			set ticket_labour_hour_p 0
		    }
		    now {
			# Check if we were to count the duration until now
			set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p && $ticket_labour_hour_p]
			# Current time. Don't count from here into the future...
			set ticket_lifetime_p 0
		    }
		    "" {
			# No event. Should not occur. But then just ignore...
		    }
		    default {
			# Probably found a status change here"
			if {![string is integer $event]} { 
			    ns_log Error "im_sla_ticket_solution_time: found invalid integer for ticket_status_id: $event" 
			    continue
			}

			# Check if we were to count the duration until now
			set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p && $ticket_labour_hour_p]

			# Determine ticket status"
			if {[lsearch $ticket_open_states $event] > -1} {
			    # Open status: continue counting...
			    set ticket_open_p 1
			} else {
			    # Not open, so thats closed probably...
			    set ticket_open_p 0
			}
		    }
		}

		if {$count_duration_p} {
		    # Total resolution time counter
		    set resolution_seconds [expr $resolution_seconds + $duration_epoch]

		    # Resolution time per queue
		    if {"" != $last_queue_id} {
			set seconds 0.0
			if {[info exists queue_resolution_time($last_queue_id)]} { set seconds $queue_resolution_time($last_queue_id) }
			set seconds [expr $seconds + $duration_epoch]
			set queue_resolution_time($last_queue_id) $seconds
		    }
		}

		set color black
		if {!$count_duration_p} { set color red }
		if {$debug_p} {
		    set event_pretty $event
		    if {[string is integer $event]} {
			set event_pretty [util_memoize [list db_string cat "select category from im_categories where category_id = $event" -default ""]]
		    }
		    if {$event == $event_pretty} { set event_pretty "" } else { set event_pretty "($event_pretty)" }
		    set restime_html ""
		    foreach q [lsort -integer [array names queue_resolution_time]] {
			set q_name [util_memoize [list db_string queue "select group_name from groups where group_id = $q" -default ""]]
			append restime_html "$q_name=[expr round(100 * $queue_resolution_time($q)) / 100.0], "
		    }
		    append time_html "
			<tr>
				<td>[expr round(100.0 * $e) / 100.0]</td>
				<td>[im_date_epoch_to_ansi $e] [im_date_epoch_to_time $e]</td>
				<td><font color=$color><nobr>$event $event_pretty</nobr></font></td>
				<td align=right>[expr round(100.0 * $duration_epoch) / 100.0]</td>
				<td align=right>$count_duration_p</td>
				<td>$last_queue_name</td>
				<td>$queue_name</td>
				<td align=right>[expr round(100.0 * $resolution_seconds) / 100.0]</td>
				<td align=right>[expr round(100.0 * $resolution_seconds / 60.0) / 100.0 ]</td>
				<td align=right>[expr round(100.0 * $resolution_seconds / 3600.0) / 100.0]</td>
				<td>$restime_html</td>
			</tr>
                    "
		}
	    
		set last_epoch $e
	    }

	    if {$debug_p} {
		append time_html "</table>\n"
	    }
	
	    ns_log Notice "im_sla_ticket_solution_time_sweeper: Calculate the array of resolution times per queue"
	    set restimes {}
	    foreach gid $group_list {
		set r 0.0
		if {[info exists queue_resolution_time($gid)]} { set r $queue_resolution_time($gid) }
		lappend restimes $r
	    }
	    set restime_per_queue [join $restimes ","]

	    # Update the resolution time of the ticket
	    db_dml update_resolution_time "
		update im_tickets set 
			ticket_resolution_time = [expr $resolution_seconds / 3600.0],
			ticket_resolution_time_dirty = now(),
			ticket_resolution_time_per_queue = '{$restime_per_queue}'
		where ticket_id = :ticket_id
	    "

	    if {$debug_p} {
		append time_html "<li><b>sla_id=$sla_id, $ticket_id : $ticket_name</b>: $resolution_seconds\n"
	    }
		
	    # End of looping through one ticket
	}

	# End of looping through one SLA
    }

    return "
	<ul>$debug_html</ul><br>
	<ul>$time_html</ul><br>
    "

}






