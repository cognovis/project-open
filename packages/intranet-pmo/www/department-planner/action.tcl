# /packages/intranet-portfolio-management/www/department-planner/action.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Perform bulk actions on department planner projects
    
    @action_id	One of "Intranet Department Planner Action" categories.
    		Determines what to do with the list of project_id IDs.
		The "aux_string1" field of the department planner action
    		category determines the URL to executefor pluggable actions.

    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    project_priority_id:integer,array
    { action_id:integer "" }
    { return_url "/intranet-portfolio-management/department-planner/index" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_name [im_name_from_user_id [ad_get_user_id]]
set edit_projects_all_p [im_permission $user_id "edit_projects_all"]
set action_name [im_category_from_id $action_id]
if {"" == $action_name} { set action_name "Save" }
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]
if {!$edit_projects_all_p} { ad_return_complaint 1 $action_forbidden_msg }

switch $action_id {
	"" {
	    # Save
	    foreach pid [array names project_priority_id] {
		im_project_permissions $user_id $pid view read write admin
		if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
		set priority $project_priority_id($pid)
		db_dml update_project "
			update im_projects set
				project_priority_id = :priority
			where project_id = :pid
	        "
	    }
	}
	default {
	    # Check if we've got a custom action to perform
	    set redirect_base_url [db_string redir "select aux_string1 from im_categories where category_id = :action_id" -default ""]
	    if {"" != [string trim $redirect_base_url]} {
		# Redirect for custom action
		set redirect_url [export_vars -base $redirect_base_url {action_id}]
		foreach pid $project_id { append redirect_url "&project_id=$pid"}
		ad_returnredirect $redirect_url
	    } else {
		ad_return_complaint 1 "Unknown project action: $action_id='[im_category_from_id $action_id]'"
	    }
	}
    }


ad_returnredirect $return_url
