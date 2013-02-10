# /packages/intranet-timesheet2-workflow/www/conf-objects/delete.tcl
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-notes/index page or 
    the notes-list-compomponent and perform the selected 
    action an all selected notes.
    @author frank.bergmann@project-open.com
} {
    conf_id:multiple,optional
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

if {![info exists conf_id] || 0 == [llength $conf_id]} { 
    aad_returnredirect $return_url 
}

foreach cid $conf_id {
    set project_id [db_string pid "select conf_project_id from im_timesheet_conf_objects where conf_id = :cid" -default ""]
    im_project_permissions $user_id $project_id view_p read_p write_p admin_p
    if {!$admin_p} {
	ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-timesheet2-workflow.Insufficient_permission "Insufficient permissions"]</b>"
	ad_script_abort
    } else {
	db_string del_conf_object "select im_timesheet_conf_object__delete(:cid) from dual" -default ""
    }
}


ad_returnredirect $return_url

