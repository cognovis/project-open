# /packages/intranet-expenses/www/bundle-del.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Delete expense bundle 
    @param project_id project on expense is going to create
    @author avila@digiteix.com
} {
    bundle_id:multiple
    project_id:integer,optional
    { return_url "/intranet-expenses/"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

foreach id $bundle_id {

    # delete bundle as a cost
    # 
    db_transaction {
	db_dml reset_expense_items "
		update im_expenses set 
		       	bundle_id = null 
		where bundle_id = :id
	"
	db_dml del_tokens "
	        delete	from wf_tokens wft
		where	wft.case_id in (
			select	wfc.case_id
			from 	wf_cases wfc
		      	where	wfc.object_id = :id
		)
	"
	db_dml del_workflows "
	        delete from wf_cases wfc
		where wfc.object_id = :id
	"

	db_string del_expense_bundle {}
    }
}

template::forward $return_url