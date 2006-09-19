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
    { project_id 0}
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
set date_format "YYYY-MM-DD"

set return_url [im_url_with_query]
set current_url [ns_conn url]

set project_name [db_string project_name "select project_name from im_projects where project_id=:project_id" -default ""]

set page_title "$project_name [_ intranet-expenses.Unassigned_Expenses]"

if {[im_permission $user_id view_projects_all]} {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
} else {
    set context_bar [im_context_bar $page_title]
}


# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------
set add_expense_p [im_permission $user_id "add_expenses"]

set admin_links ""
set bulk_actions_list "[list]"

if {$add_expense_p} {

    append admin_links " <li><a href=\"new?[export_url_vars project_id return_url]\">[_ intranet-expenses.Add_a_new_Expense]</a>\n"

    lappend bulk_actions_list "[_ intranet-expenses.Delete]" "expense-del" "[_ intranet-expenses.Delete_Expenses]"

}

set create_invoice_p [im_permission $user_id "add_expense_invoice"]
if {$create_invoice_p} {
    lappend bulk_actions_list "[_ intranet-expenses.Create_Travel_Cost]" "[export_vars -base "create-tc" {project_id}]" "[_ intranet-expenses.create_trabel_cost_help]"
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
	expense_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('expenses_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@expense_lines.expense_chk;noquote@
	    }
	}
	effective_date {
	    label "[_ intranet-expenses.Expense_Date]"
	    link_url_eval "/intranet-expenses/new?expense_id=$expense_id"
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	    display_template { <nobr>@expense_lines.amount;noquote@</nobr> }
	    link_url_eval "/intranet-expenses/new?expense_id=$expense_id"
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
	}
	note {
	    label "[lang::message::lookup {} intranet-expenses.Note {Note}]"
	}
    }

set project_where ""
if {0 != $project_id} { 
    set project_where "\tand c.project_id = :project_id\n" 
}



db_multirow -extend {expense_chk} expense_lines expenses_lines "
  select
	expense_id,  
	amount, 
	currency, 
	vat, 
	external_company_name,
	to_char(effective_date, :date_format) as effective_date,
	receipt_reference,
	expense_type,
	invoice_id,
	billable_p,
	reimbursable,
	expense_payment_type,
	p.project_name,
	c.note
  from
	im_costs c
	LEFT OUTER JOIN im_projects p on (c.project_id = p.project_id),
	im_expenses e, 
	im_expense_type et, 
	im_expense_payment_type ept
  where
	provider_id = :user_id
	$project_where
	and cost_id = expense_id
	and et.expense_type_id =e.expense_type_id 
	and ept.expense_payment_type_id = e.expense_payment_type_id
   order by
	c.effective_date DESC
" {

    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat / 100]]]] $currency"
    set vat "[format %.1f $vat] %"
    set reimbursable "[format %.1f $reimbursable] %"
    if {![exists_and_not_null invoice_id]} {
	set expense_chk "<input type=\"checkbox\" 
				name=\"expense_id\" 
				value=\"$expense_id\" 
				id=\"expenses_list,$expense_id\">"
    }
}


# ----------------------------------------------
# invoices part
# ----------------------------------------------

set list2_id "invoices_list"

set delete_invoice_p [im_permission $user_id "add_expense_invoice"]
set bulk2_actions_list [list]
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

