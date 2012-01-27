# /packages/intranet-helpdesk/www/action-duplicated.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    We get here after the user has choosen the "Duplicate" action of a ticket.
    This page redirects to a "ticket-select" page to select a specific problem 
    ticket and then continues to mark the list of "tid" tickets as duplicates 
    of the selected problem ticket.

    @param tid The list of ticket_id's that should be marked as duplicated
    @action_id The initial action selected by the user as a reference.
    @ticket_status_id Parameter for "ticket-select.tcl": 
    		By default show only open tickets.
    @ticket_type_id Parameter for "ticket-select.tcl":
		By default show only problem tickets.

    @author frank.bergmann@project-open.com
} {
    { tid:integer,multiple {}}
    { ticket_ids {} }
    action_id:integer
    { ticket_id_from_search:integer "" }
    { return_url "/intranet-helpdesk/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if { {} == $ticket_ids} {
    set ticket_ids $tid
}

# ad_return_complaint 1 "<pre>\ntid=$tid\nticket_ids=$ticket_ids\naction_id=$action_id\nticket_id_from_search=$ticket_id_from_search\nreturn_url=$return_url\n</pre>"


# Deal with funky input parameter combinations
if {![info exists tid]} { set tid {} }
if {"" == $action_id} { ad_returnredirect $return_url }
if {{} == $tid} { ad_returnredirect $return_url }

# ---------------------------------------------------------------
# Redirect to select the ticket_id if necessary
# ---------------------------------------------------------------

if {"" == $ticket_id_from_search} {
    set current_url [export_vars -base "/intranet-helpdesk/action-duplicated" {action_id}]
    set select_url [export_vars -base "/intranet-helpdesk/ticket-select" {ticket_ids {return_url $current_url}}] 
    ad_returnredirect $select_url
}


# ---------------------------------------------------------------
# Perform the action
# ---------------------------------------------------------------

# 30500, 'Close'
# 30510, 'Close &amp; notify'
# 30520, 'Duplicated'
# 30590, 'Delete'

# Deal with funky input parameter combinations
if {"" == $action_id} { ad_returnredirect $return_url }
if {![info exists tid]} { set tid {} }
if {0 == [llength $tid]} { ad_returnredirect $return_url }


foreach ticket_id $tid {
    
    # Write Audit Trail
    im_project_audit -project_id $ticket_id -action before_update

    db_transaction {
	# Close the ticket
	db_dml close_ticket "
		update	im_tickets
		set	ticket_status_id = [im_ticket_status_duplicate]
		where	ticket_id = :ticket_id
	"

	im_helpdesk_new_ticket_ticket_rel \
	    -ticket_id $ticket_id \
	    -ticket_id_from_search $ticket_id_from_search \
	    -sort_order 0
    }

    # Write Audit Trail
    im_project_audit -project_id $ticket_id -action after_update

}

ad_returnredirect $return_url
