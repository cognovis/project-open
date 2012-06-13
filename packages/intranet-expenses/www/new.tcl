# /packages/intranet-expenses/www/new.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
# 060421 avila@digiteix.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    add / edit expense in project

    @param project_id
           project on expense is going to create

    @author avila@digiteix.com
} {
    { cost_type_id:integer "[im_cost_type_expense_item]" }
    { project_id:integer "" }
    { return_url "/intranet-expenses/"}
    expense_id:integer,optional
    expense_amount:float,optional
    expense_date:optional
    {form_mode "edit"}
    {user_id_from_search "" }
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
if {![im_permission $user_id "add_expenses"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

# Check permissions to log hours for other users
# We use the hour logging permissions also for expenses...
set add_hours_all_p [im_permission $current_user_id "add_hours_all"]
if {"" == $user_id_from_search || !$add_hours_all_p} { set user_id_from_search $current_user_id }

set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "[lang::message::lookup "" intranet-expenses.New_Expense "New Expense Item"] "
if {"" != $user_id_from_search && $current_user_id != $user_id_from_search} {
    set user_name_from_search [im_name_from_user_id $user_id_from_search]
    append page_title [lang::message::lookup "" intranet-expenses.for_user_id_from_search "for '%user_name_from_search%'"]
}
set context_bar [im_context_bar $page_title]

set currency_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]
set percent_format "FM999"
set action_url "/intranet-expenses/new"

# Should we calculate VAT automatically from the expense type?
set auto_vat_p [ad_parameter -package_id [im_package_expenses_id] "CalculateVATPerExpenseTypeP" "" 0]
set auto_vat_function [ad_parameter -package_id [im_package_expenses_id] "CalculateVATPerExpenseTypeFunction" "" "im_expense_calculate_vat_from_expense_type"]

# Check the format of the expense date
if {[info exists expense_date] && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $expense_date]} {
    ad_return_complaint 1 "Expense Date doesn't have the right format.<br>
    Current value: '$expense_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

# Redirect if the type of the object hasn't been defined and
# if there are DynFields specific for subtypes.
if {0 == $cost_type_id && ![info exists expense_id]} {

    set all_same_p [im_dynfield::subtype_have_same_attributes_p -object_type "im_expense"]
    set all_same_p 0
    if {!$all_same_p} {
        ad_returnredirect [export_vars -base "/intranet/biz-object-type-select" {{object_type "im_expense"} {return_url $current_url} {type_id_var "cost_type_id"}}]
    }
}

set write_bundled_expenses [im_permission $user_id "edit_bundled_expense_items"]

# ------------------------------------------------------------------
# Form Options
# ------------------------------------------------------------------

set expense_payment_type_options [db_list_of_lists payment_options "
	select	expense_payment_type,
		expense_payment_type_id
	from	im_expense_payment_type
	order by
		expense_payment_type_id
"]


# Get the list of active projects (both main and subprojects)
# where the current user is a direct member
# ToDo: This could give problems with Tasks. Maybe exclude
# tasks in the future?
#

if {[info exists expense_id]} {
    set project_id [db_string expense_project "select project_id from im_costs where cost_id = :expense_id" -default ""]
}

set project_options [im_project_options \
	-exclude_subprojects_p 0 \
	-project_id $project_id \
	-exclude_status_id [im_project_status_closed] \
	-member_user_id $user_id \
]

set include_empty 0
set expense_currencies [parameter::get_from_package_key -package_key intranet-expenses -parameter "ExpenseCurrencies" -default {}]
set currency_options [im_currency_options -currency_list $expense_currencies $include_empty]

set expense_type_options [db_list_of_lists expense_types "
	select	expense_type,
		expense_type_id
	from im_expense_type
"]

set expense_type_options [db_list_of_lists expense_types "select expense_type, expense_type_id from im_expense_type"]
set expense_type_options [linsert $expense_type_options 0 [list [lang::message::lookup "" "intranet-expenses.--Select--" "-- Please Select --"] 0]]



set expense_payment_type_options [db_list_of_lists expense_payment_type "
	select	expense_payment_type,
		expense_payment_type_id
        from
		im_expense_payment_type
"]
set expense_payment_type_options [linsert $expense_payment_type_options 0 [list [lang::message::lookup "" "intranet-expenses.--Select--" "-- Please Select --"] 0]]




# ------------------------------------------------------------------
# Form defaults
# ------------------------------------------------------------------

# Default variables for "costs" (not really applicable)
set customer_id [im_company_internal]
set provider_id $user_id_from_search
set template_id ""
set payment_days "30"
set cost_status [im_cost_status_created]
set cost_type_id [im_cost_type_expense_item]
set tax "0"

if {![info exists reimbursable]} { set reimbursable 100 }
if {![info exists expense_date]} { set expense_date $today }
if {![info exists billable_p]} { set billable_p "f" }

if {![info exists expense_payment_type_id]} { 
    set expense_payment_type_id [im_expense_payment_type_cash]
}

if {![info exists currency]} { 
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"] 
}




# ---------------------------------------------------------------
# Action Links and their permissions
# ---------------------------------------------------------------

# Don't allow the user to modify an "invoiced" item
set edit_p 0
set delete_p 0

set expense_bundle_id ""
if {[info exists expense_id]} {
    set expense_bundle_id [db_string expense_bundle "select bundle_id from im_expenses where expense_id = :expense_id" -default ""]
}
if {"" != $expense_bundle_id} { 
    set form_mode "display"
    set edit_p 0
    set delete_p 0
}

if {$write_bundled_expenses} {
    set edit_p 1
    # No delete for the financial guys... (?)
    set form_mode "edit"
}

set actions [list]
if {[info exists bundle_id]} {
    if {$edit_p} { lappend actions [list [lang::message::lookup {} intranet-timesheet2.Edit Edit] edit] }
    if {$delete_p} { lappend actions [list [lang::message::lookup {} intranet-timesheet2.Delete Delete] delete] }
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "expense_ae"
set focus "$form_id\.var_name"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -has_edit 1 \
    -actions $actions \
    -mode $form_mode \
    -export {customer_id provider_id template_id payment_days cost_status cost_type_id tax user_id_from_search return_url} \
    -form {
        expense_id:key
        {project_id:text(select),optional
	    {label "[lang::message::lookup {} intranet-expenses.Project Project]" } 
	    {options $project_options}
	}
	{expense_amount:text(text) {label "[_ intranet-expenses.Amount]"} {html {size 10}}}
	{currency:text(select) 
	    {label "[_ intranet-expenses.Currency]"}
	    {options $currency_options} 
	}
    }

if {!$auto_vat_p} {
    ad_form -extend -name $form_id -form {
	{vat:text(text) {label "[_ intranet-expenses.Vat_Included]"} {html {size 6}}}
    }
}

ad_form -extend -name $form_id -form {
	{expense_date:text(text) {label "[_ intranet-expenses.Expense_Date]"} {html {size 10}}}
	{external_company_name:text(text) {label "[_ intranet-expenses.External_company_name]"} {html {size 40}}}
	{external_company_vat_number:text(text),optional {label "[lang::message::lookup {} intranet-expenses.External_Company_VatNr {External Company Vat Nr.}]"} {html {size 20}}}
	{receipt_reference:text(text),optional {label "[_ intranet-expenses.Receipt_reference]"} {html {size 40}}}
	{expense_type_id:text(select) 
	    {label "[_ intranet-expenses.Expense_Type]"}
	    {options $expense_type_options} 
	}
	{cost_center_id:text(hidden),optional}
        {billable_p:text(radio) {label "[_ intranet-expenses.Billable_p]"} {options {{[_ intranet-core.Yes] t} {[_ intranet-core.No] f}}} }
	{reimbursable:text(text) {label "[_ intranet-expenses.reimbursable]"} { html {size 10}}}
	{expense_payment_type_id:text(select) 
	    {label "[_ intranet-expenses.Expense_Payment_Type]"}
	    {options $expense_payment_type_options} 
	}
        {note:text(textarea),optional {label "[lang::message::lookup {} intranet-expenses.Note Note]"} {html {cols 40}}}
    }

# Add DynFields
set my_expense_id 0
if {[info exists expense_id]} { set my_expense_id $expense_id }
set field_cnt [im_dynfield::append_attributes_to_form \
    -object_subtype_id $cost_type_id \
    -object_type "im_expense" \
    -form_id $form_id \
    -object_id $my_expense_id \
    -form_display_mode $form_mode \
]



# Don't allow negative expense_amounts
if {[info exists expense_amount] && $expense_amount < 0} {
    template::element::set_error $form_id expense_amount [lang::message::lookup "" intranet-expenses.Negative_amount_not_allowed "Negative amounts are not allowed." ]
}

#    check conditions
#    if {![empty_string_p $vat]} {
#        if {0>$vat || 100<$vat} {
#            template::element::set_error $form_id vat "[_ intranet-expenses.vat_not_valid]"
#            incr n_errors
#        }
#    }

#    if {![empty_string_p $reimbursable]} {
#        if {0>$reimbursable || 100<$reimbursable} {
#            template::element::set_error $form_id reimbursable "[_ intranet-expenses.reimbursable_not_valid]"
#            incr n_errors
#        }
#    }


# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------

ad_form -extend -name $form_id -on_request {

    # Populate elements from local variables

} -select_query {
    
	select	*,
		trim(both from to_char(c.amount * (1 + c.vat / 100), :currency_format)) as expense_amount,
		to_char(c.effective_date, :date_format) as expense_date,
		to_char(c.vat, :percent_format) as vat,
		to_char(e.reimbursable, :percent_format) as reimbursable
	from
		im_costs c,
		im_expenses e
	where
		c.cost_id = e.expense_id
		and c.cost_id = :expense_id

} -new_data {

    if { $expense_type_id == 0 } {
	ad_return_complaint 1 \
	    [lang::message::lookup "" \
	     intranet-expenses.Expense_type_is_required \
	     "You have to selectect an expense type"]
    }

    if {![info exists vat] || "" == $vat} { set vat 0 }
    set amount [expr $expense_amount / [expr 1 + [expr $vat / 100.0]]]
    set expense_name $expense_id

    # Get the user's department as default CC
    set cost_center_id [db_string user_cc "
	select	department_id
	from	im_employees
	where	employee_id = :user_id
    " -default ""]
    
    db_transaction {
	db_exec_plsql create_expense {}
	db_dml update_expense ""
    	db_dml update_cost ""

	im_dynfield::attribute_store \
	    -object_type "im_expense" \
	    -object_id $expense_id \
	    -form_id $form_id
    }

    # Calculate VAT automatically?
    # We need this function at the very end because is access the newly
    # saved absence values.
    if {$auto_vat_p} { 
	set vat [$auto_vat_function -expense_id $expense_id] 
	set amount [expr $expense_amount / [expr 1 + [expr $vat / 100.0]]]
	db_dml update_cost_vat "
		update	im_costs set
			vat = :vat,
			amount = :amount
		where	cost_id = :expense_id
        "
    }

    # Audit the action
    im_audit -object_type im_expense -action after_create -object_id $expense_id

} -edit_data {

    # Security Check: Don't allow to change an "invoiced" expense
    set expense_bundle_id [db_string expense_bundle "select bundle_id from im_expenses where expense_id = :expense_id" -default ""]
    if {"" != $expense_bundle_id && !$write_bundled_expenses} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-expenses.Cant_change_bundled_expense_item "You can't change an already bundled expense item"]
    }

    if {![info exists vat] || "" == $vat} { set vat 0 }
    set amount [expr $expense_amount / [expr 1 + [expr $vat / 100.0]]]
    set expense_name $expense_id

    # Update the cost and invoice items
    db_dml update_expense ""
    db_dml update_cost ""

    im_dynfield::attribute_store \
	    -object_type "im_expense" \
	    -object_id $expense_id \
	    -form_id $form_id


    # Calculate VAT automatically?
    # We need this function at the very end because it accesses the newly
    # saved absence values.
    if {$auto_vat_p} {
	set vat [$auto_vat_function -expense_id $expense_id] 
	set amount [expr $expense_amount / [expr 1 + [expr $vat / 100.0]]]
	db_dml update_cost_vat "
		update	im_costs set
			vat = :vat,
			amount = :amount
		where	cost_id = :expense_id
        "
    }

    # Audit the action
    im_audit -object_type im_expense -action after_update -object_id $expense_id


    # ---------------------------------------------------------------
    # Re-calculate the expense bundle if exists
    # ---------------------------------------------------------------

    if {"" != $expense_bundle_id && 0 != $expense_bundle_id} {
	
	# Get the list of expense items contained in the bundle and recalculate
	set expense_ids [db_list expense_ids "
		select	expense_id
		from	im_expenses
		where	bundle_id = :expense_bundle_id
	"]
	array set hash [im_expense_bundle_item_sum -expense_ids $expense_ids]

	db_dml update_cost_vat "
	update im_costs
	set
		vat		= $hash(bundle_vat),
		tax		= $hash(tax),
		amount		= $hash(amount_before_vat),
		currency	= '$hash(default_currency)'
	where
		cost_id = :expense_bundle_id
         "

	# Audit the action
	im_audit -object_type im_expense_bundle -action after_create -object_id $expense_bundle_id

    }


} -on_submit {
    
    ns_log Notice "new1: on_submit"
    
} -after_submit {

    ad_returnredirect $return_url
    ad_script_abort
}




