# /packages/intranet-expenses/www/expense-ae.tcl
#
# Copyright (C) 2003-2006 Project/Open
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
    { project_id:integer "" }
    { return_url "/intranet-expenses/"}
    expense_id:integer,optional
    expense_amount:float,optional
    expense_date:optional
    {form_mode "edit"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "add_expenses"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

set today [lindex [split [ns_localsqltimestamp] " "] 0]
set action_url "new"
set page_title [lang::message::lookup "" intranet-expenses.New_Expense "New Expense Item"]
set context_bar [im_context_bar $page_title]
set date_format "YYYY-MM-DD"

set action_url "/intranet-expenses/expenses-ae"


if {"" != $project_id} {
    append return_url "index?[export_vars -url project_id]"
}


if {![exists_and_not_null currency]} {
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
}

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
set project_options [im_project_options \
	-exclude_subprojects_p 0 \
	-member_user_id $user_id
]

set include_empty 0
set currency_options [im_currency_options $include_empty]

set expense_type_options [db_list_of_lists expense_types "
	select	expense_type,
		expense_type_id
	from im_expense_type
"]


set include_empty 0
set currency_options [im_currency_options $include_empty]


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


# if {"" == $reimbursable_value} {
#     template::element::set_value $form_id reimbursable "100"
# }


# !!! set expense_date_value [template::element::get_value $form_id expense_date]
# if {"" == $expense_date_value} {
#     template::element::set_value $form_id expense_date $today
# }

# set expense_payment_type_value [template::element::get_value $form_id expense_payment_type_id]
# if {"" == $expense_payment_type_value} {
#     template::element::set_value $form_id expense_payment_type_id [im_expense_payment_type_cash]
# }



# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "expense_ae"
set focus "$form_id\.var_name"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {return_url} \
    -form {
        expense_id:key
        {project_id:text(select) 
	    {label "[lang::message::lookup {} intranet-expenses.Project Project]" } 
	    {options $project_options}
	}
	{expense_amount:text(text) {label "[_ intranet-expenses.Amount]"} {html {size 10}}}
	{expense_currency:text(select) 
	    {label "[_ intranet-expenses.Currency]"}
	    {options $currency_options} 
	}
	{vat_included:text(text) {label "[_ intranet-expenses.Vat_Included]"} {html {size 60}}}
	{expense_date:text(text) {label "[_ intranet-expenses.Expense_Date]"} {html {size 10}}}
	{external_company_name:text(text) {label "[_ intranet-expenses.External_company_name]"} {html {size 40}}}
	{external_company_vatnr:text(text) {label "[_ intranet-expenses.External_Company_VatNr]"} {html {size 20}}}
	{receipt_reference:text(text) {label "[_ intranet-expenses.Receipt_reference]"} {html {size 40}}}
	{expense_type_id:text(select) 
	    {label "[_ intranet-expenses.Expense_Type]"}
	    {options $expense_type_options} 
	}
        {billable_p:text(radio) {label "[_ intranet-expenses.Billable_p]"} {options {{[_ intranet-core.Yes] t} {[_ intranet-core.No] f}}} }
	{reimbursable:text(text) {label "[_ intranet-expenses.reimbursable]"} {html {size 10}}}
	{expense_payment_type_id:text(select) 
	    {label "[_ intranet-expenses.Expense_Payment_Type]"}
	    {options $expense_payment_type_options} 
	}
        {note:text(textarea),optional {label "[_ intranet-expenses.Note]"} {html {cols 40}}}
    }



#    check conditions
#    if {![empty_string_p $vat_included]} {
#        if {0>$vat_included || 100<$vat_included} {
#            template::element::set_error $form_id vat_included "[_ intranet-expenses.vat_included_not_valid]"
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
# Debug
# ------------------------------------------------------------------

set is_request [template::form::is_request $form_id]
set is_submission [template::form::is_submission $form_id]
set is_valid [template::form::is_valid $form_id]
set expense_id_exists [exists_and_not_null expense_id]

# ad_return_complaint 1 "r=$is_request, s=$is_submission, v=$is_valid, x=$expense_id_exists"


# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------

ad_form -extend -name $form_id -on_request {
    # Populate elements from local variables
} 

ad_form -extend -name $form_id -select_query {
    
	select	*,
		to_char(c.effective_date, :date_format) as expense_date
	from	im_costs c,
		im_expenses e
	where
		c.cost_id = :expense_id
		and c.cost_id = e.expense_id

}

# Reconstruct the amount from the fractioned amount
# including VAT
# !!! set expense_amount [format %.2f [expr $amount * [expr 1 + [expr $vat_included / 100]]]]


ad_form -extend -name $form_id -new_data {
    
    db_exec_plsql cost_center_insert {}
    
} 


ad_form -extend -name $form_id -edit_data {
    
    db_dml cost_center_update "
        update im_cost_centers set
                cost_center_name        = :cost_center_name,
                cost_center_label       = :cost_center_label,
                cost_center_code        = :cost_center_code,
                cost_center_type_id     = :cost_center_type_id,
                cost_center_status_id   = :cost_center_status_id,
                department_p            = :department_p,
                parent_id               = :parent_id,
                manager_id              = :manager_id,
                description             = :description
        where
                cost_center_id = :cost_center_id
"


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
	effective_date	= to_timestamp('YYYY-MM-DD', :expense_date),
	payment_days	= :payment_days,
	vat		= :vat_included,
	tax		= :tax,
	variable_cost_p = 't',
	amount		= :amount,
	currency	= :expense_currency,
	note		= :note
where
	cost_id = :expense_id
"




}

ad_form -extend -name $form_id -on_submit {
    
    ns_log Notice "new1: on_submit"
    
}

ad_form -extend -name $form_id -after_submit {

    ad_returnredirect $return_url
    ad_script_abort
}
