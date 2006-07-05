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

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "expense_ae"
set focus "$form_id\.var_name"

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


template::form::create $form_id \
    -cancel_url "$return_url" \
    -mode "$form_mode" \
    -view_buttons [list [list "[_ intranet-core.Back]" back]]

element::create $form_id expense_id \
    -widget hidden \
    -optional

element::create $form_id project_id \
    -optional \
    -datatype integer \
    -widget select \
    -options $project_options \
    -label [lang::message::lookup "" intranet-expenses.Project "Project"]
set project_id_value [template::element::get_value $form_id project_id]
if {"" == $project_id_value} {
    template::element::set_value $form_id project_id $project_id
}


element::create $form_id expense_amount \
    -datatype text \
    -widget text \
    -html {size 10} \
    -label "[_ intranet-expenses.Amount]"

element::create $form_id expense_currency \
    -datatype text \
    -widget select \
    -options $currency_options \
    -label "[_ intranet-expenses.Currency]"

element::create $form_id vat_included \
    -datatype text \
    -widget text \
    -html {size 6} \
    -label "[_ intranet-expenses.Vat_Included]"
template::element::set_value $form_id vat_included 0

element::create $form_id expense_date \
    -datatype date \
    -widget text \
    -html {size 10} \
    -label "[_ intranet-expenses.Expense_Date]"
template::element::set_value $form_id expense_date $today

element::create $form_id external_company_name \
    -datatype text \
    -widget text \
    -html {size 40} \
    -label "[_ intranet-expenses.External_company_name]"

element::create $form_id external_company_vatnr \
    -optional \
    -datatype text \
    -widget text \
    -html {size 20} \
    -label "[_ intranet-expenses.External_Company_VatNr]"

element::create $form_id receipt_reference \
    -optional \
    -datatype text \
    -widget text \
    -html {size 40} \
    -label "[_ intranet-expenses.Receipt_reference]"

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
template::element::set_value $form_id billable_p "f"


template::element::set_value $form_id billable_p "f"

element::create $form_id reimbursable \
    -datatype text \
    -widget text \
    -html {size 10} \
    -label "[_ intranet-expenses.reimbursable]"
set reimbursable_value [template::element::get_value $form_id reimbursable]
if {"" == $reimbursable_value} {
    template::element::set_value $form_id reimbursable "100"
}


template::element::set_value $form_id reimbursable 100

element::create $form_id expense_payment_type_id \
    -datatype integer \
    -widget select \
    -options $expense_payment_type_options \
    -label "[_ intranet-expenses.Expense_Payment_Type]"

element::create $form_id note \
    -optional \
    -datatype text \
    -widget textarea \
    -html {cols 40} \
    -label "[_ intranet-expenses.Note]"



# ------------------------------------------------------------------
# Debug
# ------------------------------------------------------------------

set is_request [template::form::is_request $form_id]
set is_submission [template::form::is_submission $form_id]
set is_valid [template::form::is_valid $form_id]
set expense_id_exists [exists_and_not_null expense_id]

# ad_return_complaint 1 "r=$is_request, s=$is_submission, v=$is_valid, x=$expense_id_exists"


# ------------------------------------------------------------------
# Set editing variables
# ------------------------------------------------------------------

if {!$is_submission && [exists_and_not_null expense_id]} {
    db_0or1row expense_info "
	select	*,
		to_char(c.effective_date, :date_format) as expense_date
	from	im_costs c,
		im_expenses e
	where
		c.cost_id = :expense_id
		and c.cost_id = e.expense_id
    "

    # Reconstruct the amount from the fractioned amount
    # including VAT
    set expense_amount [format %.2f [expr $amount * [expr 1 + [expr $vat_included / 100]]]]

    # Returns the list of all element variables
    set elements [template::form::get_elements $form_id]

    foreach elem $elements {
	if {[info exists $elem]} {
	    set elem_val [expr "\$$elem"]
	    template::element::set_value $form_id $elem $elem_val
	}
    }
}



# ------------------------------------------------------------------
# Set default variables if New
# ------------------------------------------------------------------

set expense_date_value [template::element::get_value $form_id expense_date]
if {"" == $expense_date_value} {
    template::element::set_value $form_id expense_date $today
}

set expense_payment_type_value [template::element::get_value $form_id expense_payment_type_id]
if {"" == $expense_payment_type_value} {
    template::element::set_value $form_id expense_payment_type_id [im_expense_payment_type_cash]
}


# ------------------------------------------------------------------
# is_request
# ------------------------------------------------------------------

if {[form is_request $form_id]} {
    ns_log notice "is request"

    form get_values $form_id
    if {[exists_and_not_null expense_id]} {
	# get db values for current expense

    }
    template::element::set_value $form_id expense_currency $currency
}

# ------------------------------------------------------------------
# is_submission
# ------------------------------------------------------------------

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

# ------------------------------------------------------------------
# is_valid
# Go and save the values
# ------------------------------------------------------------------

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


    template::forward $return_url
}

