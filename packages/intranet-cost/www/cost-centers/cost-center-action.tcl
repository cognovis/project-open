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

if {[catch {

    db_transaction {
	db_dml null_cc "update im_employees set department_id = null where department_id in ([join $cost_center_list ", "])"
	db_dml null_cc "update im_costs set cost_center_id = null where cost_center_id in ([join $cost_center_list ", "])"
	db_dml del_cost_centers "delete from im_cost_centers where cost_center_id in ([join $cost_center_list ", "])"
	db_dml del_cc_objects "delete from acs_objects where object_id in ([join $cost_center_list ", "])"
    }

} err_msg]} {
    ad_return_complaint 1 "<li>Error deleting cost centers. Perhaps you try to delete a cost center that still has sub cost centers. Here is the error:<br><pre>$err_msg</pre>"
    return
}

ad_returnredirect $return_url
