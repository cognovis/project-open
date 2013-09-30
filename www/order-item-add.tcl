# /packages/intranet-events/www/order-item-add.tcl
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
    order_item_id:integer,multiple
    return_url
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

foreach oi $order_item_id {
    set exists_p [db_string rel_exists "select count(*) from im_event_order_item_rels where event_id = :event_id and order_item_id = :oi"]
    if {!$exists_p} {
	db_dml create_rel "
	insert into im_event_order_item_rels
	(event_id, order_item_id) values 
	(:event_id, :oi)
        "
    }
}

ad_returnredirect $return_url
