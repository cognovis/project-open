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
	select	cust.company_name || ' - ' || c.cost_name || ' / ' || ii.sort_order || ' - ' || ii.item_name || ' (' || round(ii.item_units) || ')',
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
		ii.invoice_id = c.cost_id and
		c.cost_type_id = 3703
	order by
		cust.company_name,
		c.cost_name,
		ii.sort_order,
		ii.item_name
"]

# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set item_l10n [lang::message::lookup "" intranet-events.Item "Item"]
set order_l10n [lang::message::lookup "" intranet-events.Order "Order"]
set customer_l10n [lang::message::lookup "" intranet-events.Customer "Customer"]
set ordered_units_l10n [lang::message::lookup "" intranet-events.Ordered_Units "Ordered Units"]
set rueckerfasst_units_l10n [lang::message::lookup "" intranet-events.Rueckerfasst_Units "Rueckerfasst Units"]
set other_events_units_l10n [lang::message::lookup "" intranet-events.Other_Event_Units "Other Event Units"]

list::create \
    -name order_item_list \
    -multirow order_item_list_multirow \
    -key invoice_item_id \
    -orderby_name "order_item_orderby" \
    -no_data "No order items associated yet" \
    -elements {
        item_id {

	}
	company_name { 
	    label $customer_l10n
	    link_url_col customer_url
	}
	cost_name { 
	    label $order_l10n 
	    link_url_col order_item_url
	}
	item_name { 
	    label $item_l10n
	    link_url_col order_item_url
	}
	item_units {
	    label $ordered_units_l10n
	}
	rueckerfasst_units {
	    label $rueckerfasst_units_l10n
	}
	other_events_units {
	    label $other_events_units_l10n
	}
	order_item_units { 
	    label "Planned Units" 
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
	plugin_id {}
	view_name {}
    }


db_multirow -extend {order_item_url customer_url delete_url} order_item_list_multirow get_order_items "
	select	*,
                (       select  sum(item_units)
                        from    im_costs rc,
				im_invoice_items rii
                        where   rc.cost_id = rii.invoice_id and
				rc.cost_type_id = 3791 and
				rii.nav_order_item_id = ii.item_id
		) as rueckerfasst_units,
		(	-- sum up the assignments of the order item in all other events
			select	sum(oeoir.order_item_amount)
			from	im_events oe,
				im_event_order_item_rels oeoir
			where	oeoir.order_item_id = ii.item_id and
				oeoir.event_id = oe.event_id and
				oe.event_id != :event_id
		) as other_events_units
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

