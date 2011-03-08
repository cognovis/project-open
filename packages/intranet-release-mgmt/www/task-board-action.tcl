# /packages/intranet-release-mgmt/www/task-board-action.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Task Board Action
    Accepts "events" (clicking on an arrow) from the task-board
    and moves the tasks accordingly.
} {
    release_project_id:integer
    release_item_id:integer
    action
    return_url
}


# ------------------------------------------------------------
# Get the list of release states

set top_states_sql "
	select	*
	from	im_categories c
	where	category_type = 'Intranet Release Status'
	order by category_id
"
set top_states_list [list]
db_foreach top_states $top_states_sql {
    lappend top_states_list $category_id
}


# ------------------------------------------------------------
# Get information about the affected release item

set rel_item_info_sql "
	select	item.*,
		ri.*,
		ri.rel_id as release_item_id,
		im_category_from_id(ri.release_status_id) as release_status
	from
		im_projects relp,
		im_projects item,
		acs_rels r,
		im_release_items ri
	where	
		relp.project_id = :release_project_id and
		item.project_id = :release_item_id and
		r.object_id_one = relp.project_id and
		r.object_id_two = item.project_id and
		r.rel_id = ri.rel_id
"
db_0or1row rel_item_info $rel_item_info_sql


# ------------------------------------------------------------
# Update the item according to action

# determine the position of the current release_status_id in the
# list of release states
set rel_state_pos [lsearch $top_states_list $release_status_id]

switch $action {
    left {
	set rel_state_pos [expr $rel_state_pos - 1]
    }
    right {
	set rel_state_pos [expr $rel_state_pos + 1]
    }
    up {
	# Search for the items with the next lower sort_order
	set prev_release_item_id ""
	set prev_sort_order ""
	db_0or1row prev_sql "
		select	ri.rel_id as prev_release_item_id,
			ri.sort_order as prev_sort_order
		from	im_projects relp,
			im_projects item,
			acs_rels r,
			im_release_items ri
		where	relp.project_id = :release_project_id and
			r.object_id_one = relp.project_id and
			r.object_id_two = item.project_id and
			r.rel_id = ri.rel_id and
			ri.sort_order < :sort_order and
			ri.release_status_id = :release_status_id
		order by ri.sort_order DESC
		LIMIT 1
	"
	if {"" != $prev_release_item_id} {
	    # Exchange the sort_order with the previous item
	    db_dml update_prev "
		update im_release_items
		set sort_order = :sort_order
		where rel_id = :prev_release_item_id
	    "
	    db_dml update_prev "
		update im_release_items
		set sort_order = :prev_sort_order
		where rel_id = :release_item_id
	    "
	}
    }
    down {
	# Search for the items with the next higher sort_order
	set prev_release_item_id ""
	set prev_sort_order ""
	db_0or1row prev_sql "
		select	ri.rel_id as prev_release_item_id,
			ri.sort_order as prev_sort_order
		from	im_projects relp,
			im_projects item,
			acs_rels r,
			im_release_items ri
		where	relp.project_id = :release_project_id and
			r.object_id_one = relp.project_id and
			r.object_id_two = item.project_id and
			r.rel_id = ri.rel_id and
			ri.sort_order > :sort_order and
			ri.release_status_id = :release_status_id
		order by ri.sort_order
		LIMIT 1
	"
	if {"" != $prev_release_item_id} {
	    # Exchange the sort_order with the previous item
	    db_dml update_prev "
		update im_release_items
		set sort_order = :sort_order
		where rel_id = :prev_release_item_id
	    "
	    db_dml update_prev "
		update im_release_items
		set sort_order = :prev_sort_order
		where rel_id = :release_item_id
	    "
	}
    }
}

if {$rel_state_pos < 0} { set rel_state_pos 0 }
if {$rel_state_pos > [llength $top_states_list]} { set rel_state_pos [llength $top_states_list] }
set new_release_status_id [lindex $top_states_list $rel_state_pos]
set new_release_status [im_category_from_id $new_release_status_id]

db_dml update_release_item "
	update im_release_items
	set release_status_id = $new_release_status_id
	where rel_id = :release_item_id
"

if {$release_status_id != $new_release_status_id} {
    # Record that somebody moved the item between states
    im_release_mgmt_new_journal \
	-object_id $release_project_id \
	-action "release_status" \
	-action_pretty "Release Status Changed" \
	-message "Changed status of '$project_name' from '$release_status' to '$new_release_status'"
}


ad_returnredirect $return_url
