# /packages/intranet-timesheet2-invoices/www/new-3.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Receives the list of tasks to invoice and creates an invoice form
    similar to /intranet-invoicing/www/new in order to create a new
    invoice.<br>
    @param include_task A list of im_timesheet_task IDs to include in the
           new invoice
    @param company_id All include_tasks need to be from the same
           company.
    @param invoice_currency: EUR or USD

    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {
    include_task:multiple
    company_id:integer
    invoice_currency
    { invoice_hour_type "reported" }
    select_project
    start_date
    end_date
    { cost_center_id:integer 0}
    target_cost_type_id:integer
    { return_url ""}
    { aggregate_tasks_p "0" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set org_company_id $company_id

set number_format "99990.099"
set date_format "YYYY-MM-DD"
set cost_type_invoice [im_cost_type_invoice]
set target_cost_type [im_category_from_id $target_cost_type_id]
set target_cost_type_mangle [lang::util::suggest_key $target_cost_type]

set invoicing_start_date $start_date
set invoicing_end_date $end_date

if {"" == $return_url} {set return_url [im_url_with_query] }
set todays_date [db_string get_today "select to_char(now(), :date_format)"]
set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set required_field "<font color=red size=+1><B>*</B></font>"

if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "[_ intranet-timesheet2-invoices.lt_Insufficient_Privileg]" "
    <li>[_ intranet-timesheet2-invoices.lt_You_dont_have_suffici]"    
}

set allowed_cost_type [im_cost_type_write_permissions $user_id]
if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type \#$target_cost_type_id."
    ad_script_abort
}

set price_calculation_standard_p 1
set price_calculation_base [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2-invoices] -parameter "PriceCalculationBase" -default "CustomerPriceList"]
if { "CustomerPriceList"!=$price_calculation_base } {set price_calculation_standard_p 0}


# ---------------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------------

# Choose the right subnavigation bar
#
if {[llength $select_project] != 1} {
    set sub_navbar [im_costs_navbar "none" "/intranet/invoicing/index" "" "" [list]]
} else {
    set project_id [lindex $select_project 0]
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set menu_label "project_finance"
    set sub_navbar [im_sub_navbar \
			-components \
			-base_url "/intranet/projects/view?project_id=$project_id" \
			$parent_menu_id \
			$bind_vars "" "pagedesriptionbar" $menu_label]
}


# ---------------------------------------------------------------
# Gather invoice data
# ---------------------------------------------------------------

# Build the list of selected tasks ready for invoicing
set in_clause_list [list]
foreach selected_task $include_task {
    lappend in_clause_list $selected_task
}
set tasks_where_clause [join $in_clause_list ","]

# We already know that all tasks are from the same company,
# and we asume that the company_id is set from new-2.tcl.

if { [catch {
    db_1row invoices_info_query ""
} err_msg] } {
    ad_return_complaint 1 [lang::message::lookup "" intranet-timesheet2-invoices.Company_not_found "We didn't find any information about company\# %company_id%."]
}


# Default for cost-centers - take the user's
# dept from HR.
if {0 == $cost_center_id} {
    set cost_center_id [im_costs_default_cost_center_for_user $user_id]
}

set cost_center_label [lang::message::lookup "" intranet-invoices.Cost_Center "Cost Center"]
set cost_center_select [im_cost_center_select -include_empty 1 -department_only_p 0 cost_center_id $cost_center_id $target_cost_type_id]


set default_material_id [im_material_default_material_id]
set default_material_name [db_string matname "select acs_object__name(:default_material_id)"]
set default_uom_id [db_string default_uom "select material_uom_id from im_materials where material_id = :default_material_id"]

# ---------------------------------------------------------------
# Determine the contact for the invoice

 set contact_ids [db_list contact_ids "
         select distinct
 		company_contact_id
 	from	im_timesheet_tasks t,
 		im_projects p
 	where	t.task_id = p.project_id and 
 		p.project_id in ($tasks_where_clause)
 "]

if {[llength $contact_ids] > 0} {
    set company_contact_id [lindex $contact_ids 0]
} else {
    set company_contact_id $accounting_contact_id
}

db_1row accounting_contact_info "
    select
        im_name_from_user_id(:company_contact_id) as company_contact_name,
        im_email_from_user_id(:company_contact_id) as company_contact_email
"

set invoice_office_id [db_string company_main_office_info "
	select	main_office_id 
	from	im_companies
	where	company_id = :org_company_id
" -default ""]


# ---------------------------------------------------------------
# Create the default values for a new invoice.
#
# Calculate the next invoice number by calculating the maximum of
# the "reasonably build numbers" currently available

set button_text [lang::message::lookup "" intranet-timesheet2-invoices.Create_$target_cost_type_mangle "Create %target_cost_type%"]
set page_title [lang::message::lookup "" intranet-timesheet2-invoices.New_$target_cost_type_mangle "New %target_cost_type%"]

set context_bar [im_context_bar [list /intranet/invoices/ "[_ intranet-timesheet2-invoices.Invoices]"] $page_title]
set invoice_id [im_new_object_id]
set invoice_nr [im_next_invoice_nr -cost_type_id $target_cost_type_id -cost_center_id $cost_center_id]
set invoice_date $todays_date
set provider_id [im_company_internal]
set customer_id $company_id
set cost_type_id $target_cost_type_id
set cost_status_id [im_cost_status_created]

set note ""
set default_vat 0
set default_tax 0
set default_payment_method_id ""
set default_template_id ""
set default_payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultCompanyInvoicePaymentDays" "" 30] 

# Should we show a "Material" field for invoice lines?
set material_enabled_p [ad_parameter -package_id [im_package_invoices_id] "ShowInvoiceItemMaterialFieldP" "" 0]
set project_type_enabled_p [ad_parameter -package_id [im_package_invoices_id] "ShowInvoiceItemProjectTypeFieldP" "" 1]

# Should we show the "Tax" field?
set tax_enabled_p [ad_parameter -package_id [im_package_invoices_id] "EnabledInvoiceTaxFieldP" "" 1]

if {[info exists customer_id]} {
    db_0or1row customer_info "
    	select	default_vat,
		default_payment_method_id,
		coalesce(default_payment_days, 0) as default_payment_days,
		default_invoice_template_id,
		default_bill_template_id,
		default_po_template_id,
		default_delnote_template_id
	from	im_companies where company_id = :customer_id
    "
}

switch $target_cost_type_id {
    3700 { set default_template_id $default_invoice_template_id }
    3704 { set default_template_id $default_bill_template_id }
    3706 { set default_template_id $default_po_template_id }
    3724 { set default_template_id $default_delnote_template_id }
}

set due_date [db_string get_due_date "select to_date(to_char(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD') + $default_payment_days from dual"]


# ---------------------------------------------------------------
# 7. Select and format the sum of the invoicable items
# for a new invoice
# ---------------------------------------------------------------

# start formatting the list of sums with the header...
set task_sum_html "
        <tr align=center> 
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Order]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Description]</td>
"

if {$project_type_enabled_p} {
    append task_sum_html "<td class=rowtitle>[lang::message::lookup "" intranet-invoices.Type "Type"]</td>"
}

append task_sum_html "
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Units]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.UOM]</td>
          <td class=rowtitle>[_ intranet-timesheet2-invoices.Rate]</td>
        </tr>
"

# Start formatting the "reference price list" as well, even though it's going
# to be shown at the very bottom of the page.
#
set price_colspan 11
set ctr 1
set old_project_id 0
set colspan 6
set flag 0 

# ad_return_complaint 1 [concat $invoicing_start_date "" $invoicing_end_date ]
# ad_return_complaint 1 $in_clause_list

foreach project_id $in_clause_list {	
    
	set project_name [db_string get_project_name "select project_name from im_projects where project_id=$project_id"]
        append task_sum_html "
	        <tr>\n
		  <td class=rowtitle colspan=$price_colspan>
                  <a href=/intranet/projects/view?project_id=$project_id>$project_name</a>
                </td></tr>\n
	"
	set user_sql "
		select
               		sum(h.hours) as sum_hours,
			h.user_id,
        		(select im_name_from_id(h.user_id)) as user_name,
			(select company_id from im_projects where project_id = $project_id) as customer_id
	        from
        	        im_hours h
	        where
        	        h.project_id = $project_id
                	and h.day >= to_timestamp('$invoicing_start_date', 'YYYY-MM-DD')
	                and h.day < to_timestamp('$invoicing_end_date', 'YYYY-MM-DD')
        	group by
                	h.user_id
	"
	
	db_foreach users_in_group $user_sql {
	     set hourly_rate [find_sales_price $user_id $project_id $customer_id ""]
	     append task_sum_html "
                <tr>\n
          		<td colspan='1'><input type=text name=item_sort_order.$ctr size=2 value='$ctr'></td>
			<td colspan='1'><A href=/intranet/users/view?user_id=$user_id>$user_name</A></td>\n
			<td colspan='1' align=right><input size=3 type=text name='sum_hours.$ctr' value='$sum_hours'></td>\n
			<td colspan='1' align=right>Stunden</td>\n
			<td colspan='1' align=right><input size=3 type=text name='hourly_rate.$ctr' value='$hourly_rate'>\n
			<input type=hidden name='item_name.$ctr' value='$user_name'>\n
			<input type=hidden name='item_units.$ctr' value='$sum_hours'>\n
			<input type=hidden name='item_rate.$ctr' value='$hourly_rate'>\n
			<input type=hidden name='item_currency.$ctr' value='EUR'>\n
			</td>\n
		</tr>\n
	     "
	     incr ctr
	     set flag 1 
	}
	if { $flag } { set flag 0 } else { incr ctr }
}

append task_sum_html "<input type=hidden name='project_id' value='$select_project'><input type=hidden name='uom_id' value='320'>"
foreach task_id $in_clause_list {
    append task_sum_html "<input type=hidden name=include_task value=$task_id>\n"
}

set include_task_html ""
set start_date $invoicing_start_date
set end_date $invoicing_end_date
set reference_price_html ""
ad_return_template

