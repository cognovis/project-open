# /packages/intranet-helpdesk/www/action.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Perform bulk actions on tickets
    
    @action_id	One of "Intranet Ticket Action" categories.
    		Determines what to do with the list of "tid"
		ticket ids.
		The "aux_string1" field of the category determines
		the page to be called for pluggable actions.

    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    tid:integer,multiple,optional
    action_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

# 30500, 'Close'
# 30510, 'Close &amp; notify'
# 30520, 'Duplicated'
# 30590, 'Delete'
# 30599, 'Nuke'

# Deal with funky input parameter combinations
if {"" == $action_id} { ad_returnredirect $return_url }
if {![info exists tid]} { set tid {} }
if {0 == [llength $tid]} { ad_returnredirect $return_url }

set action_name [im_category_from_id $action_id]
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

switch $action_id {
	30500 {
	    # Close
	    foreach ticket_id $tid {
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		db_dml close_ticket "
			update im_tickets set ticket_status_id = [im_ticket_status_closed]
			where ticket_id = :ticket_id
	        "
	    }
	}
	30510 {
	    # Close & notify
	    foreach ticket_id $tid {
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		db_dml close_ticket "
			update im_tickets set ticket_status_id = [im_ticket_status_closed]
			where ticket_id = :ticket_id
	        "
	    }
	}
	30590 {
	    # Delete
	    foreach ticket_id $tid {
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		db_dml close_ticket "
			update im_tickets set ticket_status_id = [im_ticket_status_deleted]
			where ticket_id = :ticket_id
	        "
	    }
	}
	30599 {
	    # Nuke
	    if {!$user_is_admin_p} { ad_return_complaint 1 "User needs to be SysAdmin in order to 'Nuke' tickets.<br>Please use 'Delete' otherwise." }
	    foreach ticket_id $tid {
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$admin} { ad_return_complaint 1 $action_forbidden_msg }
		im_project_nuke $ticket_id
	    }
	}
	default {

	    # Check if we've got a custom action to perform
	    set redirect_base_url [db_string redir "select aux_string1 from im_categories where category_id = :action_id" -default ""]
	    if {"" != [string trim $redirect_base_url]} {
		# Redirect for custom action
		set redirect_url [export_vars -base $redirect_base_url {action_id}]
		foreach ticket_id $tid { append redirect_url "&tid=$ticket_id"}
#		ad_return_complaint 1 $redirect_url
		ad_returnredirect $redirect_url
	    } else {
		ad_return_complaint 1 "Unknown Ticket action: $action_id='[im_category_from_id $action_id]'"
	    }
	}
    }


ad_returnredirect $return_url
