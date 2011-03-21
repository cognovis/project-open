# /packages/intranet-helpdesk/www/request-sla-2.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    This page is called if a user is not a member of any SLA
    and doesn't have the right to see all tickets.
    @author frank.bergmann@project-open.com
} {
    { company_name "" }
    { contact "" }
    { comment "" }
    { return_url "/intranet/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Successfully_Requested_SLA "Successfully Requested a new SLA"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set ticket_navbar_html ""

# ---------------------------------------------------------------
# Create a new SLA Request Ticket
# ---------------------------------------------------------------

set internal_sla_id [im_ticket::internal_sla_id]
set ticket_nr [im_ticket::next_ticket_nr]
set ticket_name "SLA Request $ticket_nr"
set ticket_type_id [im_ticket_type_sla_request]
set ticket_status_id [im_ticket_status_open]
set ticket_note "
Company Name: $company_name
Contact Info: $contact
Comment: $comment
"

set ticket_id [im_ticket::new \
		   -ticket_sla_id $internal_sla_id \
		   -ticket_name $ticket_name \
		   -ticket_nr $ticket_nr \
		   -ticket_customer_contact_id $current_user_id \
		   -ticket_type_id $ticket_type_id \
		   -ticket_status_id $ticket_status_id \
		   -ticket_note $ticket_note \
]


# ---------------------------------------------------------------
# Show a message that the SLS has been created successfully
# ---------------------------------------------------------------

ad_return_template

