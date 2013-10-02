# /packages/intranet-events/www/order-item-update.tcl
#
# Copyright (c) 1998-2008 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@event-open.com
} {
    event_id:integer
    return_url
    { order_item_units:array,integer,optional }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_event_permissions $current_user_id $event_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You don't have the right to modify this event"
    ad_script_abort
}

foreach invoice_item_id [array names order_item_units] {
    set amount $order_item_units($invoice_item_id)
    db_dml update_order_amount "
		update im_event_order_item_rels
		set order_item_amount = :amount
		where	event_id = :event_id and
			order_item_id = :invoice_item_id
    "
}


ad_returnredirect $return_url
