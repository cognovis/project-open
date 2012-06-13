# /packages/intranet-sla-management/www/related-objects-associate.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Allow the user to create new OpenACS relationships.
    @author frank.bergmann@project-open.com
} {
    { tid "" }
    { object_id ""}
    { action_name "associate" }
    { return_url "/intranet-sla-management/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Associate_Param_With_Other_Object "Associate SLA Parameter With Another Object"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this param."]
if {"" == $tid} { set tid $object_id }

# Check that the user has write permissions on all select params
set first_param_id [lindex $tid 0]
set sla_id [db_string param_sla "select param_sla_id from im_sla_parameters where param_id = :first_param_id" -default ""]
im_project_permissions $current_user_id $sla_id view read write admin
if {!$write} { ad_return_complaint 1 $action_forbidden_msg }


foreach param_id $tid {

    # Check that param_id is an integer
    im_security_alert_check_integer -location "SLA Parameters: Associate" -value $param_id
}

