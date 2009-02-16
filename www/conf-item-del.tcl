# /packages/intranet-confdb/www/conf_items-del.tcl
#
# Copyright (c) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Delete conf_items

    @author frank.bergmann@project-open.com
} {
    conf_item_id:multiple,optional
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]
set del_p [im_permission $current_user_id "add_conf_items"]
if {!$del_p} { 
    ad_return_complaint 1 "Not sufficient permissions" 
    ad_script_abort
}

if {[info exists conf_item_id]} {
	foreach id $conf_item_id {
	    im_conf_item_delete -conf_item_id $id
	}
}

template::forward $return_url
