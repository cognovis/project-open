# /packages/intranet-events/www/participant-update.tcl
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
    { participant_status_id:array,integer,optional }
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

foreach participant_id [array names participant_status_id] {
    set status_id $participant_status_id($participant_id)
    db_dml update_order_amount "
		update im_biz_object_members
		set member_status_id = :status_id
		where rel_id in (
			   	select	rel_id
				from	acs_rels
				where	object_id_one = :event_id and
					object_id_two = :participant_id
			)
    "
}


ad_returnredirect $return_url
