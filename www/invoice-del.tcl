# /packages/intranet-expenses/www/invoice-del.tcl
#
# Copyright (C) 2003-2004 Project/Open
# 060427 avila@digiteix.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    delete trabel cost (invoice) from expenses

    @param project_id
           project on expense is going to create

    @author avila@digiteix.com
} {

    project_id:integer
    { return_url "/intranet-expenses/"}
    invoice_id:multiple
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

foreach id $invoice_id {

    # delete invoice as a cost
    # 
    db_transaction {
	db_dml "set invoice_id to expense_items to null" "
update 
     im_expenses 
     set 
         invoice_id = null 
where invoice_id =:id"
	db_string del_expense_invoice {}
    }
}

template::forward "$return_url?[export_vars -url project_id]"