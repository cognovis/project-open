# /packages/intranet-pmo/www/department-planner/save-ajax.tcl
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

    ds_comment "$project_id :: $project_priority_op_id($project_id)"
    if {[exists_and_not_null project_priority_op_id($project_id)]} {
	set priority_op $project_priority_op_id($project_id)
	if {$priority_op eq "Not set"} {
	    set priority_op 0
	}
	set op_cat_id [db_string prio "select category_id from im_categories where aux_int1 = :priority_op and category_type = 'Intranet Department Planner Project Priority'"]
    } else {
	set priority $priority_op 
    }

    if {[exists_and_not_null project_priority_st_id($project_id)]} {
	set priority_st $project_priority_st_id($project_id)
	if {$priority_st eq "Not set"} {
	    set priority_st 0
	}
	set st_cat_id [db_string prio "select category_id from im_categories where aux_int1 = :priority_st and category_type = 'Intranet Department Planner Project Priority'"]
    } else {
	set priority_st ""
    }

    set priority [expr $priority_op + $priority_st]

#    ds_comment "updated $project_id :: $priority_op :: $op_cat_id :: $priority_st :: $st_cat_id :: $priority"
    db_dml update_project "
			update im_projects set
				project_priority_op_id = :op_cat_id,
				project_priority_st_id = :st_cat_id,
				project_priority = :priority
			where project_id = :project_id
    "

}
ds_comment "$return_url"
ad_returnredirect $return_url
