# /packages/intranet-helpdesk/www/relationship-new.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Allow the user to associate the current ticket with a new object
    using an OpenACS relationship.
    @author frank.bergmann@project-open.com
} {
    { tid ""}
    { action_name "associate" }
    { return_url "/intranet-helpdesk/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Associate_Ticket_With_Other_Object "Associate Tickets With Another Object"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

# Check that the user has write permissions on all select tickets
foreach ticket_id $tid {

    # Check that ticket_id is an integer
    im_security_alert_check_integer -location "Helpdesk: Associate" -value $ticket_id

    im_ticket_permissions $current_user_id $ticket_id view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
}

set first_ticket_id [lindex $tid 0]



