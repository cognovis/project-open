# /packages/intranet-helpdesk/www/associate-delete.tcl
#
# Copyright (c) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Delete rel_ids from im_ticket_ticket_rel

    @author frank.bergmann@project-open.com
} {
    { rel_id:multiple {} }
    { ticket_id:integer "" }
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]


# Check permission on "ticket_id".
# The SQL below only selects relationships associated with ticket_id.
im_ticket_permissions $current_user_id $ticket_id view read write admin
if {!$write} { ad_return_complaint 1 "Insufficient Permissions on ticket #$ticket_id" }


foreach id $rel_id {

    set object_id_one 0
    set object_id_two 0
    db_0or1row rel_info "
	select	r.object_id_one,
		r.object_id_two
	from	acs_rels r
	where	r.rel_id = :id and
		(r.object_id_one = :ticket_id OR r.object_id_two = :ticket_id)
    "

    db_string rel_delete "select acs_rel__delete(:id)"

}

template::forward $return_url
