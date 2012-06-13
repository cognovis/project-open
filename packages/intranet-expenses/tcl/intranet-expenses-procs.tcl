# /packages/intranet-expenses/tcl/intranet-expenses-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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
# Expenses Permissions
# ----------------------------------------------------------------------


ad_proc -public im_expense_bundle_permissions {user_id bundle_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $bundle_id.<br>
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    # Just call general cost permissions
    im_cost_permissions $user_id $bundle_id view read write admin
}

# ----------------------------------------------------------------------
# Sum up multiple Expense Items for a single Bundle
# ----------------------------------------------------------------------


ad_proc im_expense_bundle_item_sum {
    -expense_ids:required
    {-user_id_from_search "" }
} {
    Sums up a list of expense items.
    Returns a hash array with the resulting amount sum etc.
} {
    set current_user_id [ad_get_user_id]
    set add_hours_all_p [im_permission $current_user_id "add_hours_all"]
    if {"" == $user_id_from_search || !$add_hours_all_p} { set user_id_from_search $current_user_id }

    set amount_before_vat 0
    set total_amount 0
    set common_project_id 0
    set common_customer_id 0
    set common_provider_id 0
    set common_currrency ""
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

    set expense_sql "
	select	c.*,
		e.*,
		im_exchange_rate(c.effective_date::date, c.currency, :default_currency) 
			* c.amount as amount_converted
	from	im_costs c, 
		im_expenses e
	where	c.cost_id in ([join $expense_ids ", "])
		and c.cost_id = e.expense_id
    "
    db_foreach expenses $expense_sql {

	# amount_converted can be NULL if exchange rates are not defined
	if {"" == $amount_converted} { set amount_converted 0 }

	set amount_before_vat [expr $amount_before_vat + $amount_converted]
	set total_amount [expr $total_amount + [expr $amount_converted * [expr 1 + [expr $vat / 100.0]]]]

	if {0 == $common_project_id & $project_id != ""} { set common_project_id $project_id }
	if {0 != $common_project_id & $project_id != "" & $common_project_id != $project_id} {
	    ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Muliple_projects "
		You can't include expense items from several project in one expense bundle:<br>
		Name of the violating item: '$external_company_name (ID=#$cost_id)'
	    "]
	    ad_script_abort
	}

	if {0 == $common_customer_id & $customer_id != ""} { set common_customer_id $customer_id }
	if {0 != $common_customer_id & $customer_id != "" & $common_customer_id != $customer_id} {
	    ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Muliple_customers "
		You can't include expense items from several 'customer' in one expense bundle.
	    "]
	    ad_script_abort
	}

	if {0 == $common_provider_id & $provider_id != ""} { set common_provider_id $provider_id }
	if {0 != $common_provider_id & $provider_id != "" & $common_provider_id != $provider_id} {
	    ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Muliple_projects "
		You can't include expense items from several 'providers' (people reporting the expense) 
		in one expense bundle.
	    "]
	    ad_script_abort
	}
    }

    set bundle_vat 0
    catch {
	set bundle_vat [expr [expr [expr $total_amount - $amount_before_vat] / $amount_before_vat] * 100.0]
    }

#    if {0 == $common_project_id} {
#	ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.No_project_specified "No (common) project specified"]
#	ad_abort_script
#    }

     if {0 == $common_project_id} { set common_project_id "" }

    # --------------------------------------
    # create bundle for these expenses
    # --------------------------------------
    
    set common_project_nr [db_string project_nr "select project_nr from im_projects where project_id = :common_project_id" -default ""]
    set common_project_name [db_string project_nr "select project_name from im_projects where project_id = :common_project_id" -default ""]
    
    set total_amount_rounded [expr round($total_amount*100) / 100]
    set cost_name [lang::message::lookup "" intranet-expenses.Expense_Bundle "Expense Bundle"]
    set cost_name "$cost_name - $default_currency $total_amount_rounded in $common_project_name"
    
    # --------------------------------------
    # Package variables in a hash for return
    # --------------------------------------

    set hash(common_project_id) $common_project_id
    set hash(common_project_nr) $common_project_nr
    set hash(common_project_name) $common_project_name
    set hash(total_amount_rounded) $total_amount_rounded
    set hash(cost_name) $cost_name
    set hash(amount_before_vat) $amount_before_vat
    set hash(total_amount) $total_amount
    set hash(bundle_vat) $bundle_vat
    set hash(customer_id) [im_company_internal]
    set hash(provider_id) $user_id_from_search
    set hash(cost_type_id) [im_cost_type_expense_bundle]
    set hash(cost_status_id) [im_cost_status_requested]
    set hash(template_id) ""
    set hash(payment_days) 0
    set hash(tax) 0
    set hash(description) ""
    set hash(note) ""
    set hash(default_currency) $default_currency

    return [array get hash]
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

