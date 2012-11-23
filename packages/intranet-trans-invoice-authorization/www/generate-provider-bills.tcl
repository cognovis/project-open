# /packages/intranet-trans-invoice-authorization/www/generate-provider-bills.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a number of provider bills as a confirmation token for providers.
    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    invoice_item_id:integer,multiple,optional
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_name [im_name_from_user_id [ad_get_user_id]]

# Make sure task contains at least one number.
# Otherwise we would get a syntax error further below in the SQL.
if {![info exists invoice_item_id]} { set invoice_item_id {} }
if {"" == $invoice_item_id} { set invoice_item_id 0 }


set base_sql "
	select
		prov.company_id as provider_id,
		prov.company_name as provider_name,
		child.project_id as child_project_id,
		child.project_nr as child_project_nr,
		c.cost_id as po_id,
		c.cost_nr as po_nr,
		c.cost_name as po_name,
		c.currency as po_currency,
		tt.*,
		ii.*,
		ii.item_id as po_item_id,
		im_category_from_id(tt.task_status_id) as task_status,
		im_category_from_id(tt.task_type_id) as task_type,
		im_category_from_id(tt.source_language_id) as source_language,
		im_category_from_id(tt.target_language_id) as target_language,
		im_category_from_id(tt.task_uom_id) as task_uom
	from
		im_projects parent,
		im_projects child,
		im_trans_tasks tt,
		im_invoice_items ii,
		im_costs c,
		im_invoices i,
		im_companies prov
	where
		parent.parent_id is null
		and child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.project_status_id not in ([im_project_status_deleted])
		and child.project_status_id not in ([im_project_status_deleted])
		and child.project_id = tt.project_id
		and tt.task_id = ii.task_id
		and ii.invoice_id = i.invoice_id
		and ii.item_id in ([join $invoice_item_id ","])
		and i.invoice_id = c.cost_id
		and c.provider_id = prov.company_id
		and c.cost_type_id = [im_cost_type_po]
	order by
		po_currency,
		provider_name,
		child.project_nr,
		c.cost_name,
		parent.project_nr,
		child.tree_sortkey
"

# -----------------------------------------------------------
# Get the list of providers into a list.
# This is necessary because we want to iterate through the providers
# to generate a single Provider Bill per provider.
#
set provider_sql "
	select	distinct po_currency as currency,
		provider_id
	from	($base_sql) t
"
set provider_list [db_list_of_lists provider_list $provider_sql]


# -----------------------------------------------------------
# Loop through the providers and generate a Provider Bill
# for all selected tasks.
foreach tuple $provider_list {
    set bill_currency [lindex $tuple 0]
    set bill_provider_id [lindex $tuple 1]

    # Get default tax + vat from provider file
    set company_info_sql "
	select	default_vat,
		default_tax,
		default_payment_days,
		default_bill_template_id,
		default_payment_method_id
	from	im_companies 
	where	company_id = :bill_provider_id
    "
    db_1row company_info $company_info_sql

    
    # Create a new "container" object of type im_invoice to represent the provider bill.
    set cost_center_id ""
    set invoice_nr [im_next_invoice_nr -cost_type_id [im_cost_type_bill] -cost_center_id $cost_center_id]
    set template_id $default_bill_template_id
    set payment_method_id $default_payment_method_id
    set payment_days $default_payment_days
    set vat $default_vat
    if {"" == $vat} { set vat 0.0 }
    set tax $default_tax
    if {"" == $tax} { set tax 0.0 }

    set note "Automatically generated using \]po\[ Invoice Authentication Wizard"
    set provider_bill_id [db_string new_bill "select im_invoice__new (
		null,				-- invoice_id
		'im_invoice',			-- object_type
		now(),				-- creation_date 
		:user_id,			-- creation_user
		'[ad_conn peeraddr]',		-- creation_ip
		null,				-- context_id
		:invoice_nr,			-- invoice_nr
		[im_company_internal],		-- customer_id
		:bill_provider_id,		-- provider_id
		null,				-- company_contact_id
		now(),				-- invoice_date
		:bill_currency,			-- currency
		:template_id,			-- invoice_template_id
		[im_cost_status_created],	-- invoice_status_id
		[im_cost_type_bill],		-- invoice_type_id
		:payment_method_id,		-- payment_method_id
		:payment_days,			-- payment_days
		0,				-- amount
		:vat,				-- vat
		:tax,				-- tax
		:note				-- note
	    )
    "]

    # Add one line per task to the Provider Bill
    set line_sql "
		select	t.*
		from	($base_sql) t
		where	provider_id = :bill_provider_id and
			po_currency = :bill_currency
    "
    db_foreach bill_lines $line_sql {
	# Insert only if it's not an empty line from the edit screen
	set item_id [db_nextval "im_invoice_items_seq"]
	set item_name_with_prefix "$po_name - $item_name"
	set insert_invoice_items_sql "
			INSERT INTO im_invoice_items (
				item_id, item_name,
				project_id, invoice_id,
				item_units, item_uom_id,
				price_per_unit, currency,
				sort_order, item_type_id,
				item_material_id,
				item_status_id, description, task_id,
				created_from_item_id
			) VALUES (
				:item_id, :item_name_with_prefix,
				:project_id, :provider_bill_id,
				:item_units, :item_uom_id,
				:price_per_unit, :bill_currency,
				:sort_order, :item_type_id,
				:item_material_id,
				:item_status_id, :description, :task_id,
				:po_item_id
			)
	"

	db_dml insert_invoice_items $insert_invoice_items_sql
    }

    # Callback & Audit
    im_audit -object_type "im_invoice" -action after_create -object_id $provider_bill_id -status_id [im_cost_status_created] -type_id [im_cost_type_bill]

}


ad_returnredirect $return_url
