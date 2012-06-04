# /packages/intranet-planning/www/action.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-planning/index page or
    the notes-list-compomponent and perform the selected
    action an all selected notes.
    @author frank.bergmann@project-open.com
} {
    action
    object_id:integer
    return_url
    item_value:array,float,optional
    item_project_phase_id:array,optional
    item_project_member_id:array,optional
    item_cost_type_id:array,optional
    item_date:array,optional
    item_note:array,optional
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# Check the permissions
# Permissions for all usual projects, companies etc.
set user_id [ad_maybe_redirect_for_registration]
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd
if {!$object_write} { ad_return_complaint 1 "You don't have sufficient permission to perform this action" }

# The project's customer and providers
set customer_id [util_memoize [list db_string customer "select company_id from im_projects where project_id = $object_id" -default 0]]
set object_name [util_memoize [list db_string oname "select acs_object__name($object_id) from dual"]]
set provider_id [im_company_internal]

# Default user's hourly billing rate
set default_billing_rate [parameter::get_from_package_key -package_key intranet-cost -parameter "DefaultTimesheetHourlyCost" -default 30]
set billing_currency [parameter::get_from_package_key -package_key intranet-cost -parameter "DefaultCurrency" -default "EUR"]

switch $action {
    create_quote_from_planning_data {
	# Redirect to the wizard page to create a new quote
	ad_returnredirect [export_vars -base "/intranet-planning/quote-wizard/new-from-planning" {{project_id $object_id} return_url}]
    }
    save {
	# Delete the old values for this object_id
	db_dml del_im_planning_items "delete from im_planning_items where item_object_id = :object_id"
	
	# Create the new values whenever the value is not "" (null)
	set invoices_planned ""
	set quotes_planned ""
	set bills_planned ""
	set pos_planned ""
	set timesheet_budget_planned ""
	set timesheet_hours_planned ""
	set expense_items_planned ""
	set expense_bundles_planned ""

	# Delete existing planning elements
	foreach cost_type_id [list [im_cost_type_timesheet_planned] [im_cost_type_timesheet_hours] [im_cost_type_expense_planned]] {
	    set del_costs_sql "
		select	cost_id
		from	im_costs
		where	project_id = :object_id and
			cost_type_id = :cost_type_id
	    "
	    db_foreach del_costs $del_costs_sql {
		db_string del_cost "select im_cost__delete(:cost_id)"
	    }
	}

	foreach id [array names item_value] {
	    set value $item_value($id)
	    if {"" == $value} { continue }

	    set project_phase_id [im_opt_val item_project_phase_id($id)]
	    set project_member_id [im_opt_val item_project_member_id($id)]
	    set cost_type_id [im_opt_val item_cost_type_id($id)]
	    set date [im_opt_val item_date($id)]
	    set value [im_opt_val item_value($id)]
	    set note [im_opt_val item_note($id)]

	    set billing_rate [util_memoize [list db_string billing_rate "select hourly_cost from im_employees where employee_id = $project_member_id" -default ""]]
	    if {"" == $billing_rate} { set billing_rate $default_billing_rate }

	    db_string insert_im_planning_item "select im_planning_item__new(
			-- object standard 6 parameters
			null, 'im_planning_item', now(), :user_id, '[ns_conn peeraddr]', null,
			-- Main parameters
			:object_id, null, null,
			-- Value parameters
			:value, :note,
			-- Dimension parameters
			:project_phase_id, :project_member_id, :cost_type_id, :date
		)
	    "

	    set target_cost_type_id ""
	    set target_amount $value
	    switch $cost_type_id {
		3700 {
			# Customer Invoice
			if {"" == $invoices_planned} { set invoices_planned 0.0 }
			set invoices_planned [expr $invoices_planned + $value]
		}
		3702 {
			# Quote
			if {"" == $quotes_planned} { set quotes_planned 0.0 }
			set quotes_planned [expr $quotes_planned + $value]
		}
		3704 {
			# Provider Bill
			if {"" == $bills_planned} { set bills_planned 0.0 }
			set bills_planned [expr $bills_planned + $value]
		}
		3706 {
			# Purchase Order
			if {"" == $pos_planned} { set pos_planned 0.0 }
			set pos_planned [expr $pos_planned + $value]
		}
		3718 {
			# Timesheet Cost
			if {"" == $timesheet_budget_planned} { set timesheet_budget_planned 0.0 }
			set timesheet_budget_planned [expr $timesheet_budget_planned + $value]
		}
		3736 {
			# Timesheet Hours
			if {"" == $timesheet_hours_planned} { set timesheet_hours_planned 0.0 }
			set timesheet_hours_planned [expr $timesheet_hours_planned + $value]

			# Trigger the generation of a cost item
			set target_cost_type_id [im_cost_type_timesheet_planned]
			set target_amount [expr $billing_rate * $value]
		}
		3720 {
			# Expense Item
			if {"" == $expense_items_planned} { set expense_items_planned 0.0 }
			set expense_items_planned [expr $expense_items_planned + $value]
		}
		3722 {
			# Expense Bundle
			if {"" == $expense_bundles_planned} { set expense_bundles_planned 0.0 }
			set expense_bundles_planned [expr $expense_bundles_planned + $value]

			# Trigger the generation of a cost item
			set target_cost_type_id [im_cost_type_expense_planned]
		}
		default {
			# ToDo: Implement budget for expense types (airfare, telephone, ...)
			# Not implemented yet
			ad_return_complaint 1 "Project Financial Planning: '$cost_type' planning not implemented yet"
		}
	    }


	    # --------------------------------------------------
	    # Generate a cost element
	    if {"" != $target_cost_type_id} {
		ns_log Notice "action: Creating new cost element"
		set cost_name "[im_category_from_id $target_cost_type_id] for "
		if {"" != $project_member_id} { append cost_name [im_name_from_user_id $project_member_id] }
		if {"" != $project_phase_id} { append cost_name " in project phase [util_memoize [list db_string phase_name "select acs_object__name($project_phase_id) from dual"]]" }
		if {"" != $date} { append cost_name $date }
		append cost_name " in project $object_name"
		set cost_center_id [util_memoize [list im_costs_default_cost_center_for_user $project_member_id]]
		set cost_id [db_string im_cost__new "
				select im_cost__new(
					null, 'im_cost', now(), :user_id, '[ns_conn peeraddr]', null,	-- object standard args

					:cost_name,			-- cost_name default null
					null,				-- parent_id default null
					:object_id,			-- project_id default null
					:customer_id,			-- customer_id
					:provider_id,			-- provider_id
					null,				-- investment_id default null

					[im_cost_status_created],	-- cost_status_id
					:target_cost_type_id,		-- cost_type_id
					null,				-- template_id default null

					now(),				-- effective_date default now()
					0,				-- payment_days default 30
					:target_amount,			-- amount default null
					:billing_currency,		-- currency default EUR
					0.0,				-- vat default 0
					0.0,				-- tax default 0

					't',				-- variable_cost_p default f
					'f',				-- needs_redistribution_p default f
					'f',				-- redistributed_p default f
					't',				-- planning_p default f
					null,				-- planning_type_id default null

					:note,				-- note default null
					null				-- description default null
				)
		"]

		# Audit the action
		im_audit \
		    -object_type im_cost \
		    -action after_create \
		    -object_id $cost_id \
		    -status_id [im_cost_status_created] \
		    -type_id $target_cost_type_id \
		    -comment "Cost to represent timesheet hours."
	    }
	}


	# Calculate values for the project's budget fields
	set sql "update im_projects set
								cost_cache_dirty = now(),
	"
	if {"" != $invoices_planned} { append sql		"project_budget = :invoices_planned,\n" }
	if {"" != $quotes_planned} { append sql			"project_budget = :quotes_planned,\n" }
	if {"" != $bills_planned} { append sql			"cost_bills_planned = :bills_planned,\n" }
	if {"" != $pos_planned} { append sql			"cost_pos_planned = :pos_planned,\n" }
	if {"" != $timesheet_budget_planned} { append sql 	"cost_timesheet_budget_planned = :timesheet_budget_planned,\n" }
	if {"" != $timesheet_hours_planned} { append sql 	"project_budget_hours = :timesheet_hours_planned,\n" }
	if {"" != $expense_items_planned} { append sql		"cost_expenses_planned = :expense_items_planned,\n" }
	if {"" != $expense_bundles_planned} { append sql 	"cost_expenses_planned = :expense_bundles_planned,\n" }
	append sql "project_nr = project_nr
		where project_id = :object_id
	"

	db_dml update_project_budgets $sql
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url

