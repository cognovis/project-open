# /packages/intranet-helpdesk/www/action-increase-priority.tcl
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


ad_return_complaint 1 "
<pre>
ticket_ids=$ticket_ids
ticket_id_from_search=$ticket_id_from_search
return_url=$return_url
</pre>
"



ad_returnredirect $return_url
