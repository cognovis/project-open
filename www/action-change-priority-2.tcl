# /packages/intranet-helpdesk/www/action-change-priority-2.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {

    @param tid The list of ticket_id's 
    @author klaus.hofeditz@project-open.com
} {
    { tid:integer,multiple {}}
    { ticket_ids "" }
    { ticket_prio "" }
    { return_url "/intranet-helpdesk/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Title_Change_Prio "Change Ticket Prio"]

if { ""==$ticket_prio  } {
    ad_return_complaint 1  [lang::message::lookup "" intranet-helpdesk.Please_Provide_Ticket_Prio "Please choose Prio"]
}

# ********************************************************************
# Simplified implementation - would need to be improved -> trigger WF!   
# ********************************************************************

set err_mess ""
foreach ticket_id $tid {
	im_ticket::audit                -ticket_id $ticket_id -action "before_update"
	if {[catch {
		db_dml update_ticket_prio "update im_tickets set ticket_prio_id = :ticket_prio where ticket_id = :ticket_id"
	} err_msg]} {
		set msg [lang::message::lookup "" intranet-helpdesk.Change_Prio_Problems "We found problems while updating the ticket_status:<br> $err_mess"]	
		ad_return_complaint 1 "$msg<br>$err_msg"
		break
	}
	im_ticket::audit                -ticket_id $ticket_id -action "after_update"
	
	set ticket_assignee_id ""
	set ticket_assignee_id [db_string get_ticket_asignee_id "select ticket_assignee_id from im_tickets where ticket_id=:ticket_id" -default 0]
	if { "" == $ticket_assignee_id } {
		set ticket_assignee [parameter::get -package_id [apm_package_id_from_key intranet-helpdesk] -parameter "HelpdeskOwner" -default ""]
	    	if { "" == $ticket_assignee_id } {
			set ticket_assignee [parameter::get -package_id [apm_package_id_from_key acs-kernel] -parameter "SystemOwner" -default ""]
		}

	        # tmp patch due to issues with parameter
	        set ticket_assignee "klaus.hofeditz@project-open.com"

	        set ticket_assignee_id [db_string get_ticket_asignee_id "select party_id from parties where email = :ticket_assignee" -default 0]
	    	if { "" == $ticket_assignee_id  } {
			ad_return_complaint 1 [lang::message::lookup "" intranet-helpdesk.Err_Mess_No_Email_Found "Ticket prio changed, but could not find any recipient to notify. Please contact the owner of the helpdesk"]
	    	}
	}	

        set subject [lang::message::lookup "" intranet-helpdesk.Subject_Prio_Change "Ticket Prio Change"]
	set body [lang::message::lookup "" intranet-helpdesk.Body_Prio_Change "A priority of a ticket has been changed:\n\n"]
	set base_url  [parameter::get -package_id [apm_package_id_from_key acs-kernel] -parameter "SystemURL" -default 60]
	set ticket_name [db_string get_ticket_name "select project_name from im_projects where project_id = :ticket_id" -default 0]
	append body "$ticket_name \n set to prio: [im_category_from_id $ticket_prio] \n $base_url/intranet-helpdesk/new?form_mode=display&ticket_id=$ticket_id" 
	set sql "select acs_mail_nt__post_request (:current_user_id, :ticket_assignee_id, 'f', :subject, :body, 0)"

	set err ""
	if {[catch {
	    	set foo [db_string send_notif_email $sql -default 0]
	} err_msg]} {
		ad_return_complaint 1 $err_msg
		append err [lang::message::lookup "" intranet-helpdesk.Error_Sending_Notif-Mail "Error sending notification mail, please consider notification by email"]
		append err "<br>"
		append err $err_msg
	}
}

if { "" == $err } {
	set usr_mess  [lang::message::lookup "" intranet-helpdesk.Ticket_Assignee_Informed "Ticket prio updated, ticket assignee(s) informed by email"]
} else {
	set usr_mess  [lang::message::lookup "" intranet-helpdesk.Change_Prio_Problems "We found problems while updating the ticket_status:<br> $err"]
}
