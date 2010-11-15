# /packages/intranet-sla-management/www/associate-2.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Associate the ticket_ids in "tid" with one of the specified objects.
    target_object_type specifies the type of object to associate with and
    determines which parameters are used.
    @author frank.bergmann@project-open.com
} {
    { tid ""}
    { target_object_type "" }
    { action_name "" }
    { indicator_id "" }
    { return_url "/intranet-sla-management/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-sla-management.Associate_Ticket_With_$target_object_type "Associate Ticket With $target_object_type"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set action_forbidden_msg [lang::message::lookup "" intranet-sla-management.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]

# Check that the user has write permissions on all select tickets
set first_param_id [lindex $tid 0]
set sla_id [db_string param_sla "select param_sla_id from im_sla_parameters where param_id = :first_param_id" -default ""]
im_project_permissions $current_user_id $sla_id view read write admin
if {!$write} { ad_return_complaint 1 $action_forbidden_msg }

foreach t $tid {
    # Check that t is an integer
    im_security_alert_check_integer -location "Helpdesk: Associate" -value $t
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

switch $target_object_type {
    indicator {
	foreach t $tid {
	    # Create a new relationship connecting the indicator with the parameter
	    set rel_id [db_string new_rel "select im_sla_param_indicator_rel__new(null, 'im_sla_param_indicator_rel', :t, :indicator_id, null, :current_user_id, '[ns_conn peeraddr]', 0)"]
	}
    }
    default {
	ad_return_complaint 1 [lang::message::lookup "" intranet-sla-management.Unknown_target_object_type "Unknown object type %target_object_type%"]
    }
}

ad_returnredirect $return_url

