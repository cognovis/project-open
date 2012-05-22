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
set user_name [im_name_from_user_id [ad_get_user_id]]

# 30500, 'Close'
# 30510, 'Close &amp; notify'
# 30520, 'Duplicated'
# 30060, 'Resolved'
# 30590, 'Delete'
# 30599, 'Nuke'

# Customers should not be able to close, delete or nuke tickets  
if { [im_profile::member_p -profile_id [im_customer_group_id] -user_id $user_id] && ($action_id == 30500 || $action_id == 30510 || $action_id == 30590 || $action_id == 30599) } {
    ad_return_complaint 1  [lang::message::lookup "" intranet-helpdesk.No_Permission "As a customer you are not allowed to delete, nuke or close tickets. If the ticket is 'resolved' please mark it as such. "]
}

# Deal with funky input parameter combinations
if {"" == $action_id} { ad_returnredirect $return_url }
if {![info exists tid]} { set tid {} }
if {0 == [llength $tid]} { ad_returnredirect $return_url }

set action_name [im_category_from_id $action_id]
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

switch $action_id {
	30500 - 30510 {
	    # Close and "Close & Notify"
	    foreach ticket_id $tid {
		im_ticket::audit		-ticket_id $ticket_id -action "before_update"
		im_ticket::check_permissions	-ticket_id $ticket_id -operation "write"
		im_ticket::set_status_id	-ticket_id $ticket_id -ticket_status_id [im_ticket_status_closed]
		im_ticket::update_timestamp	-ticket_id $ticket_id -timestamp "done"
		im_ticket::close_workflow	-ticket_id $ticket_id
		im_ticket::close_forum		-ticket_id $ticket_id
		im_ticket::audit		-ticket_id $ticket_id -action "after_update"
	    }

	    if {$action_id == 30510} {
		# Close & Notify - Notify all stakeholders
		ad_returnredirect [export_vars -base "/intranet-helpdesk/notify-stakeholders" {tid action_id return_url}]
	    }
	}
	30530 - 30532 {
	    # Reopen
	    foreach ticket_id $tid {
		im_ticket::audit		-ticket_id $ticket_id -action "before_update"
		im_ticket::check_permissions	-ticket_id $ticket_id -operation "write"
		im_ticket::set_status_id	-ticket_id $ticket_id -ticket_status_id [im_ticket_status_open]
		im_ticket::audit		-ticket_id $ticket_id -action "after_update"
	    }

	    if {$action_id == 30532} {
		# Reopen & Notify - Notify all stakeholders
		ad_returnredirect [export_vars -base "/intranet-helpdesk/notify-stakeholders" {tid action_id return_url}]
	    }
	}
	30540 {
	    # Associated
	    if {"" == $tid} { ad_returnredirect $return_url }
	    ad_returnredirect [export_vars -base "/intranet-helpdesk/associate" {tid}]
	}
    	30545 {
            # Change Prio
	    foreach ticket_id $tid {
                set redirect_url [export_vars -base "/intranet-helpdesk/action-change-priority" {action_id return_url}]
                foreach ticket_id $tid { append redirect_url "&tid=$ticket_id"}
                ad_returnredirect $redirect_url
	    }
        }
	30550 {
	    # Escalate
	    if {"" == $tid} { ad_returnredirect $return_url }
	    if {[llength $tid] > 1} { ad_return_complaint 1 "[lang::message::lookup "" intranet-helpdesk.Can_excalate_only_one_ticket "
		We can escalate only one ticket at a time" ]" }
	    ad_returnredirect [export_vars -base "/intranet-helpdesk/new" {{escalate_from_ticket_id $tid}}]
	}
	30552 {
	    # Close Escalated Tickets
	    if {"" == $tid} { ad_returnredirect $return_url }
	    set escalated_tickets [db_list escalated_tickets "
		select	t.ticket_id
		from	im_tickets t,
			acs_rels r,
			im_ticket_ticket_rels ttr
		where	r.rel_id = ttr.rel_id and
			r.object_id_one in ([join $tid ","]) and
			r.object_id_two = t.ticket_id
	    "]

	    # Redirect to this page, but with Action=Close (30500) to close the escalated tickets
	    ad_returnredirect [export_vars -base "/intranet-helpdesk/action" {{action_id 30500} {tid $escalated_tickets} return_url}]
	}
	30560 {
	    # Resolved
	    foreach ticket_id $tid {
		im_ticket::audit		-ticket_id $ticket_id -action "before_update"
		im_ticket::check_permissions	-ticket_id $ticket_id -operation "write"
		im_ticket::set_status_id	-ticket_id $ticket_id -ticket_status_id [im_ticket_status_resolved]
		im_ticket::update_timestamp	-ticket_id $ticket_id -timestamp "done"
		im_ticket::audit		-ticket_id $ticket_id -action "after_update"
	    }
	}
	30590 {
	    # Delete
	    foreach ticket_id $tid {
		im_ticket::audit		-ticket_id $ticket_id -action "before_update"
		im_ticket::check_permissions	-ticket_id $ticket_id -operation "write"
		im_ticket::set_status_id	-ticket_id $ticket_id -ticket_status_id [im_ticket_status_deleted]
		im_ticket::close_workflow	-ticket_id $ticket_id
		im_ticket::close_forum		-ticket_id $ticket_id
		im_ticket::audit		-ticket_id $ticket_id -action "after_update"
	    }
	}
	30599 {
	    # Nuke
	    if {!$user_is_admin_p} { 
	        ad_return_complaint 1 "User needs to be SysAdmin in order to 'Nuke' tickets.<br>Please use 'Delete' otherwise." 
		ad_script_abort
	    }
	    foreach ticket_id $tid {
	        im_ticket::check_permissions	-ticket_id $ticket_id -operation "admin"
		im_project_nuke $ticket_id
	    }
	}
	default {
	    # Check if we've got a custom action to perform
	    set redirect_base_url [db_string redir "select aux_string1 from im_categories where category_id = :action_id" -default ""]
	    if {"" != [string trim $redirect_base_url]} {
		# Redirect for custom action
		set redirect_url [export_vars -base $redirect_base_url {action_id return_url}]
		foreach ticket_id $tid { append redirect_url "&tid=$ticket_id"}
		ad_returnredirect $redirect_url
	    } else {
		ad_return_complaint 1 "Unknown Ticket action: $action_id='[im_category_from_id $action_id]'"
	    }
	}
    }


ad_returnredirect $return_url
