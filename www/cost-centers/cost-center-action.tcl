# /packages/intranet-cost/www/cost-centers/cost-center-action.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Delete selected cost_centers

    @param return_url the url to return to
    @param cost_center_id The list of cost_centers to delete

    @author frank.bergmann@project-open.com
} {
    cost_center_id:array,optional
    {return_url "/intranet-cost/cost-centers/index"}
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set cost_center_list [array names cost_center_id]
ns_log Notice "cost_center-action: cost_center_list=$cost_center_list"

if {0 == [llength $cost_center_list]} {
    ad_returnredirect $return_url
}

# Convert the list of selected cost_centers into a
# "cost_center_id in (1,2,3,4...)" clause
#
set cost_center_in_clause "and cost_center_id in ("
append cost_center_in_clause [join $cost_center_list ", "]
append cost_center_in_clause ")\n"
ns_log Notice "cost_center-action: cost_center_in_clause=$cost_center_in_clause"


# Delete

set sql "
	delete from im_cost_centers
	where 1=1
		$cost_center_in_clause"
if {[catch {
    db_dml del_cost_centers $sql
} err_msg]} {
    ad_return_complaint 1 "<li>Error deleting cost centers. Perhaps you try to delete a cost center that still has sub cost centers. Here is the error:<br><pre>$err_msg</pre>"
    return
}

ad_returnredirect $return_url
