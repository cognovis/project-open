# /packages/intranet-expenses/www/bundle-create.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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
    { user_id_from_search "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# No ExpenseItems specified? => Go back
if {![info exists expense_id]} { ad_returnredirect $return_url }

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]
set add_expense_bundles_p [im_permission $current_user_id "add_expense_bundle"]

# Check permissions to log hours for other users
# We use the hour logging permissions also for expenses...
set add_hours_all_p [im_permission $current_user_id "add_hours_all"]
if {"" == $user_id_from_search || !$add_hours_all_p} { set user_id_from_search $current_user_id }


# if {!$add_expense_bundles_p} {
#    ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.No_perms "You don't have permission to see this page:"]
#    ad_script_abort
# }

# Add a "0" expense to avoid syntax error if the list was empty.
lappend epense_id 0

# ---------------------------------------------------------------
# Sum up the expenses
# ---------------------------------------------------------------

array set hash [im_expense_bundle_item_sum -user_id_from_search $user_id_from_search -expense_ids $expense_id]

set common_project_id $hash(common_project_id)
set common_project_nr $hash(common_project_nr)
set common_project_name $hash(common_project_name)
set total_amount_rounded $hash(total_amount_rounded)
set cost_name $hash(cost_name)
set amount_before_vat $hash(amount_before_vat)
set total_amount $hash(total_amount)
set bundle_vat $hash(bundle_vat)
set customer_id $hash(customer_id)
set provider_id $hash(provider_id)
set cost_type_id $hash(cost_type_id)
set cost_status_id $hash(cost_status_id)
set template_id $hash(template_id)
set payment_days $hash(payment_days)
set tax $hash(tax)
set description $hash(description)
set note $hash(note)
set default_currency $hash(default_currency)

# ---------------------------------------------------------------
# Create the bundle
# ---------------------------------------------------------------

# Status: normal users can only create "requested" bundles
if {$add_expense_bundles_p} { set cost_status_id [im_cost_status_created] }

# Check that we don't try to update any items that are already
# part of a bunlde
set bundled_items_p [db_string bundled_items "
	select	count(*)
	from	im_expenses
	where	expense_id in ([join $expense_id ", "])
		and bundle_id is not null

"]
if {$bundled_items_p} {
   ad_return_complaint 1 "You are trying to re-bundle already bundled items"
   ad_script_abort
}


# Create Expense Bundle, basically as a cost item with type "im_expense_bundle".
db_transaction {
    set expense_bundle_id [db_exec_plsql create_expense_bundle ""] 

    db_dml update_expense_items "
	update im_expenses 
	set bundle_id = :expense_bundle_id 
	where expense_id in ([join $expense_id ", "])
	      and bundle_id is null
    "
}

# Audit the action
im_audit -object_type im_expense_bundle -action after_create -object_id $expense_bundle_id -status_id cost_status_id -type_id $cost_type_id


# ---------------------------------------------------------------
# Spawn a workflow for confirmation by the superior
# Only spawn the WF if the user DOESN't have the right to 
# create expense bundles anyway...
# ---------------------------------------------------------------

set wf_installed_p 0
catch {set wf_installed_p [im_expenses_workflow_installed_p] }

if {$wf_installed_p && $add_expense_bundles_p} {
    im_expenses_workflow_spawn_workflow \
	-expense_bundle_id $expense_bundle_id \
	-user_id $user_id_from_search

    set page_title [lang::message::lookup "" intranet-expenses.Workflow_Created "Workflow Created"]
    set context_bar [im_context_bar $page_title]
    set message [lang::message::lookup "" intranet-expenses.Workflow_Created_msg "
    	A new workflow has been created for your request.
    "]
    ad_return_template
}

# ---------------------------------------------------------------
# Where to go now?
# ---------------------------------------------------------------

ad_returnredirect [export_vars -base "bundle-new" {{bundle_id $expense_bundle_id} {form_mode "edit"}}]
