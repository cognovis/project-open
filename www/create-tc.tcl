# /packages/intranet-expenses/www/create-tc.tcl
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
    create trabel cost (invoice) from expenses

    @param project_id
           project on expense is going to create

    @author avila@digiteix.com
} {

    { cost_type_id:integer "[im_cost_type_invoice]" }
    project_id:integer
    { return_url "/intranet-expenses/"}
    expense_id:multiple
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set amount_before_vat 0
set total_amount 0
set expenses_list [list]

foreach id $expense_id {
    db_1row "get expense info" "select
           amount, 
           currency, 
           vat, 
	   external_company_name,
	receipt_reference,
	invoice_id,
	billable_p,
	reimbursable
    from im_costs, im_expenses e
    where cost_id = :id 
	and cost_id = expense_id
        and invoice_id is null"

    set amount_before_vat [expr $amount_before_vat + $amount]
    set total_amount [expr $total_amount + [expr $amount * [expr 1 + [expr $vat / 100.0]]]]
    lappend expenses_list $id
}

set invoice_vat [expr [expr [expr $total_amount - $amount_before_vat] / $amount_before_vat] * 100.0]

# --------------------------------------
# create invoice for these expenses
# --------------------------------------
set cost_name "__expense_invoice"
set customer_id "[im_company_internal]"
set provider_id $user_id
set cost_status_id [im_cost_status_created]
set cost_type_id [im_cost_type_expense_report]
set template_id ""
set payment_days "30"
set tax "0"
set description ""
set note ""

# create invoice as a cost
# Let's create the new expense
db_transaction {
    set invoice_id [db_exec_plsql create_expense_invoice ""] 
    set expenses_list_sql [join $expenses_list ","]
    db_dml "set invoice_id to expense_items" "
update 
     im_expenses 
     set 
         invoice_id = :invoice_id 
where expense_id in ($expenses_list_sql)"
}



template::forward "$return_url?[export_vars -url project_id]"