# /packages/intranet-sysconfig/www/admin-guide-action.tcl
#
# Copyright (c) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Disables or restores admin guide actions
    @author frank.bergmann@project-open.com
} {
    { action1 ""}
    { action2 ""}
    { action_submit1 ""}
    { action_submit2 ""}
    { item:multiple ""}
    return_url
}

# ---------------------------------------------------------------
# Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set action ""
if {"" != $action_submit1} { set action $action1 }
if {"" != $action_submit2} { set action $action2 }

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

switch $action {
    reset {
	# Reset the parameter to an empty value
	parameter::set_from_package_key -package_key "intranet-sysconfig" -parameter "AdminGuideItemsDone" -value ""
    }
    mark_as_done {
	# Get the old list of values
	set items_done [parameter::get_from_package_key -package_key "intranet-sysconfig" -parameter "AdminGuideItemsDone" -default ""]
	
	# append and remove duplicates
	foreach i $item {
	    lappend items_done $i
	}
	
	set items_done [lsort -unique $items_done]
	
	# Save the updated list of values
	parameter::set_from_package_key -package_key "intranet-sysconfig" -parameter "AdminGuideItemsDone" -value $items_done
    }

    default {
	ad_return_complaint 1 "Unknown action '$action'"
    }
}

ad_returnredirect $return_url

