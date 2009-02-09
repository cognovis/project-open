# /packages/intranet-freelance-rfqs/www/del-rfq.tcl
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    rfq_id:multiple,integer
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

db_dml close_rfqs "
	update	im_freelance_rfqs
	set	rfq_status_id = [im_freelance_rfq_status_closed]
	where	rfq_id in ([join [lappend rfq_id 0] ","])
"

ad_returnredirect $return_url

