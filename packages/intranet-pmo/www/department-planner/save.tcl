# /packages/intranet-pmo/www/department-planner/save.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#

ad_page_contract {
    Save the priorities of the projects
    @param return_url the url to return to
    @author frank.bergmann@project-open.com
    @author malte.sussdorff@cognovis.de
} {
    project_priority_st_id:array
    project_priority_op_id:array
    { return_url "/intranet-pmo/department-planner/index" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_name [im_name_from_user_id [ad_get_user_id]]
set edit_projects_all_p [im_permission $user_id "edit_projects_all"]
set action_name "Save"
set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to execute the action '%action_name%' on this ticket."]
if {!$edit_projects_all_p} { ad_return_complaint 1 $action_forbidden_msg }

set project_ids [list]
foreach pid [array names project_priority_op_id] {
    if {$project_priority_op_id($pid) ne ""} {
	lappend project_ids $pid
    }
}

foreach pid [array name project_priority_st_id] {
    if {$project_priority_st_id($pid) ne ""} {
	if {[lsearch $project_ids $pid] <0} {
	    lappend project_ids $pid
	}
    }
}

foreach project_id $project_ids {
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }

    if {[exists_and_not_null project_priority_op_id($project_id)]} {
	set priority_op $project_priority_op_id($project_id)
	set priority [db_string priority "select aux_int1 from im_categories where category_id = :priority_op" -default 0]
    } else {
	set priority_op ""
	set priority 0
    }

    if {[exists_and_not_null project_priority_st_id($project_id)]} {
	set priority_st $project_priority_st_id($project_id)
	incr priority  [db_string priority "select aux_int1 from im_categories where category_id = :priority_st" -default 0]
    } else {
	set priority_st ""
    }

    if {$priority eq 0} {
	set priority ""
    }

    ds_comment "updated $project_id :: $priority_op :: $priority_st :: $priority"
    db_dml update_project "
			update im_projects set
				project_priority_op_id = :priority_op,
				project_priority_st_id = :priority_st,
				project_priority = :priority
			where project_id = :project_id
    "

}

ad_returnredirect $return_url
