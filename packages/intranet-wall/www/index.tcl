# /packages/intranet-wall/www/index.tcl
#
# Copyright (c) 2011 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@ticket-open.com
} {
    { wall_date "" }
    { order_by "Points" }
    { mine_p "all" }
    { ticket_status_id:integer "[im_ticket_status_open]" }
    { letter:trim "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "wall_management_list" }
    { wall_search "" }
    { perspective "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_get_user_id]
set page_title [lang::message::lookup "" intranet-wall.Project_Wall "Project Wall"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set letter [string toupper $letter]
set max_description_len 200

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set return_url [im_url_with_query]

if {"" == $wall_date} { set wall_date [db_string wall_date "select now()::date - 30 from dual"] }

set view_walls_all_p 1
set edit_walls_all_p 1

# Parameter passing from XoWiki includelet:
# Allow the includelet to disable the "master" on this page.
if {![info exists show_template_p]} { set show_template_p 1 }


set ticket_bulk_actions_p $user_is_admin_p

# ---------------------------------------------------------------
# Perspectives
# ---------------------------------------------------------------

set order_by_clause "thumbs_up_count DESC"

switch $perspective {
    Top { set order_by_clause "thumbs_up_count DESC" }
    Hot { set order_by_clause "thumbs_up_count_in_last_month, thumbs_up_count DESC" }
    New { set order_by_clause "creation_date DESC" }
    Accepted { set ticket_status_id [im_ticket_status_assigned] }
    Done { set ticket_status_id [im_ticket_status_closed] }
    default {
	# Nothing, show "Top" order
    }
}



# ---------------------------------------------------------------
# Main SQL
# ---------------------------------------------------------------


set wall_sql [db_string wall "select report_sql from im_reports where report_code = 'wall_new_project_task'"]


set substitution_list [list \
			   user_id $current_user_id \
			   wall_date $wall_date \
]

set form_vars [ns_conn form]
foreach form_var [ad_ns_set_keys $form_vars] {
    set form_val [ns_set get $form_vars $form_var]
    lappend substitution_list $form_var
    lappend substitution_list $form_val
}

set wall_sql [lang::message::format $wall_sql $substitution_list]

# append wall_sql "\nLIMIT 10"

# ---------------------------------------------------------------
# Create the main walls multirow
# ---------------------------------------------------------------

set user_id 0

db_multirow -extend { container_object_url container_object_type_l10n specific_object_url specific_object_type_l10n } wall wall_query $wall_sql {

    set container_object_url [util_memoize [list db_string container_object_url "
	select	url
	from	im_biz_object_urls
	where	object_type = '$container_object_type' and
		url_type = 'view'
    "]]
    append container_object_url $container_object_id
    set container_object_type_l10n [lang::message::lookup "" intranet-core.$container_object_type $container_object_type]

    set specific_object_url [util_memoize [list db_string specific_object_url "
	select	url
	from	im_biz_object_urls
	where	object_type = '$specific_object_type' and
		url_type = 'view'
    "]]
    append specific_object_url $specific_object_id
    set specific_object_type_l10n [lang::message::lookup "" intranet-core.$specific_object_type $specific_object_type]

    set creator_url [export_vars -base "/intranet/users/view" {{user_id $user_id}}]
}


# Define a few GIFs that are used in the ADP
set comment_gif [im_gif comments]
set thumbs_up_pale_24 [im_gif "thumbs_up.pale.24"]
set thumbs_down_pale_24 [im_gif "thumbs_down.pale.24"]
set thumbs_up_pressed_24 [im_gif "thumbs_up.pressed.24"]
set thumbs_down_pressed_24 [im_gif "thumbs_down.pressed.24"]

regexp {src=\"([a-z0-9A-Z_\./]*)\"} $thumbs_up_pale_24 match thumbs_up_pale_24_gif
regexp {src=\"([a-z0-9A-Z_\./]*)\"} $thumbs_up_pressed_24 match thumbs_up_pressed_24_gif



# ---------------------------------------------------------------
# Count how many surveys the user has filled out
# ---------------------------------------------------------------

set survey_count [db_string survey_count "
	select	count(*)
	from	survsimp_responses sr,
		acs_objects o
	where	sr.response_id = o.object_id and
		o.creation_user = :current_user_id and
		survey_id in (438275, 438249, 305439)
"]

# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set next_page_url ""
set previous_page_url ""
set menu_select_label "wall"

set wall_navbar_html ""

# [im_wall_navbar $letter "/intranet-wall/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter] $menu_select_label]


