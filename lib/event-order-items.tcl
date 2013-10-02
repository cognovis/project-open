# /intranet-events/lib/event-order-items.tcl
#
# Variables from calling procedure:
# 	event_id
#	return_url

# ******************************************************
# Default & Security
# ******************************************************

set current_user_id [ad_maybe_redirect_for_registration]
im_event_permissions $current_user_id $event_id view read write admin
if {!$read} { return }

set current_url [im_url_with_query]
set form_mode "display"

# ******************************************************
# Order Items for Customer
# ******************************************************

set order_item_options [db_list_of_lists order_items "
	select	
		cust.company_name || ' / ' || c.cost_name || ' / ' || ii.item_name,
		ii.item_id
	from	im_events e,
		acs_rels ecr,
		im_event_customer_rels iecr,
		im_companies cust,
		im_costs c,
		im_invoice_items ii
	where	e.event_id = :event_id and
		ecr.rel_id = iecr.rel_id and
		ecr.object_id_one = e.event_id and
		ecr.object_id_two = cust.company_id and
		c.customer_id = cust.company_id and
		ii.invoice_id = c.cost_id
	order by
		cust.company_name,
		c.cost_name,
		ii.item_name
"]

# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

list::create \
    -name order_item_list \
    -multirow order_item_list_multirow \
    -key invoice_item_id \
    -no_data "No order items associated yet" \
    -elements {
	company_name { 
	    label "Customer" 
	    link_url_col customer_url
	}
	cost_name { 
	    label "Order" 
	    link_url_col order_item_url
	}
	item_name { 
	    label "Item" 
	    link_url_col order_item_url
	}
	order_item_units { 
	    label "Units" 
	    display_template {
		<input type=textbox size=5 name=order_item_units.@order_item_list_multirow.item_id@ value="@order_item_list_multirow.order_item_amount@">
	    }
	}
	delete {
	    label ""
	    display_template {
		<a href="@order_item_list_multirow.delete_url@" class="button">#acs-kernel.common_Delete#</a>
	    }
	}
    } \
    -orderby {
	orderby {orderby cost_name}
	cost_name {orderby cost_name}
	item_name {orderby item_name}
    } \
    -filters {
	form_mode {}
	event_id {}
    }


db_multirow -extend {order_item_url customer_url delete_url} order_item_list_multirow get_order_items "
	select	*
	from	im_companies cust,
		im_invoice_items ii,
		im_costs c,
		im_event_order_item_rels eoir
	where	ii.invoice_id = c.cost_id and
		c.customer_id = cust.company_id and
		eoir.event_id = :event_id and
		eoir.order_item_id = ii.item_id
	[template::list::orderby_clause -name order_item_list -orderby]
" {
    set delete_url [export_vars -base "order-item-del" { event_id {item_id $item_id} {return_url $current_url} }]
    set customer_url [export_vars -base "/intranet/companies/view" { {company_id $customer_id} {return_url $current_url} }]
    set order_item_url [export_vars -base "/intranet-invoices/view" { invoice_id {return_url $current_url} }]
}


# Set the variable for the ADP page
# set return_url $current_url

