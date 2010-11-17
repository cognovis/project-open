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
# Components
# ---------------------------------------------------------------------

ad_proc -public im_sla_parameter_component {
    -object_id
} {
    Returns a HTML component to show a list of SLA parameters with the option
    to add more parameters
} {
    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/sla-parameters-list-component"]
    return [string trim $result]
}


ad_proc -public im_sla_parameter_list_component {
    {-project_id ""}
    {-param_id ""}
} {
    Returns a HTML component with a mix of SLA parameters and indicators.
    The component can be used both on the SLAViewPage and the ParamViewPage.
} {
    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list project_id $project_id] \
		    [list param_id $param_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/indicator-component"]
    return [string trim $result]
}


ad_proc -public im_sla_service_hours_component {
    {-project_id ""}
} {
    Returns a HTML component with a component to display and modify working hours
    for the 7 days of the week.
} {
    set params [list \
		    [list base_url "/intranet-sla-management/"] \
		    [list project_id $project_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sla-management/www/service-hours-component"]
    return [string trim $result]
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

# ----------------------------------------------------------------------
# Calculate the Solution time for every ticket
# ---------------------------------------------------------------------

ad_proc -public im_sla_ticket_solution_time {
    {-ticket_id ""}
} {
    Calculates "resolution time" for all open tickets.
} {
    # ToDo!!!: Check the semaphore if this is the only thread runnging

    set debug_html ""

    # ----------------------------------------------------------------
    # Define the service hours per weekday
    #
    set service_hours_list [list]
    # Sunday no service
    lappend service_hours_list {}
    # Monday - Friday from 9:00 til 18:00
    lappend service_hours_list {09:00 18:00}	
    lappend service_hours_list {09:00 18:00}
    lappend service_hours_list {09:00 18:00}
    lappend service_hours_list {09:00 18:00}
    lappend service_hours_list {09:00 18:00}
    # Saturday from 9:00 til 12:00
    lappend service_hours_list {09:00 18:00}

    # Returns a list with weekday names from 0=Su, 1=Mo to 6=Sa
    set dow_list [im_sla_day_of_week_list]

    # ----------------------------------------------------------------
    # Get the list of all selected ticket (either all open ones or one
    # ticket in particular.
    #
    set extra_where "and t.ticket_status_id in ([join [im_sub_categories [im_ticket_status_open]] ","])"
    if {"" != $ticket_id} { 
	set extra_where "and t.ticket_id = :ticket_id"
    }
    set ticket_sql "
	select	*,
		extract(epoch from t.ticket_creation_date) as ticket_creation_epoch,
		to_char(t.ticket_creation_date, 'J') as ticket_creation_julian,
		to_char(t.ticket_creation_date, 'YYYY') as ticket_creation_year,
		extract(epoch from now()) as now_epoch,
		to_char(now(), 'J') as now_julian
	from	im_tickets t,
		im_projects p
	where
		t.ticket_id = p.project_id
		$extra_where
    "
    
    db_foreach tickets $ticket_sql {
	append debug_html "
		<li><b>$ticket_id : $project_name</b>
		<li>ticket_creation_date: $ticket_creation_date
		<li>ticket_creation_julian: $ticket_creation_julian
		<li>ticket_creation_epoch: $ticket_creation_epoch
	"
	set name($ticket_id) $project_name
	set start_julian($ticket_id) $ticket_creation_julian
	set start_epoch($ticket_id) $ticket_creation_epoch
	set end_julian($ticket_id) $now_julian
	set epoch_{$ticket_id}($ticket_creation_epoch) "creation"
	set julian_{$ticket_id}($ticket_creation_julian) "creation"
	set epoch_{$ticket_id}($now_epoch) "now"
	set julian_{$ticket_id}($now_julian) "now"
	
	# Loop through all days between start and end and add the start
	# and end of the business hours this day.
	append debug_html "<li>Starting to go loop through julian dates from ticket_creation_julian=$ticket_creation_julian to now_julian=$now_julian ([im_date_julian_to_ansi $ticket_creation_julian] to [im_date_julian_to_ansi $now_julian]\n"
	for {set j $ticket_creation_julian} {$j < $now_julian} {incr j} {
	    
	    # Get the service hours per Day Of Week (0=Su, 1=mo, 6=Sa)
	    # service_hours are like {09:00 18:00}
	    set dow [expr ($j + 1) % 7]
	    set service_hours [lindex $service_hours_list $dow]
	    append debug_html "<li>Ticket: $ticket_id, julian=$j, ansi=[im_date_julian_to_ansi $j], dow=$dow: [lindex $dow_list $dow], service_hours=$service_hours\n"
	    
	    # Example: service_start = '09:00'. Add 0.01 to avoid overwriting.
	    set service_start [lindex $service_hours 0]
	    set service_start_epoch [db_string epoch "select extract(epoch from to_timestamp('$j $service_start', 'J HH24:MM')) + 0.01"]
            set epoch_{$ticket_id}($service_start_epoch) "service_start"
	    append debug_html "<li>Start: julian=$j, ansi=[im_date_julian_to_ansi $j], service_start=$service_start, service_start_epoch=$service_start_epoch\n"

	    # service_end = '18:00'. Add 0.02 to avoid overwriting.
	    set service_end [lindex $service_hours 1]
	    set service_end_epoch [db_string epoch "select extract(epoch from to_timestamp('$j $service_end', 'J HH24:MM')) + 0.02"]
            set epoch_{$ticket_id}($service_end_epoch) "service_end"
	    append debug_html "<li>End: julian=$j, ansi=[im_date_julian_to_ansi $j], service_end=$service_end, service_end_epoch=$service_end_epoch\n"

	}
    }

    # ----------------------------------------------------------------
    # Get all audit records for the open tickets.
    #
    set audit_sql "
	select	*,
		a.audit_object_id as ticket_id,
		extract(epoch from a.audit_date) as audit_date_epoch,
		to_char(a.audit_date, 'J') as audit_date_julian,
		im_category_from_id(audit_object_status_id) as audit_object_status
	from	im_audits a
	where	audit_object_id in (
			select	t.ticket_id
			from	im_tickets t
			where	1=1
				$extra_where
		)
	order by
		ticket_id,
		a.audit_date
    "
    db_foreach audit $audit_sql {
	if {"" == $audit_object_status} { set audit_object_status "NULL" }
	append debug_html "
		<li>$ticket_id: $audit_date: $audit_object_status
	"
	set epoch_{$ticket_id}($audit_date_epoch) $audit_object_status_id
	set julian_{$ticket_id}($audit_date_julian) $audit_object_status_id
    }
    
    # Copy the epoc_12345 hash into "hash" for easier access.
    # ToDo: Remove this detour for performance reasons?
    #
    array set hash [array get epoch_{$ticket_id}]

    # Loop through the hash in time order and process the various
    # events.
    set time_html ""
    set ticket_resolution_seconds 0.000

    set ticket_lifetime_p 1
    set ticket_service_hour_p 1
    set ticket_open_p 1

    # Counter from last 
    set last_epoch $start_epoch($ticket_id)
    
    foreach e [lsort [array names hash]] {
        set event_full $hash($e)
	set event [lindex $event_full 0]

	# Event can be a ticket_status_id or {creation service_start service_end now}
        switch $event {
	    creation {
		# creation of ticket. Assume that it's open now and that it's created
		# during service hours (otherwise the taximeter will run until the next day...)
		set ticket_lifetime_p 1
		set ticket_service_hour_p 1
		set ticket_open_p 1	
	    }
	    service_start {
		set ticket_service_hour_p 1
	    }
	    service_end {
		set ticket_service_hour_p 0
	    }
	    now {
		# Current time. Don't count from here into the future...
		set ticket_lifetime_p 0
	    }
	    default {
		# We assume a valid ticket_status_id here, otherwise we will skip...
		if {![string is integer $event]} { ns_log Error "im_sla_ticket_solution_time: found invalid integer for ticket_status_id: $event" }
		if {[im_category_is_a $event 30000]} { 
		    # Open status: continue counting...
		    set ticket_open_p 1
		} else {
		    # Not open, so thats closed probably...
		    set ticket_open_p 0
		}
	    }
	}
	
	set duration_epoch [expr $e - $last_epoch]
	set count_duration_p [expr $ticket_open_p && $ticket_lifetime_p && $ticket_service_hour_p]
	if {$count_duration_p} {
	    set ticket_resolution_seconds [expr $ticket_resolution_seconds + $duration_epoch]
	}
        set color black
	if {!$count_duration_p} { set color red }
	append time_html "<li>
		<font color=$color>
		[im_date_epoch_to_ansi $e] [im_date_epoch_to_time $e], event=$event, 
		duration=$duration_epoch, count_duration_p=$count_duration_p, resolution_seconds=$ticket_resolution_seconds
		</font>
        "

	set last_epoch $e
    }
    
    ad_return_complaint 1 "
	<ul>
	$debug_html<br>
	</ul>
	<br>
	<ul>
	$time_html<br>
	</ul>
    "
}






