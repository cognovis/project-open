# /packages/intranet-release-mgmt/www/save-items.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new release item to a project

    @author frank.bergmann@project-open.com
} {
    release_project_id:integer
    release_status_id:integer,array
    release_sort_order:array
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]

im_project_permissions $user_id $release_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

foreach item_id [array names release_status_id] {

    if {[info exists release_sort_order($item_id)]} {
	set sort_order $release_sort_order($item_id)
	db_dml update_sort_order "
		update	im_release_items set
			sort_order = :sort_order
		where rel_id in (
			select	r.rel_id
			from	acs_rels r,
				im_release_items i
			where	r.rel_id = i.rel_id
				and r.object_id_one = :release_project_id
				and r.object_id_two = :item_id
		)
	"
    }

    set status_id $release_status_id($item_id)

    set old_status_id [db_string old_status_id "
	select	release_status_id
	from	acs_rels r,
		im_release_items i
	where	r.rel_id = i.rel_id
		and r.object_id_one = :release_project_id
		and r.object_id_two = :item_id
    " -default ""]

    if {$old_status_id != $status_id} {

	    db_dml update_item "
		update im_release_items
		set release_status_id = :status_id
		where rel_id in (
				select	rel_id
				from	acs_rels
				where	object_id_one = :release_project_id
					and object_id_two = :item_id
			)
	    "
 
	    set status [db_string status "select im_category_from_id(:status_id)"]
	    set old_status [db_string status "select im_category_from_id(:old_status_id)"]
	    set item_nr [db_string item_name "select project_nr from im_projects where project_id = :item_id" -default "unknown"]

	    im_release_mgmt_new_journal \
		-object_id $release_project_id \
		-action "release_status" \
		-action_pretty "Release Status Changed" \
		-message "Changed status of '$item_nr' from '$old_status' to '$status'"
    }
}

ad_returnredirect $return_url
