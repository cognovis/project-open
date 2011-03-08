# /packages/intranet-invoices/www/new-2.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Saves invoice changes and set the invoice status to "Created".<br>
    Please note that there are different forms to create invoices for
    example in the intranet-trans-invoicing module of the 
    intranet-server-hosting module.
    @author frank.bergmann@project-open.com
} {
    item_name:array
    item_material_id:integer,array
    item_units:float,array
    item_uom_id:integer,array
    item_rate:float,array
    item_currency:array
    project_id:integer
    customer_id:integer
    invoice_id:integer
    { return_url "/intranet-invoices/" }
}

set cost_type_id [im_cost_type_estimation]
set invoice_nr [im_next_invoice_nr -cost_type_id $cost_type_id]
set cost_status_id [im_cost_status_created]

set auto_increment_invoice_nr_p [parameter::get -parameter InvoiceNrAutoIncrementP -package_id [im_package_invoices_id] -default 0]


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set provider_id [im_company_internal] 

# Does the invoice already exist?
set invoice_exists_p [db_string invoice_count "select count(*) from im_invoices where invoice_id=:invoice_id"]

if {!$invoice_exists_p} {

    # Let's create the new invoice
    set invoice_id [db_exec_plsql create_invoice ""]

    # Audit the creation of the invoice
    im_audit -object_id $invoice_id -action create

}



# Delete the old items if they exist
db_dml delete_invoice_items "
	DELETE from im_invoice_items
	WHERE invoice_id=:invoice_id
"

set item_list [array names item_name]
foreach nr $item_list {
    set name $item_name($nr)
    if {$name eq ""} {continue}
    set units $item_units($nr)
    set uom_id $item_uom_id($nr)
    set rate $item_rate($nr)
    set currency $item_currency($nr)
    set material_id $item_material_id($nr)

    set item_id [db_nextval "im_invoice_items_seq"]
    set insert_invoice_items_sql "
	INSERT INTO im_invoice_items (
		item_id, item_name, 
		project_id, invoice_id, 
		item_units, item_uom_id, 
		price_per_unit, currency, 
		sort_order,item_material_id
	) VALUES (
		:item_id, :name, 
		:project_id, :invoice_id, 
		:units, :uom_id, 
		:rate, :currency, 
		:nr,:material_id
	)"

    db_dml insert_invoice_items $insert_invoice_items_sql
}

im_invoice_update_rounded_amount \
    -invoice_id $invoice_id 

db_dml update_costs "
update im_costs
set
	project_id	= :project_id
where
	cost_id = :invoice_id
"

db_1row "get relations" "
		select	count(*) as v_rel_exists
                from    acs_rels
                where   object_id_one = :project_id
                        and object_id_two = :invoice_id
    "
if {0 ==  $v_rel_exists} {
    set rel_id [db_exec_plsql create_rel ""]
}


db_release_unused_handles
ad_returnredirect "/intranet-invoices/view?invoice_id=$invoice_id"
