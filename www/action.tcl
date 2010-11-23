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
    item_value:array,optional
    item_note:array,optional
    return_url
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


ad_return_complaint 1 [array get item_value]


set note_list [array names note]
if {0 == [llength $note_list]} { ad_returnredirect $return_url }

switch $action {
    del_notes {
	foreach note_id $note_list {
	    db_string del_notes "select im_note__delete(:note_id)"
	}
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url

