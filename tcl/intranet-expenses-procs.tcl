# /packages/intranet-expenses/tcl/intranet-expenses-procs.tcl
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures to implement travel expenses
    @author frank.bergmann@project-open.com
}



ad_proc -public im_expense_payment_type_cash {} { return 4100 }
ad_proc -public im_expense_payment_type_visa1 {} { return 4101 }
ad_proc -public im_expense_payment_type_paypal {} { return 4102 }

# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_expenses_id {} {
    Returns the package id of the intranet-expenses module
} {
    return [util_memoize "im_package_expenses_id_helper"]
}

ad_proc -private im_package_expenses_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-expenses'
    } -default 0]
}


# ----------------------------------------------------------------------
# Workflow Permissions
# ----------------------------------------------------------------------

ad_proc im_expense_bundle_new_page_wf_perm_table { } {
    Returns a hash array representing (role x status) -> (v r d w a),
    controlling the read and write permissions on expenses,
    depending on the users's role and the WF status.
} {
    set req [im_cost_status_requested]
    set rej [im_cost_status_rejected]
    set act [im_cost_status_created]
    set del [im_cost_status_deleted]

    set perm_hash(owner-$rej) {v r d w}
    set perm_hash(owner-$req) {v r d w}
    set perm_hash(owner-$act) {v r}
    set perm_hash(owner-$del) {v r}

    set perm_hash(assignee-$rej) {v r}
    set perm_hash(assignee-$req) {v r}
    set perm_hash(assignee-$act) {v r}
    set perm_hash(assignee-$del) {v r}

    set perm_hash(hr-$rej) {v r d w a}
    set perm_hash(hr-$req) {v r d w a}
    set perm_hash(hr-$act) {v r d w a}
    set perm_hash(hr-$del) {v r d w a}

    set perm_hash(accounting-$rej) {v r}
    set perm_hash(accounting-$req) {v r}
    set perm_hash(accounting-$act) {v r}
    set perm_hash(accounting-$del) {v r}

    return [array get perm_hash]
}


ad_proc im_expense_bundle_new_page_wf_perm_modify_included_expenses {
    -bundle_id:required
} {
    Should we show the "Modify Included Expenses" link in the ExpenseBundleNewPage?
    The link is visible only for users with "w" permission on the bundle

    Also, the included expenses can't be change anymore once the 
    Expense Bundle has been approved.
} {
    set perm_table [im_expense_bundle_new_page_wf_perm_table]
    set perm_set [im_workflow_object_permissions -object_id $bundle_id -perm_table $perm_table]
    return [expr [lsearch $perm_set "w"] > -1]
}
ad_proc im_expense_bundle_new_page_wf_perm_edit_button {
    -bundle_id:required
} {
    Should we show the "Edit" button in the ExpenseBundleNewPage?
} {
    set perm_table [im_expense_bundle_new_page_wf_perm_table]
    set perm_set [im_workflow_object_permissions -object_id $bundle_id -perm_table $perm_table]
    return [expr [lsearch $perm_set "a"] > -1]
}

ad_proc im_expense_bundle_new_page_wf_perm_delete_button {
    -bundle_id:required
} {
    Should we show the "Delete" button in the ExpenseBundleNewPage?
    Only the owner himself is allowed to delete a bundle, while it
    is in status "Requrested" or "Rejected".
} {
    set perm_table [im_expense_bundle_new_page_wf_perm_table]
    set perm_set [im_workflow_object_permissions -object_id $bundle_id -perm_table $perm_table]
    return [expr [lsearch $perm_set "d"] > -1]
}



# ----------------------------------------------------------------------
# Automatically calculate VAT
# ----------------------------------------------------------------------

ad_proc im_expense_calculate_vat_from_expense_type {
    -expense_id:required
} {
    Calculates the VAT % as a function of the "aux_string" field
    in im_categories for 'Intranet Expense Type'.
} {
    set vat [db_string vat "
	select	c.aux_string1 
	from	im_categories c,
		im_expenses e
	where	e.expense_id = :expense_id and
		expense_type_id = c.category_id
    " -default ""]
    if {"" == $vat} { set vat 0.0 }

    return $vat
}

