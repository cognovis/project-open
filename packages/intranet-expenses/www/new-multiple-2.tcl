# /packages/intranet-expenses/www/new-multiple-2.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Create a number of expenses at a time
    @author frank.bergmann@project-open.com
} {
    project_id:array,integer,optional
    expense_amount:array,float,optional
    currency:array,optional
    vat:array,float,optional
    expense_date:array,optional
    external_company_name:array,optional
    expense_type_id:array,integer,optional
    billable_p:array,optional
    reimbursable:array,optional,optional
    expense_payment_type_id:array,integer,optional
    receipt_reference:array,optional
    note:array,optional
    { user_id_from_search "" }
    return_url
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
set page_title [lang::message::lookup "" intranet-expenses.New_Expense "New Expense Item"]
if {"" != $user_id_from_search && $current_user_id != $user_id_from_search} {
    set user_name_from_search [im_name_from_user_id $user_id_from_search]
    append page_title [lang::message::lookup "" intranet-expenses.for_user_id_from_search "for '%user_name_from_search%'"]
}
set context_bar [im_context_bar $page_title]
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set percent_format "FM999"

# Should we calculate VAT automatically from the expense type?
set auto_vat_p [ad_parameter -package_id [im_package_expenses_id] "CalculateVATPerExpenseTypeP" "" 0]
set auto_vat_function [ad_parameter -package_id [im_package_expenses_id] "CalculateVATPerExpenseTypeFunction" "" "im_expense_calculate_vat_from_expense_type"]


# ------------------------------------------------------------------
# First we need to go through all items and check for incomplete lines
# before we can go and create the items.
# ------------------------------------------------------------------

for {set i 0} {$i < 20} {incr i} {

    set set_p 0

    set item_customer_id [im_company_internal]
    set item_provider_id $user_id
    set item_template_id ""
    set item_payment_days "30"
    set item_cost_status [im_cost_status_created]
    set item_cost_type_id [im_cost_type_expense_item]
    set item_project_id ""
    set item_expense_amount ""
    set item_currency $default_currency
    set item_vat 0
    set item_tax 0
    set item_expense_date $today
    set item_external_company_name ""
    set item_expense_type_id ""
    set item_billable_p "f"
    set item_reimbursable 100
    set item_expense_payment_type_id [im_expense_payment_type_cash]
    set item_receipt_reference ""
    set item_note ""
    

    if {[info exists project_id($i)] && "" != $project_id($i)} { 
	set item_project_id $project_id($i)
    }

    if {[info exists expense_amount($i)] && "" != $expense_amount($i)} {
	set item_expense_amount $expense_amount($i)
	set set_p 1
    }

    if {[info exists currency($i)] && "" != $currency($i)} { 
	set item_currency $currency($i)
    }

    if {[info exists vat($i)] && "" != $vat($i)} { 
	set item_vat $vat($i)
	set set_p 2
    }

    if {[info exists expense_date($i)] && "" != $expense_date($i)} { 
	set item_expense_date $expense_date($i)
    }

    if {[info exists external_company_name($i)] && "" != $external_company_name($i)} { 
	set item_external_company_name $external_company_name($i)
	set set_p 3
    }

    if {[info exists expense_type_id($i)] && "" != $expense_type_id($i) && 0 != $expense_type_id($i)} { 
	set item_expense_type_id $expense_type_id($i)
	set set_p 4
    }

    if {[info exists billable_p($i)] && "" != $billable_p($i)} { 
	set item_billable_p $billable_p($i)
    }

    if {[info exists reimbursable($i)] && "" != $reimbursable($i)} { 
	set item_reimbursable $reimbursable($i)
	set set_p 5
    }

    if {[info exists expense_payment_type_id($i)] && "" != $expense_payment_type_id($i) && 0 != $expense_payment_type_id($i)} { 
	set item_expense_payment_type_id $expense_payment_type_id($i)
	set set_p 6
    }


    if {[info exists receipt_reference($i)] && "" != $receipt_reference($i)} {
        set item_receipt_reference $receipt_reference($i)
        set set_p 7
    }

    if {[info exists note($i)] && "" != $note($i)} { 
	set item_note $note($i)
	set set_p 8
    }


    if {$set_p != 0} {

	# Check the format of the expense date
	if {![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $item_expense_date]} {
	    ad_return_complaint 1 "Expense Date doesn't have the right format.<br>
	    Current value: '$item_expense_date'<br>
	    Expected format: 'YYYY-MM-DD'"
	    ad_script_abort
	}

	if {"" == $item_expense_amount} {
	    ad_return_complaint 1 "Found empty 'amount' in line [expr $i+1]."
	    ad_script_abort
	}


	# Don't allow negative expense_amounts
	if {"" != $item_expense_amount && $item_expense_amount < 0} {
	    ad_return_complaint 1 "Found negative expense amount:<br>
		Current value: '$item_expense_amount'
	    "
	    ad_script_abort
	}

	if { $item_expense_type_id == 0 } {
	    ad_return_complaint 1 [lang::message::lookup "" \
	     intranet-expenses.Expense_type_is_required \
	     "You have to selectect an expense type"]
	}


    }
}



# ------------------------------------------------------------------
# In a second pass we can now create the expense items.
# This should(!) not give any errors anymore.
# ------------------------------------------------------------------

db_transaction {

    for {set i 0} {$i < 20} {incr i} {

	set set_p 0

	set item_customer_id [im_company_internal]
	set item_provider_id $user_id_from_search
	set item_template_id ""
	set item_payment_days "30"
	set item_cost_status [im_cost_status_created]
	set item_cost_type_id [im_cost_type_expense_item]
	set item_project_id ""
	set item_expense_amount ""
	set item_currency $default_currency
	set item_vat 0
	set item_tax 0
	set item_expense_date $today
	set item_external_company_name ""
	set item_expense_type_id ""
	set item_billable_p "f"
	set item_reimbursable 100
	set item_expense_payment_type_id [im_expense_payment_type_cash]
	set item_receipt_reference
	set item_note ""
	
	set item_external_company_vat_number ""
	set item_receipt_reference ""
	
	if {[info exists project_id($i)] && "" != $project_id($i)} { 
	    set item_project_id $project_id($i)
	}
	
	if {[info exists expense_amount($i)] && "" != $expense_amount($i)} {
	    set item_expense_amount $expense_amount($i)
	    set set_p 1
	}

	if {[info exists currency($i)] && "" != $currency($i)} { 
	    set item_currency $currency($i)
	}
	
	if {[info exists vat($i)] && "" != $vat($i)} { 
	    set item_vat $vat($i)
	    set set_p 1
	}
	
	if {[info exists expense_date($i)] && "" != $expense_date($i)} { 
	    set item_expense_date $expense_date($i)
	}
	
	if {[info exists external_company_name($i)] && "" != $external_company_name($i)} { 
	    set item_external_company_name $external_company_name($i)
	    set set_p 1
	}
	
	if {[info exists expense_type_id($i)] && "" != $expense_type_id($i) && 0 != $expense_type_id($i)} { 
	    set item_expense_type_id $expense_type_id($i)
	    set set_p 1
	}
	
	if {[info exists billable_p($i)] && "" != $billable_p($i)} { 
	    set item_billable_p $billable_p($i)
	}
	
	if {[info exists reimbursable($i)] && "" != $reimbursable($i)} { 
	    set item_reimbursable $reimbursable($i)
	    set set_p 1
	}
	
	if {[info exists expense_payment_type_id($i)] && "" != $expense_payment_type_id($i) && 0 != $expense_payment_type_id($i)} { 
	    set item_expense_payment_type_id $expense_payment_type_id($i)
	    set set_p 1
	}

        if {[info exists receipt_reference($i)] && "" != $receipt_reference($i)} {
            set item_receipt_reference $receipt_reference($i)
            set set_p 1
        }

	if {[info exists note($i)] && "" != $note($i)} { 
	    set item_note $note($i)
	    set set_p 1
	}
	

	if {$set_p} {

	    # Get the user's department as default CC
	    set cost_center_id [db_string user_cc "select department_id from im_employees where employee_id = :user_id" -default ""]
	    # Choose a name for the expense without incrementing the object pointer
	    set item_expense_name [expr [db_string expname "select t_acs_object_id_seq.last_value"] +1]
	    
	    set expense_id [db_string create_expense "
			select im_expense__new (
				null,				-- expense_id
				'im_expense',			-- object_type
				now(),				-- creation_date 
				:user_id,			-- creation_user
				'[ad_conn peeraddr]',		-- creation_ip
				null,				-- context_id
				:item_expense_name,		-- expense_name
				:item_project_id,		-- project_id
				:item_expense_date,		-- expense_date now()
				:item_currency,			-- expense_currency default ''EUR''
				null,				-- expense_template_id default null
				:item_cost_status,		-- expense_status_id default 3802
				:item_cost_type_id,		-- expense_type_id default 3720
				:item_payment_days,		-- payment_days default 30
				:item_expense_amount,		-- amount
				:item_vat,			-- vat default 0
				:item_tax,			-- tax default 0
				:item_note,			-- note
				:item_external_company_name,	-- hotel name, taxi, ...
				:item_external_company_vat_number,	-- vat number
				:item_receipt_reference,	-- receipt refergence
				:item_expense_type_id,		-- expense type default null
				:item_billable_p,		-- is billable to client 
				:item_reimbursable,		-- % reibursable from amount value
				:item_expense_payment_type_id, 	-- credit card used to pay, ...
				:item_customer_id,		-- customer
				:item_provider_id		-- provider
			)
	    "]

	    # Calculate VAT automatically?
	    if {$auto_vat_p} { 
		set item_vat [$auto_vat_function -expense_id $expense_id] 
	    }
	    
	    set item_amount [expr $item_expense_amount / [expr 1 + [expr $item_vat / 100.0]]]

	    db_dml update_costs "
			update im_costs set
				cost_center_id = :cost_center_id,
				vat = :item_vat,
				tax = :item_tax,
				amount = :item_amount,
				note = :item_note
			where cost_id = :expense_id
	    "

	    # Audit the action
	    im_audit -object_type im_expense -action after_create -object_id $expense_id -status_id $item_cost_status -type_id $item_cost_type_id
	}
	
    }
}

ad_returnredirect $return_url

