# /packages/intranet-costs/www/costs/cost-action.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Takes commands from the /intranet-cost/index
    page and deletes costs where marked

    @param return_url the url to return to
    @param group_id group id
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet-costs/list" }
    del_cost:multiple,optional
    cost_status:array,optional
    object_type:array,optional
    {submit_del ""}
    {submit_save ""}
}

set user_id [ad_maybe_redirect_for_registration]

if {![im_permission $user_id add_costs]} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

ns_log Notice "cost-action: submit_del=$submit_del, submit_save=$submit_save"

if {"" != $submit_save} {
    # Save the stati for the costs on this list
    foreach cost_id [array names cost_status] {
	set cost_status_id $cost_status($cost_id)
	ns_log Notice "set cost_status($cost_id) = $cost_status_id"
	
	db_dml update_cost_status "update im_costs set cost_status_id=:cost_status_id where cost_id=:cost_id"
    }
    
    ad_returnredirect $return_url
    return
}


if {"" != $submit_del} {
    # Maybe the list of costs was empty...
    if {![info exists del_cost]} { 
	ad_returnredirect $return_url
	return
    }
    
    foreach cost_id $del_cost {
	set otype $object_type($cost_id)
	# ToDo: Security
	
	if [catch {
	    im_exec_dml del_cost_item "${otype}__delete(:cost_id)"
	} errmsg] {
	    ad_return_complaint 1 "<li>Error deleting cost item #$cost_id of type '$otype':<br>
            <pre>$errmsg</pre>"
	    return
	}
	
	lappend in_clause_list $cost_id
    }
    set cost_where_list "([join $in_clause_list ","])"
    
    ad_returnredirect $return_url
    return
}

ad_return_complaint 1 "<li>No action selected:<br>
This page expects 'submit_del' or 'submit_save' as input parameters.<br>
Please update your system.<br>
If this doesn't help please inform <A href='mailto:support@project-open.com'>support@project-open.com</a>."


