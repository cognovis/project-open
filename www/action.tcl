# /packages/intranet-planning/www/action.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-planning/index page or 
    the notes-list-compomponent and perform the selected 
    action an all selected notes.
    @author frank.bergmann@project-open.com
} {
    action
    object_id:integer
    return_url
    item_value:array,float,optional
    item_project_phase_id:array,optional
    item_project_member_id:array,optional
    item_cost_type_id:array,optional
    item_date:array,optional
    item_note:array,optional
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# Check the permissions
# Permissions for all usual projects, companies etc.
set user_id [ad_maybe_redirect_for_registration]
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd
if {!$object_write} { ad_return_complaint 1 "You don't have sufficient permission to perform this action" }


switch $action {
    save {
	# Delete the old values for this object_id
	db_dml del_im_planning_items "delete from im_planning_items where item_object_id = :object_id"

	# Create the new values whenever the value is not "" (null)
	foreach id [array names item_value] {
	    set value $item_value($id)
	    if {"" == $value} { continue }

	    set project_phase_id [im_opt_val item_project_phase_id($id)]
	    set project_member_id [im_opt_val item_project_member_id($id)]
	    set cost_type_id [im_opt_val item_cost_type_id($id)]
	    set date [im_opt_val item_date($id)]
	    set value [im_opt_val item_value($id)]
	    set note [im_opt_val item_note($id)]

	    db_string insert_im_planning_item "select im_planning_item__new(
			-- object standard 6 parameters
			null,
			'im_planning_item',
			now(),
			:user_id,
			'[ns_conn peeraddr]',
			null,

			-- Main parameters
			:object_id,
			null,
			null,

			-- Value parameters
			:value,
			:note,

			-- Dimension parameters
			:project_phase_id,
			:project_member_id,
			:cost_type_id,
			:date
		)
	    "
	}
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url

