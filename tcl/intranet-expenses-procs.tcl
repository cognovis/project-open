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


ad_proc im_expense_bundle_new_page_wf_perm_modify_included_expenses {
    -bundle_id:required
} {
    Should we show the "Modify Included Expenses" link in the
    ExpenseBundleNewPage?
    The link is visible only for the Owner of the bundle
    and the Admin.

    Also, the included expenses can't be change anymore once the 
    Expense Bundle has been approved.
} {
    set current_user_id [ad_get_user_id]
    set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set owner_id [util_memoize "db_string owner \"select creation_user from acs_objects where object_id = $bundle_id\" -default 0"]

    # The standard case: Only the owner should edit his own bundles.
    set perm_p 0
    if {$owner_id == $current_user_id} { set perm_p 1 }

    # The owner can edit the bundle only in status requested and rejected
    set already_approved_p 1
    set bundle_status_id [db_string start "select cost_status_id from im_costs where cost_id = :bundle_id" -default 0]
    if {$bundle_status_id == [im_cost_status_requested]} { set already_approved_p 0}
    if {$bundle_status_id == [im_cost_status_rejected]} { set already_approved_p 0}
    if {$already_approved_p} { set perm_p 0 }

    # Admins & HR can do everything anytime.
    if {[im_user_is_hr_p $current_user_id]} { set perm_p 1 }
    if {$current_user_is_admin_p} { set perm_p 1 }

    return $perm_p
}



ad_proc im_expense_bundle_new_page_wf_perm_edit_button {
    -bundle_id:required
} {
    Should we show the "Edit" button in the ExpenseBundleNewPage?
} {
    return 0
}

ad_proc im_expense_bundle_new_page_wf_perm_delete_button {
    -bundle_id:required
} {
    Should we show the "Delete" button in the ExpenseBundleNewPage?
    Only the owner himself is allowed to delete a bundle, while it
    is in status "Requrested" or "Rejected".
} {
    im_expense_bundle_new_page_wf_perm_modify_included_expenses -bundle_id $bundle_id
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
