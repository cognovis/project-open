# /packages/intranet-expenses/www/expense-ae.tcl
#
# Copyright (C) 2003-2004 Project/Open
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

    { cost_type_id:integer "[im_cost_type_invoice]" }
    project_id:integer
    { return_url "/intranet-expenses/"}
    expense_id:integer,optional
    {form_mode "edit"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
#set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
#if {!$user_is_admin_p} {
#    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
#    return
#}

set action_url "new"
set page_title "[_ intranet-expenses.New_Expense]"
set context [im_context_bar $page_title]
append return_url "index?[export_vars -url project_id]"

if {![exists_and_not_null currency]} {
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------
set form_id "expense_ae"
set focus "$form_id\.var_name"

set include_empty 0
set currency_options [im_currency_options $include_empty]

template::form::create $form_id \
    -cancel_url "$return_url" \
    -mode "$form_mode" \
    -view_buttons [list [list "[_ intranet-core.Back]" back]]

element::create $form_id expense_id \
    -widget hidden \
    -optional
element::create $form_id project_id \
    -widget hidden \
    -value $project_id

element::create $form_id expense_amount \
    -datatype text \
    -widget text \
    -html {size 10} \
    -label "[_ intranet-expenses.Amount]"

element::create $form_id vat_included \
    -datatype text \
    -widget text \
    -html {size 10} \
    -label "[_ intranet-expenses.Vat_Included]"
    
element::create $form_id expense_currency \
    -datatype text \
    -widget select \
    -options $currency_options \
    -label "[_ intranet-expenses.Currency]"

element::create $form_id expense_date \
    -datatype date \
    -widget date \
    -label "[_ intranet-expenses.Expense_Date]"

element::create $form_id external_company_name \
    -datatype text \
    -widget text \
    -label "[_ intranet-expenses.External_company_name]"

element::create $form_id receipt_reference \
    -datatype text \
    -widget text \
    -label "[_ intranet-expenses.Receipt_reference]"

set expense_type_options [db_list_of_lists "get expense type" "select expense_type, expense_type_id from im_expense_type"]
element::create $form_id expense_type_id \
    -datatype integer \
    -widget select \
    -options $expense_type_options \
    -label "[_ intranet-expenses.Expense_Type]"


element::create $form_id billable_p \
    -datatype text \
    -widget radio \
    -options {{yes t} {no f}}\
    -label "[_ intranet-expenses.Billable_p]"

element::create $form_id reimbursable \
    -datatype text \
    -widget text \
    -html {size 10} \
    -label "[_ intranet-expenses.reimbursable]"

set expense_payment_type_options [db_list_of_lists "get expense payment type" "select expense_payment_type, \
        expense_payment_type_id \
        from im_expense_payment_type"]
element::create $form_id expense_payment_type_id \
    -datatype integer \
    -widget select \
    -options $expense_payment_type_options \
    -label "[_ intranet-expenses.Expense_Payment_Type]"

if {[form is_request $form_id]} {
    ns_log notice "is request"
    #form get_values $form_id
    if {[exists_and_not_null expense_id]} {
	# get db values for current expense

    }
    template::element::set_value $form_id expense_currency $currency
}

if {[form is_submission $form_id]} {
    form get_values $form_id
    #check conditions
    set n_errors 0
    if {![empty_string_p $vat_included]} {
        if {0>$vat_included || 100<$vat_included} {
            template::element::set_error $form_id vat_included "[_ intranet-expenses.vat_included_not_valid]"
            incr n_errors
        }
    }

    if {![empty_string_p $reimbursable]} {
        if {0>$reimbursable || 100<$reimbursable} {
            template::element::set_error $form_id reimbursable "[_ intranet-expenses.reimbursable_not_valid]"
            incr n_errors
        }
    }
    if {0 < $n_errors} {
	return
    }
}

if {[form is_valid $form_id]} {
    form get_values $form_id
    # temp vars
    set expense_name "$expense_id"
    set customer_id "[im_company_internal]"
    set cost_nr ""
    set provider_id "$user_id"
    set template_id ""
    set payment_days "30"
    set cost_status [im_cost_status_created]
    set cost_type_id [im_cost_type_expense_item]
    set tax "0"

    set amount [expr $expense_amount / [expr 1 + [expr $vat_included / 100.0]]]

    set expense_date_sql [template::util::date get_property sql_date $expense_date]
    regsub "to_date" $expense_date_sql "to_timestamp" expense_date_sql
    if {![exists_and_not_null expense_id]} {

	# Let's create the new expense
	set expense_id [db_exec_plsql create_expense ""]

    }
 
    # Update the invoice itself
    db_dml update_expense "
update im_expenses 
set 
        external_company_name = :external_company_name,
        receipt_reference = :receipt_reference,
        billable_p = :billable_p,
        reimbursable = :reimbursable,
        expense_payment_type_id = :expense_payment_type_id
where
	expense_id = :expense_id
"

    db_dml update_costs "
update im_costs
set
	project_id	= :project_id,
	cost_name	= :expense_id,
	customer_id	= :customer_id,
	cost_nr		= :expense_id,
        cost_type_id    = :cost_type_id,
	provider_id	= :provider_id,
	template_id	= :template_id,
	effective_date	= $expense_date_sql,
	payment_days	= :payment_days,
	vat		= :vat_included,
	tax		= :tax,
	variable_cost_p = 't',
	amount		= :amount,
	currency	= :expense_currency
where
	cost_id = :expense_id
"


    template::forward $return_url
}

