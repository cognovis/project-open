# /packages/intranet-expenses/www/classify-costs.tcl
#
# Copyright (c) 2003-2006 ]project-open[
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Assign several expense items to a specific project

    @author frank.bergmann@project-open.com
} {
    return_url
    expense_id:integer,multiple
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id "add_expense_bundle"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

set expense_ids $expense_id

set page_title [lang::message::lookup "" intranet-expenses.Assign_Expenses_to_Projects "Assign Expenses to Projects"]
set context_bar [im_context_bar $page_title]

set date_format [im_l10n_sql_date_format]
set percent_format "FM999"


# ---------------------------------------------------------------
# List of expense_ids
# ---------------------------------------------------------------

set expense_ids_html ""
foreach id $expense_id {
    append expense_ids_html "<input type=hidden name=expense_ids value=$id>\n"
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
    -bulk_action_export_vars { return_url } \
    -row_pretty_plural "[_ intranet-expenses.Expenses_Items]" \
    -elements {
	effective_date {
	    label "[_ intranet-expenses.Expense_Date]"
	    link_url_eval $expense_new_url
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	    display_template { <nobr>@expense_lines.amount;noquote@</nobr> }
	    link_url_eval $expense_new_url
	}
	provider_name {
	    label "[lang::message::lookup {} intranet-expenses.Submitter Submitter]"
	    link_url_eval $provider_url
	}
	vat {
	    label "[_ intranet-expenses.Vat_Included]"
	}
	external_company_name {
	    label "[_ intranet-expenses.External_company_name]"
	}
	receipt_reference {
	    label "[_ intranet-expenses.Receipt_reference]"
	}
	expense_type {
	    label "[_ intranet-expenses.Expense_Type]"
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
	project_name {
	    label "[_ intranet-expenses.Project_Name]"
	    link_url_eval $project_url
	}
	note {
	    label "[lang::message::lookup {} intranet-expenses.Note {Note}]"
	}
    }


db_multirow -extend {expense_chk project_url expense_new_url provider_url} expense_lines expenses_lines "
  select
	c.*,
	e.*,
	acs_object__name(provider_id) as provider_name,
	to_char(effective_date, :date_format) as effective_date,
	im_category_from_id(expense_type_id) as expense_type,
	im_category_from_id(expense_payment_type_id) as expense_payment_type,
	p.project_name
  from
	im_costs c
	LEFT OUTER JOIN im_projects p on (c.project_id = p.project_id),
	im_expenses e
  where
	cost_id = expense_id
	and c.cost_id in ([join $expense_ids ", "])
   order by
	c.effective_date DESC
" {
    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat / 100]]]] $currency"
    set vat "[format %.1f $vat] %"
    set reimbursable "[format %.1f $reimbursable] %"
    set expense_new_url [export_vars -base "/intranet-expenses/new" {expense_id return_url}]
    set provider_url [export_vars -base "/intranet/companies/view" {{company_id $provider_id} return_url}]
    set project_url [export_vars -base "/intranet/projects/view" {{project_id $project_id} return_url}]
}

