# /packages/intranet-sla-management/www/service-hours-save.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Associate the ticket_ids in "tid" with one of the specified objects.
    target_object_type specifies the type of object to associate with and
    determines which parameters are used.
    @author frank.bergmann@project-open.com
} {
    sla_id:integer
    hours:array,optional
    { return_url "/intranet-sla-management/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-sla-management.Save_Service_Hours "Save Service Hours"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

# Check that the user has write permissions on all select tickets
im_project_permissions $current_user_id $sla_id view read write admin
if {!$write} { ad_return_complaint 1 "You don't have permissions to perform this action" }

# ---------------------------------------------------------------
# Save the values
# ---------------------------------------------------------------

set start 0
set end 24
set state "off"
foreach dow {0 1 2 3 4 5 6} {

    set debug_html "dow=$dow"
    set service_hours ""
    for {set h 0} {$h < 25} {incr h} {
	set hh $h
	if {[string length $hh] < 2} { set hh "0$hh" } 
	set ck "off"
	set key [string trimleft "$dow$hh" "0"]
	if {"" == $key} { set key "0" }
	if {[info exists hours($key)]} { set ck $hours($key) }

        if {"off" == $state && "off" == $ck} { 
	    set start $h
	    set state "off"
	}

        if {"off" == $state && "on" == $ck} { 
	    set start $h
	    set state "on"
	}

        if {"on" == $state && "off" == $ck} { 

	    # Add start-end to list of service hours
	    set start_pretty $start
	    if {[string length $start_pretty] < 2} { set start_pretty "0$start" }
	    # The end time is the start of the next hour, so we have to add +1 to end
	    set end_pretty [expr $end + 1]
	    if {[string length $end_pretty] < 2} { set end_pretty "0$end_pretty" }
	    lappend service_hours [list "$start_pretty:00" "$end_pretty:00"]

	    set end $h
	    set state "off"
	}

        if {"on" == $state && "on" == $ck} { 
	    set end $h
	    set state "on"
	}

	ns_log Notice "service-hours-save: befor: dow=$dow, h=$hh, start=$start, end=$end, state=$state, ck=$ck"

    }
    set service_hours_hash($dow) $service_hours
}

# -------------------------------------------------------
# Store the service hours into the SLA

# Delete the old service hours if they exist
db_dml del_service_hours "
	delete from im_sla_service_hours
	where sla_id = :sla_id
"

foreach dow {0 1 2 3 4 5 6} {
   db_dml insert_service_hours "
	insert into im_sla_service_hours (
		sla_id,
		dow,
		service_hours
	) values (
		:sla_id,
		:dow,
		'$service_hours_hash($dow)'
	)
   "
}

ad_returnredirect $return_url

