# /packages/intranet-helpdesk/www/nuke-2.tcl
#
# Copyright (C) 1998-2008 ]project-open[

ad_page_contract {
    Remove a user from the system completely
    @author frank.bergmann@project-open.com
} {
    ticket_id:integer,notnull
    { return_url "/intranet-helpdesk/" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set page_title [_ intranet-core.Done]
set context_bar [im_context_bar [list /intranet/projects/ "[lang::message::lookup "" intranet-helpdesk.Helpdesk "Helpdesk"]"] $page_title]

set current_user_id [ad_maybe_redirect_for_registration]
im_ticket_permissions $current_user_id $ticket_id view read write admin

if {!$admin} {
    ad_return_complaint 1 "You need to have administration rights for this ticket."
    return
}


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

im_project_nuke $ticket_id

set return_to_admin_link "<a href=\"$return_url\">[lang::message::lookup "" intranet-helpdesk.Return_to_Helpdesk "Return to Helpdesk"]</a>" 

