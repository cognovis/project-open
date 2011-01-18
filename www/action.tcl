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
# 30590, 'Delete'
# 30599, 'Nuke'

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
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		db_dml close_ticket "
			update im_tickets set 
				ticket_status_id = [im_ticket_status_closed],
				ticket_done_date = now()
			where ticket_id = :ticket_id
	        "
		db_dml close_ticket "
			update im_projects set 
				project_status_id = [im_project_status_closed]
			where project_id = :ticket_id
	        "

		im_ticket::add_reply -ticket_id $ticket_id -subject \
		    [lang::message::lookup "" intranet-helpdesk.Closed_by_user "Closed by %user_name%"]

		# Cancel associated workflow
		im_workflow_cancel_workflow -object_id $ticket_id
		
		# Close associated forum by moving to "deleted" folder
		db_dml move_to_deleted "
			update im_forum_topic_user_map
        	        set folder_id = 1
                	where topic_id in (
				select	t.topic_id
				from	im_forum_topics t
				where	t.object_id = :ticket_id
			)
		"
	    }

	    if {$action_id == 30510} {
		# Close & Notify - Notify all stakeholders
		ad_returnredirect [export_vars -base "/intranet-helpdesk/notify-stakeholders" {tid action_id return_url}]
	    }
	}
	30530 {
	    # Reopen
	    foreach ticket_id $tid {
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		db_dml reopen_ticket "
			update im_tickets set ticket_status_id = [im_ticket_status_open]
			where ticket_id = :ticket_id
	        "

		# Re-Open the project as well
		db_dml close_ticket "
			update im_projects set 
				project_status_id = [im_project_status_open]
			where project_id = :ticket_id
	        "

		im_ticket::add_reply -ticket_id $ticket_id -subject \
		    [lang::message::lookup "" intranet-helpdesk.Re_opened_by_user "Re-opened by %user_name%"]
	    }
	}
	30540 {
	    # Associated
	    if {"" == $tid} { ad_returnredirect $return_url }
	    ad_returnredirect [export_vars -base "/intranet-helpdesk/associate" {tid}]
	}
	30550 {
	    # Escalate
	    if {"" == $tid} { ad_returnredirect $return_url }
	    if {[llength $tid] > 1} { ad_return_complaint 1 "[lang::message::lookup "" intranet-helpdesk.Can_excalate_only_one_ticket "
		We can escalate only one ticket at a time" ]" }
	    ad_returnredirect [export_vars -base "/intranet-helpdesk/new" {escalate_from_ticket_id $tid}]
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

	30590 {
	    # Delete
	    foreach ticket_id $tid {
		im_ticket_permissions $user_id $ticket_id view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		db_dml close_ticket "
			update im_tickets set ticket_status_id = [im_ticket_status_deleted]
			where ticket_id = :ticket_id
	        "
		im_ticket::add_reply -ticket_id $ticket_id -subject \
		    [lang::message::lookup "" intranet-helpdesk.Deleted_by_user "Deleted by %user_name%"]
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
		set redirect_url [export_vars -base $redirect_base_url {action_id return_url}]
		foreach ticket_id $tid { append redirect_url "&tid=$ticket_id"}

#		ad_return_complaint 1 $redirect_url

		ad_returnredirect $redirect_url
	    } else {
		ad_return_complaint 1 "Unknown Ticket action: $action_id='[im_category_from_id $action_id]'"
	    }
	}
    }


ad_returnredirect $return_url
