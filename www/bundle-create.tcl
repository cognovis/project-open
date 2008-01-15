# /packages/intranet-expenses/www/bundle-create.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Create expense bundle from variousl expenses
    @param project_id project on expense is going to create
    @author avila@digiteix.com
} {
    return_url
    expense_id:integer,multiple,optional
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# No ExpenseItems specified? => Go back
if {![info exists expense_id]} { ad_returnredirect $return_url }

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]
set add_expense_bundles_p [im_permission $current_user_id "add_expense_bundle"]
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

# if {!$add_expense_bundles_p} {
#    ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.No_perms "You don't have permission to see this page:"]
#    ad_script_abort
# }

# Add a "0" expense to avoid syntax error if the list was empty.
lappend epense_id 0

set expense_ids $expense_id


# ---------------------------------------------------------------
# Sum up the expenses
# ---------------------------------------------------------------

set amount_before_vat 0
set total_amount 0
set expenses_list [list]
set common_project_id 0
set common_customer_id 0
set common_provider_id 0

set expense_sql "
	select	c.*,
		e.*
	from	im_costs c, 
		im_expenses e
	where	c.cost_id in ([join $expense_ids ", "])
		and c.cost_id = e.expense_id
        	and e.bundle_id is null
"
db_foreach expenses $expense_sql {

    set amount_before_vat [expr $amount_before_vat + $amount]
    set total_amount [expr $total_amount + [expr $amount * [expr 1 + [expr $vat / 100.0]]]]

    if {0 == $common_project_id & $project_id != ""} { set common_project_id $project_id }
    if {0 != $common_project_id & $project_id != "" & $common_project_id != $project_id} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Muliple_projects "
		You can't included expense items from several project in one expense bundle.
	"]
	ad_script_abort
    }

    if {0 == $common_customer_id & $customer_id != ""} { set common_customer_id $customer_id }
    if {0 != $common_customer_id & $customer_id != "" & $common_customer_id != $customer_id} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Muliple_customers "
		You can't included expense items from several 'customer' in one expense bundle.
	"]
	ad_script_abort
    }

    if {0 == $common_provider_id & $provider_id != ""} { set common_provider_id $provider_id }
    if {0 != $common_provider_id & $provider_id != "" & $common_provider_id != $provider_id} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Muliple_projects "
		You can't included expense items from several 'providers' in one expense bundle.
	"]
	ad_script_abort
    }
}

set bundle_vat 0
catch {
     set bundle_vat [expr [expr [expr $total_amount - $amount_before_vat] / $amount_before_vat] * 100.0]
}

if {0 == $common_project_id} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.No_project_specified "No project specified"]
    ad_abort_script
}

# --------------------------------------
# create bundle for these expenses
# --------------------------------------

set project_nr [db_string project_nr "select project_nr from im_projects where project_id = :common_project_id" -default ""]
set project_name [db_string project_nr "select project_name from im_projects where project_id = :common_project_id" -default ""]
set cost_name [lang::message::lookup "" intranet-expenses.Expense_Bundle "Expense Bundle"]
set cost_name "$cost_name - $default_currency $total_amount in $project_name"

set customer_id "[im_company_internal]"
set provider_id $current_user_id

# Status: normal users can only create "requested" bundles
set cost_status_id [im_cost_status_requested]
if {$add_expense_bundles_p} { set cost_status_id [im_cost_status_created] }

set cost_type_id [im_cost_type_expense_bundle]
set template_id ""
set payment_days "30"
set tax "0"
set description ""
set note ""

# Create Expense Bundle, basicly as a cost item with type "im_expense_bundle".
db_transaction {
    set expense_bundle_id [db_exec_plsql create_expense_bundle ""] 
    set expenses_list_sql [join $expenses_list ","]

    db_dml update_expense_items "
	update im_expenses 
	set bundle_id = :expense_bundle_id 
	where expense_id in ([join $expense_ids ", "])
    "
}


# ---------------------------------------------------------------
# Spawn a workflow for confirmation by the superior
# Only spawn the WF if the user DOESN't have the right to 
# create expense bundles anyway...
# ---------------------------------------------------------------

set wf_installed_p 0
catch {set wf_installed_p [im_expenses_workflow_installed_p] }
if {$wf_installed_p && !$add_expense_bundles_p} {

    im_expenses_workflow_spawn_workflow \
	-expense_bundle_id $expense_bundle_id \
	-user_id $current_user_id

    set page_title [lang::message::lookup "" intranet-expenses.Workflow_Created "Workflow Created"]
    set message [lang::message::lookup "" intranet-expenses.Workflow_Created_msg "
    	A new workflow has been created for your request.
    "]
    ad_return_template
    
}


# ---------------------------------------------------------------
# Where to go now?
# ---------------------------------------------------------------

ad_returnredirect $return_url
