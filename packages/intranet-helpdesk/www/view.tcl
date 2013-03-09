# /packages/intranet-timesheet2-task/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    { ticket_id "" }
    { plugin_id:integer "" }
}

set page_title [_ intranet-helpdesk.Ticket_Info]
set context [list $page_title]
set current_user_id [ad_conn user_id]
set user_id $current_user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

# ------------------------------------------------------------------
# Get ticket_customer_id from information available in order to set options right
# ------------------------------------------------------------------

db_1row ticket_info "
	select	t.*, p.*,
		t.ticket_customer_deadline::date as ticket_customer_deadline,
		p.company_id as ticket_customer_id
	from	im_projects p,
		im_tickets t
	where	p.project_id = t.ticket_id
		and p.project_id = :ticket_id
    "


# Check if we can get the ticket_customer_id.
# We need this field in order to limit the customer contacts to show.
if {![exists_and_not_null ticket_customer_id] && [exists_and_not_null ticket_sla_id] && "new" != $ticket_sla_id} {
    set ticket_customer_id [db_string cid "select company_id from im_projects where project_id = :ticket_sla_id" -default ""]
}



# ---------------------------------------------------------------
# Ticket Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
if {[info exists ticket_id]} { ns_set put $bind_vars ticket_id $ticket_id }


if {![info exists ticket_id]} { set ticket_id "" }

set ticket_parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='helpdesk'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet-helpdesk/new?ticket_id=$ticket_id" \
    -plugin_url "/intranet-helpdesk/new" \
    $ticket_parent_menu_id \
    $bind_vars "" "pagedesriptionbar" "helpdesk_summary"] 

