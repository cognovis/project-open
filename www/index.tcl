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
    { project_id:integer ""}
    { expense_type_id:integer ""}
    { start_date ""}
    { end_date ""}
    { provider_id 0}
    { orderby "effective_date,desc" }
    { unassigned "all"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_focus "im_header_form.keywords"
set date_format "YYYY-MM-DD"
set cur_format [im_l10n_sql_currency_format]
set return_url [im_url_with_query]
set current_url [ns_conn url]
set project_nr [db_string project_nr "select project_nr from im_projects where project_id=:project_id" -default "Unassigned"]
set page_title "$project_nr - [_ intranet-expenses.Unassigned_Expenses]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]

set org_project_id $project_id
# if {"" == $org_project_id} { set unassigned "unassigned" }


# Check that Start & End-Date have correct format
#if {"" != $start_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
#    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
#    Current value: '$start_date'<br>
#    Expected format: 'YYYY-MM-DD'"
#}

#if {"" != $end_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
#    ad_return_complaint 1 "End Date doesn't have the right format.<br>
#    Current value: '$end_date'<br>
#    Expected format: 'YYYY-MM-DD'"
#}


set main_navbar_label "projects"
if {"" == $project_id | 0 == $project_id} { set main_navbar_label "expenses" }

# ---------------------------------------------------------------
# Default Start and End


#db_1row todays_date "
#select
#        to_char(now()::date, 'YYYY') as todays_year,
#        to_char(now()::date, 'MM') as todays_month
#"
#if {"" == $start_date} { set start_date "$todays_year-01-01" }
#
#db_1row end_date "
#select
#        to_char(to_date(:start_date, 'YYYY-MM-DD') + 365::integer, 'YYYY') as end_year,
#        to_char(to_date(:start_date, 'YYYY-MM-DD') + 365::integer, 'MM') as end_month
#"
#if {"" == $end_date} { set end_date "$end_year-01-01" }


set unassigned_p_options [list \
        "unassigned" [lang::message::lookup "" intranet-expenses.Unassigned "Expenses without Projects"] \
        "assigned" [lang::message::lookup "" intranet-expenses.Assigned "Expenses assigned to a Projects"] \
        "both" [lang::message::lookup "" intranet-expenses.Assig_Unassig "Expenses with or without Project"] \
        "all" [lang::message::lookup "" intranet-expenses.All "All Expenses"] \
]


# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set add_expense_p [im_permission $user_id "add_expenses"]
set create_invoice_p [im_permission $user_id "add_expense_invoice"]

set admin_links ""
set bulk_actions_list "[list]"

if {$add_expense_p} {
    append admin_links "<li><a href=\"new?[export_url_vars project_id return_url]\">[_ intranet-expenses.Add_a_new_Expense]</a>\n"
    lappend bulk_actions_list "[_ intranet-expenses.Delete]" "expense-del" "[_ intranet-expenses.Delete_Expenses]"
}

if {$create_invoice_p} {
    lappend bulk_actions_list "[_ intranet-expenses.Create_Invoice]" "[export_vars -base "create-tc" {project_id}]" "[_ intranet-expenses.create_invoice_help]"

    lappend bulk_actions_list "[lang::message::lookup "" intranet-expenses.Assign_to_a_project {Assign to a Project}]" "[export_vars -base "classify-costs" {project_id}]" "[lang::message::lookup "" intranet-expenses.Assign_to_a_project_help {Assign several expenses to a project}]"


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
    -bulk_action_export_vars { start_date end_date return_url } \
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
	    link_url_eval $expense_new_url
	    display_template { <nobr>@expense_lines.effective_date;noquote@</nobr> }
	    orderby "c.effective_date"
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	    display_template { <nobr>@expense_lines.amount;noquote@</nobr> }
	    link_url_eval $expense_new_url
	    orderby amount
	}
	provider_name {
	    label "[lang::message::lookup {} intranet-expenses.Submitter Submitter]"
	    link_url_eval $provider_url
	    display_template { <nobr>@expense_lines.provider_name;noquote@</nobr> }
	    orderby provider_name
	}
	vat {
	    label "[_ intranet-expenses.Vat_Included]"
	    orderby vat
	}
	external_company_name {
	    label "[_ intranet-expenses.External_company_name]"
	    orderby external_company_name
	}
	receipt_reference {
	    label "[_ intranet-expenses.Receipt_reference]"
	    orderby receipt_reference
	}
	expense_type {
	    label "[_ intranet-expenses.Expense_Type]"
	    orderby expense_type
	}
	billable_p {
	    label "[_ intranet-expenses.Billable_p]"
	}
	reimbursable {
	    label "[_ intranet-expenses.reimbursable]"
	}
	expense_payment_type {
	    label "[_ intranet-expenses.Expense_Payment_Type]"
	    orderby expense_payment_type
	}
	project_name {
	    label "[_ intranet-expenses.Project_Name]"
	    link_url_eval $project_url
	    orderby project_name
	}
	note {
	    label "[lang::message::lookup {} intranet-expenses.Note {Note}]"
	}
    } \
    -filters {
 	start_date {}
        end_date {}
        project_id {}
	expense_type_id {}
	unassigned {}
    }

set project_where ""
if {"" != $project_id & 0 != $project_id} { 
    set project_where "\tand c.project_id = :project_id\n" 
}

set expense_where ""
if {"" != $expense_type_id  & 0 != $expense_type_id} { 
    set expense_where "\tand e.expense_type_id = :expense_type_id\n" 
}





# Allow accounting guys to see all expense items,
# not just their own ones...
set personal_only_sql "and provider_id = :user_id"
if {$create_invoice_p} { set personal_only_sql "" }

set unassigned_sql "and e.invoice_id is null"
if {"all" == $unassigned} { set unassigned_sql "" }

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
	$unassigned_sql
	$personal_only_sql
	$project_where
	$expense_where
  [template::list::orderby_clause -name $list_id -orderby]
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
    set expense_new_url [export_vars -base "/intranet-expenses/new" {expense_id return_url}]
    set provider_url [export_vars -base "/intranet/companies/view" {{company_id $provider_id} return_url}]
    set project_url [export_vars -base "/intranet/projects/view" {{project_id $project_id} return_url}]
}


#	and c.effective_date >= to_date(:start_date, 'YYYY-MM-DD')
#	and c.effective_date < to_date(:end_date, 'YYYY-MM-DD')

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
    -bulk_action_export_vars { project_id } \
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
	project_name {
	    label "[lang::message::lookup {} intranet-expenses.Project Project]"
	    link_url_eval $project_url
	}
	invoice_chk {
	    label "<input type=\"checkbox\" name=\"_dummy\" onclick=\"acs_ListCheckAll('invoices_list', this.checked)\" title=\"Check/uncheck all rows\">"
	    display_template {
		@invoice_lines.invoice_chk;noquote@
	    }
	}
    }



db_multirow -extend {invoice_chk project_url} invoice_lines "get invoices" "
	select	c.*,
		to_char(c.effective_date,'DD/MM/YYYY') as effective_date,
		acs_object__name(c.project_id) as project_name
	from 
		im_costs c
	where
		c.cost_type_id = [im_cost_type_expense_report]
		$project_where
" {

    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat / 100]]]] $currency"
    set vat "[format %.1f $vat] %"
    set invoice_chk "<input type=\"checkbox\" 
				name=\"invoice_id\" 
				value=\"$cost_id\" 
				id=\"invoices_list,$cost_id\">"
    set project_url [export_vars -base "/intranet/projects/view" {{project_id $project_id} return_url}]
}


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_expenses"]

if {0 == $org_project_id | "" == $org_project_id} {
    set project_menu ""
}