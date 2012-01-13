# /packages/intranet-expenses/www/new-multiple.tcl
#
# Copyright (C) 2003-2008 ]project-open[
# Frank Bergmann <frank.bergmann@project-open.com>
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Add a bunch of expense items
    @param project_id project on expense is going to create
    @author frank.bergmann@project-open.com
} {
    { cost_type_id:integer "[im_cost_type_expense_item]" }
    { project_id:integer "" }
    { return_url "/intranet-expenses/"}
    { user_id_from_search "" }
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
set this_year [string range [ns_localsqltimestamp] 0 4]
set page_title "[lang::message::lookup "" intranet-expenses.New_Expense_Items "New Expense Items"] "
if {"" != $user_id_from_search && $current_user_id != $user_id_from_search} {
    set user_name_from_search [im_name_from_user_id $user_id_from_search]
    append page_title [lang::message::lookup "" intranet-expenses.for_user_id_from_search "for '%user_name_from_search%'"]
}


set context_bar [im_context_bar $page_title]

set currency_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]
set percent_format "FM999"
set action_url "/intranet-expenses/new-multiple-2"

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

# Should we calculate VAT automatically from the expense type?
set auto_vat_p [ad_parameter -package_id [im_package_expenses_id] "CalculateVATPerExpenseTypeP" "" 0]
set auto_vat_function [ad_parameter -package_id [im_package_expenses_id] "CalculateVATPerExpenseTypeFunction" "" "im_expense_calculate_vat_from_expense_type"]

# Redirect if the type of the object hasn't been defined and
# if there are DynFields specific for subtypes.
if {0 == $cost_type_id && ![info exists expense_id]} {
    set all_same_p [im_dynfield::subtype_have_same_attributes_p -object_type "im_expense"]
    set all_same_p 0
    if {!$all_same_p} {
        ad_returnredirect [export_vars -base "/intranet/biz-object-type-select" {{object_type "im_expense"} {return_url $current_url} {type_id_var "cost_type_id"}}]
    }
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

if {[info exists expense_id]} {
    set project_id [db_string expense_project "select project_id from im_costs where cost_id = :expense_id" -default ""]
}

set project_options [im_project_options \
	-exclude_subprojects_p 0 \
	-member_user_id $user_id \
	-project_id $project_id \
	-exclude_status_id [im_project_status_closed] \
]

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

set expense_billable_options [list [list [_ intranet-core.Yes] t] [list [_ intranet-core.No] f]]


# ------------------------------------------------------------------
# Form defaults
# ------------------------------------------------------------------

# Default variables for "costs" (not really applicable)
set customer_id [im_company_internal]
set provider_id $user_id
set template_id ""
set payment_days "30"
set cost_status [im_cost_status_created]
set cost_type_id [im_cost_type_expense_item]
set tax "0"

if {![info exists reimbursable]} { set reimbursable 100 }
if {![info exists expense_date]} { set expense_date $today }
if {![info exists billable_p]} { set billable_p "f" }
if {![info exists expense_payment_type_id]} { set expense_payment_type_id [im_expense_payment_type_cash] }
if {![info exists currency]} { set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"] }

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

# Default project_id
if {"" == $project_id} {
    set project_id [db_string pid "
	select project_id from (
		select	count(*) as cnt,
			project_id
		from	im_costs c,
			im_expenses e,
			acs_objects o
		where	c.cost_id = e.expense_id and
			c.cost_id = o.object_id and
			o.creation_date > now()::date -15
		group by project_id
		order by cnt DESC
	) c
	LIMIT 1
    " -default ""]
}

set form_html ""

for {set i 0} {$i < 20} {incr i} {

    append form_html "
	<tr>
	<td>[expr $i+1]</td>
	<td>[im_select -ad_form_option_list_style_p 1 -translate_p 0 project_id.$i $project_options $project_id]</td>
	<td><input type=input name=expense_amount.$i size=8></td>
	<td>[im_select -ad_form_option_list_style_p 1 -translate_p 1 currency.$i $currency_options $default_currency]</td>
    "

    if {!$auto_vat_p} {	
	append form_html "<td><input type=input name=vat.$i size=5></td>\n"
    }

    append form_html "
	<td><input type=input name=expense_date.$i size=10 value=$this_year></td>
	<td><input type=input name=external_company_name.$i size=20 value=''></td>
	<td>[im_select -ad_form_option_list_style_p 1 -translate_p 1 -package_key intranet-expenses expense_type_id.$i $expense_type_options ""]</td>
	<td>[im_select -ad_form_option_list_style_p 1 -translate_p 1 -package_key intranet-expenses billable_p.$i $expense_billable_options "f"]</td>
	<td>[im_select -ad_form_option_list_style_p 1 -translate_p 1 -package_key intranet-expenses expense_payment_type_id.$i $expense_payment_type_options ""]</td>
        <td><input type=input name=receipt_reference.$i size=20 value=''></td>
	<td><input type=input name=note.$i size=20 value=''></td>
	</tr>
    "
}
