# /packages/intranet-freelance-rfqs/www/del-rfq-skills.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Add / edit freelance-rfqs in project
    @param project_id
} {
    rfq_id:integer
    object_skill_map_ids:multiple
    return_url
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "add_freelance_rfqs"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------


foreach map_id $object_skill_map_ids {

    if {"" == $map_id} { continue }

    db_dml del_map "
	delete from im_object_freelance_skill_map
	where	object_skill_map_id = :map_id
    "

}

ad_returnredirect $return_url
