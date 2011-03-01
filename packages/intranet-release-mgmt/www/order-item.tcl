# /packages/intranet-release-mgmt/www/order-items.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new release item to a project

    @param dir Is one of (up, down)

    @author frank.bergmann@project-open.com
} {
    release_project_id:integer
    project_id:integer
    dir
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]

im_project_permissions $user_id $release_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# -----------------------------------------------------
# Get the "sort_order" of the current item

set cur_item_ids [db_list cur_sort_order "
		select	rel_id
		from	acs_rels
		where	rel_type = 'im_release_item'
			and object_id_one = :release_project_id
			and object_id_two = :project_id
"]
set cur_item_id [lindex $cur_item_ids 0]


set cur_sort_order [db_string cur_sort_order "
	select	sort_order
	from	im_release_items
	where	rel_id = :cur_item_id
" -default 0]


# ad_return_complaint 1 "<pre>cur_item_ids=$cur_item_ids \ncur_item_id=$cur_item_id \ncur_sort_order=$cur_sort_order\n</pre>"

# -----------------------------------------------------
# Move the item

switch $dir {
    up {
	# Get the "sort_order" of the item above
	set above_sort_order [db_string above_sort_order "
		select	coalesce(max(i.sort_order),0)
		from	im_release_items i,
			acs_rels r
		where	r.rel_id = i.rel_id
			and r.object_id_one = :release_project_id
			and i.sort_order < :cur_sort_order
	" -default 0]

	if {0 != $above_sort_order} {

	    # There is an element above the current one: 
	    # Get the ID of the component above
	    set above_ids [db_list above_list "
		select	i.rel_id
		from	acs_rels r,
			im_release_items i
		where	i.sort_order = :above_sort_order
			and r.object_id_one = :release_project_id
			and r.object_id_two = :project_id
	    "]
	    set above_item_id [lindex $above_ids 0]

	    # Exchange the sort orders of the user_map table
	    db_dml update "
			update	im_release_items
			set	sort_order = :above_sort_order 
			where	rel_id = :cur_item_id
	    "
	    db_dml update "
			update	im_release_items
			set	sort_order = :cur_sort_order 
			where	rel_id = :above_item_id
	    "
	}
    }

    down {
	# Get the "sort_order" of the item below
	set below_sort_order [db_string below_sort_order "
		select	coalesce(min(i.sort_order),0)
		from	im_release_items i,
			acs_rels r
		where	r.rel_id = i.rel_id
			and r.object_id_one = :release_project_id
			and i.sort_order > :cur_sort_order
	" -default 0]

	if {0 != $below_sort_order} {

	    # There is an element below the current one: 
	    # Get the ID of the component below
	    set below_ids [db_list below_list "
		select	i.rel_id
		from	acs_rels r,
			im_release_items i
		where	i.sort_order = :below_sort_order
			and r.object_id_one = :release_project_id
			and r.object_id_two = :project_id
	    "]
	    set below_item_id [lindex $below_ids 0]

	    # Exchange the sort orders of the user_map table
	    db_dml update "
			update	im_release_items
			set	sort_order = :below_sort_order 
			where	rel_id = :cur_item_id
	    "
	    db_dml update "
			update	im_release_items
			set	sort_order = :cur_sort_order 
			where	rel_id = :below_item_id
	    "
	}
    }
}

ad_returnredirect $return_url
