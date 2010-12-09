# /packages/intranet-release-mgmt/www/task-board.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

# Expected variables:
# release_project_id

# ------------------------------------------------------------
# Page Title & Help Text

set page_title [lang::message::lookup "" intranet-release-mgmt.Task_Board "Task Board"]
set context_bar [im_context_bar $page_title]
set context ""

set return_url [im_url_with_query]

# ------------------------------------------------------------
# Defaults

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-release-mgmt/task-board" {release_project_id} ]
set task_board_action_url "/intranet-release-mgmt/task-board-action"



# ------------------------------------------------------------
# Get Top Dimension (Release Status)

set top_states_sql "
	select	*
	from	im_categories c
	where	category_type = 'Intranet Release Status'
	order by category_id
"
set top_html ""
set top_states_list [list]
db_foreach top_states $top_states_sql {
    append top_html "<td class=rowtitle>$category</td>\n"
    lappend top_states_list $category_id
}


# ------------------------------------------------------------
# Calculate the items to be displayed

set items_sql "
	select	item.*,
		ri.*,
		im_category_from_id(ri.release_status_id) as release_status
	from	im_projects relp,
		im_projects item,
		acs_rels r,
		im_release_items ri
	where	
		relp.project_id = :release_project_id and
		r.object_id_one = relp.project_id and
		r.object_id_two = item.project_id and
		r.rel_id = ri.rel_id
	order by ri.sort_order
"
db_foreach items $items_sql {
    set cell ""
    if {[info exists cell_hash($release_status_id)]} { set cell $cell_hash($release_status_id) }

    set color "grey"
    set left_url [export_vars -base $task_board_action_url {{release_item_id $project_id} return_url {action left} release_project_id}]
    set right_url [export_vars -base $task_board_action_url {{release_item_id $project_id} return_url {action right} release_project_id}]
    set up_url [export_vars -base $task_board_action_url {{release_item_id $project_id} return_url {action up} release_project_id}]
    set down_url [export_vars -base $task_board_action_url {{release_item_id $project_id} return_url {action down} release_project_id}]
    append cell "
	<table width=150 bgcolor=$color>
	<tr><td colspan=3 align=center><a href='$up_url'>[im_gif arrow_up]</a></td></tr>
	<tr>
	<td><a href='$left_url'>[im_gif arrow_left]</a></td>
	<td>$project_name</td>
	<td><a href='$right_url'>[im_gif arrow_right]</a></td>
	</tr>
	<tr><td colspan=3 align=center><a href='$down_url'>[im_gif arrow_down]</a></td></tr>
	</table>
	<br>
    "
    set cell_hash($release_status_id) $cell
}

# ------------------------------------------------------------
# Render the table body

set body_html ""
foreach release_status_id $top_states_list {

    set cell ""
    if {[info exists cell_hash($release_status_id)]} { set cell $cell_hash($release_status_id) }
    append body_html "
	<td>$cell</td>
    "
}

# ---------------------------------------------------------------
# Navbar
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $release_project_id
set show_context_help_p 0
set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]

set menu_label "release_items"
set sub_navbar_html [im_sub_navbar \
    -base_url "/intranet/projects/view?project_id=$release_project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label] 
