# /packages/intranet-helpdesk/www/ticket-ticket-rel-del.tcl
#
# Copyright (c) 2003-2008 Project/Open
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
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]

foreach id $rel_id {

    set object_id_one 0
    set object_id_two 0
    db_0or1row rel_info "
	select	r.object_id_one,
		r.object_id_two
	from	acs_rels r,
		im_ticket_ticket_rels ttr
	where	r.rel_id = ttr.rel_id
		and r.rel_id = :id
    "

    set del_p 0
    im_ticket_permissions $current_user_id $object_id_one view read write admin
    if {$write} { set del_p 1 }
    im_ticket_permissions $current_user_id $object_id_two view read write admin
    if {$write} { set del_p 1 }

    if {!$del_p} {
	ad_return_complaint 1 "Unsufficient Permissions:<br>You don't have sufficient
 	permissions to delete the relationship between objects: $object_id_one - $object_id_two"
	ad_script_abort
    }

    db_string del_ticket_ticket_rel "select im_ticket_ticket_rel__delete(:id)"

}

template::forward $return_url
