# /packages/intranet-riskmanagement/www/action.tcl
#
# Copyright (C) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Perform bulk actions on risks
    
    @action_id	One of "Intranet Risk Action" categories.
    		Determines what to do with the list of "tid"
		risk ids.
		The "aux_string1" field of the category determines
		the page to be called for pluggable actions.

    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    risk_id:array
    { action_id:integer ""}
    { action "" }
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set user_name [im_name_from_user_id [ad_get_user_id]]

if {"" != $action_id} { set action [im_category_from_id -translate_p 0 $action_id] }
set action_forbidden_msg [lang::message::lookup "" intranet-riskmanagement.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action%'."]

switch [string tolower $action] {
    delete {
	# Delete
	foreach rid [array names risk_id] {
	    set risk_project_id [db_string pid "select risk_project_id from im_risks where risk_id = :rid" -default ""]
	    im_project_permissions $user_id $risk_project_id view read write admin
	    if {!$write} {
		ad_return_complaint 1 $action_forbidden_msg
		ad_script_abort
	    }
	    set value [string tolower $risk_id($rid)]
	    if {"on" == $value} {
		db_string del "select im_risk__delete(:rid) from dual"
	    }
	}
    }
    default {
	# Check if we've got a custom action to perform
	set redirect_base_url [db_string redir "select aux_string1 from im_categories where category_id = :action_id" -default ""]
	if {"" != [string trim $redirect_base_url]} {
	    # Redirect for custom action
	    set redirect_url [export_vars -base $redirect_base_url {action_id return_url}]
	    foreach risk_id $risk_id { append redirect_url "&risk_id=$risk_id"}
	    ad_returnredirect $redirect_url
	} else {
	    ad_return_complaint 1 "Unknown Risk action: $action_id='$action'"
	}
    }
}

ad_returnredirect $return_url
