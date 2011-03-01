# /packages/intranet-confdb/www/associate-2.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Associate the conf_item_ids in "cid" with one of the specified objects.
    target_object_type specifies the type of object to associate with and
    determines which parameters are used.
    @author frank.bergmann@project-open.com
} {
    { cid ""}
    { target_object_type "" }
    { user_id "" }
    { role_id "" }
    { project_id "" }
    { ticket_id "" }
    { return_url "/intranet-confdb/index" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-confdb.Associate_Conf_Item_With_$target_object_type "Associate Configuration Item With $target_object_type"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set action_forbidden_msg [lang::message::lookup "" intranet-confdb.Action_Forbidden "<b>Unable to execute action</b>:<br>You don't have the permissions to associated this conf item with other objects."]

# Check that the user has write permissions on all select conf_items
foreach c $cid {
    # Check that t is an integer
    im_security_alert_check_integer -location "Confdb: Associate" -value $c

    im_conf_item_permissions $current_user_id $c view read write admin
    if {!$write} { ad_return_complaint 1 $action_forbidden_msg }
}


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

switch $target_object_type {
    user {
	# user_id contains the user to associate with 
	# role_id contains the type of association (member or admin)

	if {"" == $role_id} { ad_return_complaint 1 [lang::message::lookup "" intranet-confdb.No_Role_Specified "No role specified"] }
	foreach c $cid {
	    im_biz_object_add_role $user_id $c $role_id
	}
    }
    ticket {
	foreach c $cid {
	    im_conf_item_new_project_rel \
		-project_id $ticket_id \
		-conf_item_id $c
	}
    }
    project {
	foreach c $cid {
	    im_conf_item_new_project_rel \
		-project_id $project_id \
		-conf_item_id $c
	}
    }
    default {
	ad_return_complaint 1 [lang::message::lookup "" intranet-confdb.Unknown_target_object_type "Unknown object type %target_object_type%"]
    }
}

ad_returnredirect $return_url

