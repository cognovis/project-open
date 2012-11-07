# /packages/intranet-invoices/www/delete.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Delete a single invoice

    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet-invoices/list" }
    invoice_id:integer
}

set cost_id $invoice_id

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_invoices]} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

# Need to go through object type, because we may
# have to delete a "translation invoice", which
# requires different cleanup then "im_invoice".
#
set otype [db_string object_type "select object_type from acs_objects where object_id=:invoice_id"]

db_1row type_and_status "select cost_type_id, cost_status_id from im_costs where cost_id = :cost_id"

im_audit -object_type "$otype" -object_id $invoice_id -status_id $cost_status_id -type_id $cost_type_id -action before_delete

# Delete rels
set rel_ids [db_list rels "select rel_id from acs_rels where object_id_one = :cost_id or object_id_two = :cost_id"]
foreach rel_id $rel_ids {
    db_string delete_rel "select acs_rel__delete(:rel_id) from dual"
}

# Delete attached content items
set item_ids [db_list context "select object_id from acs_objects where context_id = :cost_id and object_type = 'content_item'"]
foreach item_id $item_ids {
    content::item::delete -item_id $item_id
}

db_string delete_cost_item ""

ad_returnredirect $return_url
return
