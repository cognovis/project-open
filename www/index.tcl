# /packages/intranet-expenses/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {

    { project_id }
    { cost_type_id:integer "[im_cost_type_invoice]" }
    { form_mode "edit" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set project_name [db_string project_name "select project_name from im_projects where project_id=:project_id" -default [_ intranet-core.One_project]]

set page_title $project_name
if {[im_permission $user_id view_projects_all]} {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
} else {
    set context_bar [im_context_bar $page_title]
}


set return_url [im_url_with_query]
set current_url [ns_conn url]


# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------
set add_expense_p [im_permission $user_id "add_expense"]
###### to be removed
set add_expense_p 1
######


set admin_links ""

if {$add_expense_p} {
    append admin_links " <li><a href=\"expense-ae?[export_url_vars project_id return_url]\">[_ intranet-expenses.Add_a_new_Expense]</a>\n"
}

set bulk_actions_list "[list]"
#[im_permission $user_id "delete_expense"]
set delete_expense_p 1 
if {$delete_expense_p} {
    lappend bulk_actions_list "[_ intranet-expenses.Delete]" "expense-del" "[_ intranet-expenses.Remove_checked_items]"
}
#[im_permission $user_id "add_expense_invoice"]
set create_invoice_p 1
if {$create_invoice_p} {
    lappend bulk_actions_list "[_ intranet-expenses.Create_Travel_Cost]" "create-tc" "[_ intranet-expenses.create_trabel_cost_help]"
}

# ---------------------------------------------------------------
# Expenses info
# ---------------------------------------------------------------

# Variables of this page to pass through the expenses_page

set export_var_list [list]

# define list object
set list_id "expenses_list"

template::list::create \
    -name $list_id \
    -multirow expense_lines \
    -key expense_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	project_id
    } \
    -row_pretty_plural "[_ intranet-expenses.Expenses_Items]" \
    -elements {
	expense_id {
	    label "[_ intranet-expenses.ID]"
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	}
	vat_included {
	    label "[_ intranet-expenses.Vat_Included]"
	}
	external_company_name {
	    label "[_ intranet-expenses.External_company_name]"
	}
	effective_date {
	    label "[_ intranet-expenses.Expense_Date]"
	}
	receipt_reference {
	    label "[_ intranet-expenses.Receipt_reference]"
	}
	expense_type {
	    label "[_ intranet-expenses.Expense_Type]"
	}
	invoice_id {
	    label "[_ intranet-expenses.Invoice]"
	}
	billable_p {
	    label "[_ intranet-expenses.Billable_p]"
	}
	reimbursable {
	    label "[_ intranet-expenses.reimbursable]"
	}
	expense_payment_type {
	    label "[_ intranet-expenses.Expense_Payment_Type]"
	}
	expense_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('expenses_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@expense_lines.expense_chk;noquote@
	    }
	}
    }

db_multirow -extend {expense_chk} expense_lines "get expenses" {
    select expense_id,  
           amount, 
           currency, 
           vat_included, 
	   external_company_name,
           to_char(effective_date,'DD/MM/YYYY') as effective_date,
	receipt_reference,
	expense_type,
	invoice_id,
	billable_p,
	reimbursable,
	expense_payment_type 
    from im_costs, im_expenses e, im_expense_type et, im_expense_payment_type ept
    where project_id = :project_id 
	and cost_id = expense_id
        and provider_id = :user_id
        and et.expense_type_id =e.expense_type_id 
        and ept.expense_payment_type_id = e.expense_payment_type_id
} {

    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat_included / 100]]]] $currency"
    set vat_included "[format %.1f $vat_included] %"
    set reimbursable "[format %.1f $reimbursable] %"
    if {![exists_and_not_null invoice_id]} {
	set expense_chk "<input type=\"checkbox\" 
                                name=\"expense_id\" 
                                value=\"$expense_id\" 
                                id=\"expenses_list,$expense_id\">"
    }
}

# ----------------------------------------------
# add expense part
# ----------------------------------------------
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



# ----------------------------------------------
# invoices part
# ----------------------------------------------

set list2_id "invoices_list"

set bulk2_actions_list "[list]"
#[im_permission $user_id "delete_expense_invoice"]
set delete_invoice_p 1 
if {$delete_invoice_p} {
    lappend bulk2_actions_list "[_ intranet-expenses.Delete]" "invoice-del" "[_ intranet-expenses.Remove_checked_items]"
}

template::list::create \
    -name $list2_id \
    -multirow invoice_lines \
    -key cost_id \
    -has_checkboxes \
    -bulk_actions  $bulk2_actions_list \
    -bulk_action_export_vars  {
	project_id
    } \
    -row_pretty_plural "[_ intranet-expenses.Invoice_Items]" \
    -elements {
	cost_id {
	    label "[_ intranet-expenses.ID]"
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	}
	vat {
	    label "[_ intranet-expenses.Vat_Included]"
	}
	effective_date {
	    label "[_ intranet-expenses.Expense_Date]"
	}
	invoice_chk {
	    label "<input type=\"checkbox\" name=\"_dummy\" onclick=\"acs_ListCheckAll('invoices_list', this.checked)\" title=\"Check/uncheck all rows\">"
	    display_template {
		@invoice_lines.invoice_chk;noquote@
	    }
	}
    }

db_multirow -extend {invoice_chk} invoice_lines "get invoices" {
    select c1.cost_id,  
           c1.amount,
           c1.currency, 
           c1.vat, 
           to_char(c1.effective_date,'DD/MM/YYYY') as effective_date
    from im_costs c1
    where c1.project_id = :project_id 
	and c1.cost_id in (select invoice_id 
			from im_costs c2, 
			     im_expenses 
			where c2.project_id = :project_id 
			and c2.cost_id = expense_id
			and c2.provider_id = :user_id
		       )
        and c1. provider_id = :user_id
} {

    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat / 100]]]] $currency"
    set vat "[format %.1f $vat] %"
    set invoice_chk "<input type=\"checkbox\" 
                                name=\"invoice_id\" 
                                value=\"$cost_id\" 
                                id=\"invoices_list,$cost_id\">"
}


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_expenses"]

