# /packages/intranet-helpdesk/www/request-sla.tcl
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
    { return_url "/intranet/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Request_SLA "Request a Service Contract"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set ticket_navbar_html ""
