# /packages/intranet-portfolio-management/www/department-planner/save.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Save the priorities of the projects
    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    project_priority_id:integer,array
    { return_url "/intranet-portfolio-management/department-planner/index" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_name [im_name_from_user_id [ad_get_user_id]]
set edit_projects_all_p [im_permission $user_id "edit_projects_all"]
set action_name "Save"
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]
if {!$edit_projects_all_p} { ad_return_complaint 1 $action_forbidden_msg }

foreach pid [array names project_priority_id] {
    im_project_permissions $user_id $pid view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
    set priority $project_priority_id($pid)
    db_dml update_project "
			update im_projects set
				project_priority_id = :priority
			where project_id = :pid
    "
    im_audit -object_id $pid
}

ad_returnredirect $return_url
