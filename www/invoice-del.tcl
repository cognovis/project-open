# /packages/intranet-expenses/www/invoice-del.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Delete expense invoice 
    @param project_id project on expense is going to create
    @author avila@digiteix.com
} {
    project_id:integer
    { return_url "/intranet-expenses/"}
    invoice_id:multiple
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

foreach id $invoice_id {

    # delete invoice as a cost
    # 
    db_transaction {
	db_dml reset_expense_items "
		update im_expenses set 
		       	invoice_id = null 
		where invoice_id = :id
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

	db_string del_expense_invoice {}
    }
}

template::forward "$return_url?[export_vars -url project_id]"