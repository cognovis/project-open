# /packages/intranet-trans-invoices/www/new-4.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Save invoice changes and set the invoice status to "Created"
    or higher.
    @author frank.bergmann@project-open.com
} {
    invoice_id:integer
    { customer_id:integer 0 }
    { provider_id:integer 0 }
    invoice_nr
    invoice_date
    { invoice_type_id 700 }
    payment_days:integer
    payment_method_id:integer
    invoice_template_id:integer
    vat
    tax

    include_task:multiple

    item_sort_order:array
    item_name:array
    item_units:array
    item_uom_id:integer,array
    item_type_id:integer,array
    item_project_id:integer,array
    item_rate:array
    item_currency:array
    { return_url "/intranet-invoices/" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

set invoice_status_created [db_string invoice_status "select invoice_status_id from im_invoice_status where upper(invoice_status)='CREATED'"]

set invoice_status_in_process [db_string invoice_status "select category_id from im_categories where category_type='Intranet Invoice Status' and upper(category)='IN PROCESS'"]

set project_status_invoiced [db_string project_status "select category_id from im_categories where category_type='Intranet Project Status' and upper(category)='INVOICED'"]

set customer_internal [db_string customer_internal "select customer_id from im_customers where lower(customer_path) = 'internal'" -default 0]
if {!$customer_internal} {
    ad_return_complaint 1 "<li>Unable to find 'Internal' customer with path 'internal'. <br>Maybe somebody has change the path of the customer?"    
    return
}

set invoice_status_id $invoice_status_created

if {!$provider_id} { set provider_id $customer_internal }
if {!$customer_id} { set customer_id $customer_internal }

# Build the list of selected tasks ready for invoicing
set in_clause_list [list]
foreach selected_task $include_task {
    lappend in_clause_list $selected_task
}
set tasks_where_clause "task_id in ([join $in_clause_list ","])"

# ---------------------------------------------------------------
# Create the new invoice
# ---------------------------------------------------------------

    
    # Now we get into trouble:
    # Creating a new new invoice we have to:
    # - Mark im_trans_task and im_invoicable_items with the new invoice_id

    # Let's create the new invoice first
    set create_invoice_sql "
INSERT INTO im_invoices (
	invoice_id, 
	invoice_nr,
	customer_id, 
	provider_id, 
	invoice_date,
	payment_days,
	payment_method_id,
	invoice_template_id,
	vat,
	tax,
	invoice_status_id, 
	invoice_type_id, 
	last_modified, 
	last_modifying_user, 
	modified_ip_address
) VALUES (
	:invoice_id, 
	:invoice_nr,
	:customer_id, 
	:provider_id, 
	:invoice_date,
	:payment_days,
	:payment_method_id,
	:invoice_template_id,
	:vat,
	:tax,
	:invoice_status_created, 
	:invoice_type_id, 
	sysdate,
	:user_id,
	'[ad_conn peeraddr]'
)"


    # Tag the im_trans_tasks to be invoices with "invoice_id", marking
    # them as invoiced.
    #
    set update_trans_tasks_sql "
	UPDATE	im_trans_tasks t 
	SET	invoice_id = :invoice_id
	WHERE	$tasks_where_clause
    "

    # set all invoiced projects (=projects contained in this invoice)
    # to "invoiced", except those that still contain atleast one im_trans_task
    # that has not been invoiced yet (invoice_id is null)
    #
    set update_project_to_invoiced_sql "
        UPDATE im_projects
        SET project_status_id=:project_status_invoiced
        WHERE project_id IN (
                SELECT
                        r.object_id_one
                FROM
                        acs_rels r
                WHERE
                        r.object_id_two = :invoice_id
                        and r.object_id_one not in (
                                select distinct
                                        p.project_id
                                from
                                        acs_rels r,
                                        im_projects p,
                                        im_trans_tasks t
                                where
                                        r.object_id_two = :invoice_id
                                        and r.object_id_one = p.project_id
                                        and p.project_id = t.project_id
                                        and (t.invoice_id is null)
                        )
        )
    "

    # Check if one of the items is already invoiced    
    # This should never happend, but in this case we would loose
    # real money, so we double check here:
    set already_invoiced_tasks [db_string already_invoiced_tasks "
	SELECT	count(*)
	FROM	im_trans_tasks t
	WHERE	t.invoice_id is not null
		and $tasks_where_clause
    "]
    if {$already_invoiced_tasks > 0} {
        ad_return_complaint 1 "<li>System inconsistency found:<BR>
            We have found altleast on translation task that has already
            been invoiced. Maybe there is somebody else in the system
            trying to invoice the same project as you?"
        return
    }


    db_transaction {
	db_dml create_invoice $create_invoice_sql
	db_dml update_trans_tasks $update_trans_tasks_sql
	db_dml update_project_to_invoiced $update_project_to_invoiced_sql
    }


# ---------------------------------------------------------------
# Update the im_invoice_items
# ---------------------------------------------------------------

    # Delete the old items
    db_dml delete_invoice_items "
	DELETE from im_invoice_items
	WHERE invoice_id=:invoice_id
    "

set item_list [array names item_name]
foreach nr $item_list {
    set name $item_name($nr)
    set units $item_units($nr)
    set uom_id $item_uom_id($nr)
    set type_id $item_type_id($nr)
    set project_id $item_project_id($nr)
    set rate $item_rate($nr)
    set currency $item_currency($nr)
    set sort_order $item_sort_order($nr)
    ns_log Notice "item($nr, $name, $units, $uom_id, $project_id, $rate, $currency)"

    # Insert only if it's not an empty line from the edit screen
    if {!("" == [string trim $name] && (0 == $units || "" == $units))} {
	set item_id [db_nextval "im_invoice_items_seq"]
	set insert_invoice_items_sql "
INSERT INTO im_invoice_items (
	item_id, item_name, project_id, invoice_id, item_units, item_uom_id, 
	price_per_unit, currency, sort_order, item_type_id, item_status_id, description
) VALUES (
	:item_id, :name, :project_id, :invoice_id, :units, :uom_id, 
	:rate, :currency, :sort_order, :type_id, null, ''
)"

        db_dml insert_invoice_items $insert_invoice_items_sql
    }
}

db_release_unused_handles
ad_returnredirect "/intranet-invoices/view?invoice_id=$invoice_id"
