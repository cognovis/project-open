# /packages/intranet-planning/www/new-from-planning.tcl
#
# Copyright (C) 2003 - 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Create a new quote from planning information
    @author frank.bergmann@project-open.com
} {
    project_id:integer
    return_url
    { target_cost_type_id 3702 }
}

# ---------------------------------------------------------------
# Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."
    ad_script_abort
}

# ---------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------

set tax_format [im_l10n_sql_currency_format -style simple]
set vat_format [im_l10n_sql_currency_format -style simple]
set price_per_unit_format [im_l10n_sql_currency_format -style simple]
set date_format [im_l10n_sql_date_format -style simple]

set todays_date [db_string get_today "select now()::date"]
set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set required_field "<font color=red size=+1><B>*</B></font>"

# Should we show a "Material" field for invoice lines?
# set material_enabled_p [ad_parameter -package_id [im_package_invoices_id] "ShowInvoiceItemMaterialFieldP" "" 0]
set material_enabled_p 0
# set project_type_enabled_p [ad_parameter -package_id [im_package_invoices_id] "ShowInvoiceItemProjectTypeFieldP" "" 1]
set project_type_enabled_p 0

set default_material_id [im_material_default_material_id]
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

# ---------------------------------------------------------------
# Get base information
# ---------------------------------------------------------------

# Use today's date as effective date
set effective_date $todays_date

db_1row project_info "
	select	p.*,
		c.company_id as customer_id,
		c.company_name as customer_name,
		c.main_office_id as invoice_office_id,
		c.default_vat as vat,
		c.default_tax as tax,
		c.default_payment_method_id as payment_method_id,
		c.default_payment_days as payment_days
	from	im_projects p,
		im_companies c
	where	p.project_id = :project_id and
		p.company_id = c.company_id
"

set provider_id [im_company_internal]

# Default for template: Get it from the company
set template_id [im_invoices_default_company_template $target_cost_type_id $company_id]

# Invoice Nr.
set new_invoice_id [im_new_object_id]
set invoice_nr [im_next_invoice_nr -cost_type_id $target_cost_type_id]

# The list of associated projects
set select_project $project_id

set cost_note [lang::message::lookup "" intranet-planning.Automatically_created_from_planning_date "Automatically created from planning data"]

# ---------------------------------------------------------------
# Determine whether it's an Invoice or a Bill
# ---------------------------------------------------------------

set invoice_mode "[_ intranet-invoices.clone]"
set page_title [lang::message::lookup "" intranet-planning.New_quote_from_planning_data "New Quote from planning data"]
set button_text [_ intranet-invoices.Submit]
set context_bar [im_context_bar [list /intranet/invoices/ "Finance"] $page_title]

set invoice_address_label [lang::message::lookup "" intranet-invoices.Invoice_Address "Address"]
set invoice_address_select [im_company_office_select invoice_office_id $invoice_office_id $company_id]

set contact_select [im_company_contact_select company_contact_id $company_contact_id $company_id]

set target_cost_type [im_category_from_id $target_cost_type_id]
set cost_status_id [im_cost_status_created]
set cost_center_id ""
set cost_center_label [lang::message::lookup "" intranet-invoices.Cost_Center "Cost Center"]
set cost_center_select [im_cost_center_select -include_empty 1 -department_only_p 0 cost_center_id $cost_center_id $target_cost_type_id]



# ---------------------------------------------------------------
# Calculate the selects for the ADP page
# ---------------------------------------------------------------

set customer_select [im_company_select customer_id $customer_id "" "CustOrIntl"]
set provider_select [im_company_select provider_id $provider_id "" "Provider"]

set company_type [_ intranet-core.Customer]
set company_select $customer_select

set payment_method_select [im_invoice_payment_method_select payment_method_id $payment_method_id]
set template_select [im_cost_template_select template_id $template_id]
set status_select [im_cost_status_select cost_status_id $cost_status_id]

# Type_select doesnt allow for options anymore...
# set type_select [im_cost_type_select cost_type_id $target_cost_type_id 0 "financial_doc"]
#
set type_select "
        <input type=hidden name=cost_type_id value=$target_cost_type_id>
        $target_cost_type
"


# ---------------------------------------------------------------
# Select and format the sum of the invoicable items
# ---------------------------------------------------------------

set line_sql "
	select	t.*
	from	(
		select	pi.*,
			pi.item_value as item_units,
			(select hourly_cost from im_employees where employee_id = pi.item_project_member_id) as price_per_unit,
			:default_currency as currency,
			[im_uom_unit] as item_uom_id,
			:default_material_id as item_material_id,
			null as item_type_id,
			1 as sort_order
		from	im_planning_items pi
		where	item_object_id = :project_id and
			pi.item_cost_type_id = [im_cost_type_timesheet_hours]
		UNION
		select	pi.*,
			1.0 as item_units,
			pi.item_value as price_per_unit,
			:default_currency as currency,
			[im_uom_unit] as item_uom_id,
			:default_material_id as item_material_id,
			null as item_type_id,
			2 as sort_order
		from	im_planning_items pi
		where	item_object_id = :project_id and
			pi.item_cost_type_id = [im_cost_type_expense_bundle]
	) t
	order by
		sort_order,
		item_cost_type_id DESC,
		lower(im_name_from_user_id(item_project_member_id))
"

set ctr 1
set old_project_id 0
set colspan 6
set target_language_id ""
set task_sum_html ""
db_foreach quote_lines $line_sql {
    set task_id $ctr
    set item_name [lang::message::lookup "" intranet-planning.Cost_type_for_user "[im_category_from_id $item_cost_type_id] for [im_name_from_user_id $item_project_member_id]"]
    append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])> 
          <td>
	    <input type=text name=item_sort_order.$ctr size=2 value='$ctr'>
	  </td>
          <td>
	    <input type=text name=item_name.$ctr size=40 value='[ns_quotehtml $item_name]'>
	  </td>
    "
    append task_sum_html "<input type=hidden name=item_task_id.$ctr value='$task_id'>"

    if {$material_enabled_p} {
	append task_sum_html "<td>[im_material_select item_material_id.$ctr $item_material_id]</td>"
    } else {
	append task_sum_html "<input type=hidden name=item_material_id.$ctr value='$item_material_id'>"
    }
    
    if {$project_type_enabled_p} {
	append task_sum_html "<td>[im_category_select "Intranet Project Type" item_type_id.$ctr $item_type_id]</td>"
    } else {
	append task_sum_html "<input type=hidden name=item_type_id.$ctr value='$item_type_id'>"
    }

    append task_sum_html "
          <td align=right>
	    <input type=text name=item_units.$ctr size=4 value='$item_units'>
	  </td>
          <td align=right>
            [im_category_select "Intranet UoM" item_uom_id.$ctr $item_uom_id]
	  </td>
          <td align=right><nobr>
	    <input type=text name=item_rate.$ctr size=3 value='$price_per_unit'>
	    <input type=hidden name=item_currency.$ctr value='$currency'>
	    $currency
	  </nobr></td>
        </tr>
	<input type=hidden name=item_project_id.$ctr value='$project_id'>
"
    incr ctr
}


# ---------------------------------------------------------------
# NavBars
# ---------------------------------------------------------------

set sub_navbar_html [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list]]

