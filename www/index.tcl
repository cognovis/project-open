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

set admin_links "<li><a href=\"expense-ae?[export_url_vars project_id return_url]\">[_ project-expenses.Add_a_new_Expense]</a>\n"


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
    -actions [list "Add item" [export_vars -base item-add {order_id}] "Add item to this order"] \
    -bulk_actions {
            "Remove" "item-remove" "Remove checked items"
    } \
    -row_pretty_plural "Expenses Items" \
    -elements {
	expense_id {
	    label "ID"
	}
	amount {
	    label "Amount"
	}
	currency {
	    label "Currency"
	}
	vat_included {
	    label "Vat Included"
	}
	external_company_name {
	    label "External Company Name"
	}
	receipt_reference {
	    label "Receipt Reference"
	}
	expense_type {
	    label "Expense Type"
	}
	invoice_id {
	    label "Invoice"
	}
	billable_p {
	    label "Billable?"
	}
	reimbursable {
	    label "Reibursable"
	}
	expense_payment_type {
	    label "Expenses Payment Type"
	}
    }

db_multirow expense_lines "get expenses" {
    select expense_id,  
           amount, 
           currency, 
           vat_included, 
	   external_company_name,
	receipt_reference,
	expense_type_id as expense_type,
	invoice_id,
	billable_p,
	reimbursable,
	expense_payment_type_id as expense_payment_type 
    from im_costs, im_expenses where project_id = :project_id 
	and cost_id = expense_id
}

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_expenses"]

