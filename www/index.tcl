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


# ---------------------------------------------------------------
# Create the main walls multirow
# ---------------------------------------------------------------

set user_id 0
set wall_id 0
set forum_topic_id 0
set ticket_description ""

db_multirow -extend { ticket_status ticket_type thumbs_up_count thumbs_direction wall_description comment_count wall_url project_name wall_id type thumbs_down_url thumbs_up_url thumbs_undo_url dollar_url comments_url creator_url creator_name } wall wall_query $wall_sql {

    set wall_id $container_object_id
    set type "wall_project_tasks"
    set thumbs_up_count 0
    set comment_count 0
    set thumbs_direction "up"
    set project_name $container_object_name
    set wall_description "adsf"
    set ticket_status "status"
    set ticket_type "type"


    set wall_url [export_vars -base "/intranet-wall/redirect-to-ticket" {{ticket_id $wall_id} return_url}]
    set dollar_url [export_vars -base "/intranet-wall/dollar-action" {return_url ticket_id}]
    set comments_url [export_vars -base "/intranet-forum/new" {return_url {parent_id $forum_topic_id}}]

    set wall_description [ns_quotehtml [string range $ticket_description 0 $max_description_len]]
    if {[string length $wall_description] >= $max_description_len} { append wall_description "... (<a href='$wall_url'>more</a>)" }

    set creator_name $user_name
    if {[regexp {^([a-z0-9A-Z\-_]*)@} $creator_name match username_body]} { set creator_name $username_body }
    set creator_url [export_vars -base "/intranet/users/view" {{user_id $user_id}}]

    set thumbs_up_url [export_vars -base "/intranet-wall/thumbs-action" {return_url {ticket_id $wall_id} {direction up}}]
    set thumbs_down_url [export_vars -base "/intranet-wall/thumbs-action" {return_url {ticket_id $wall_id} {direction down}}]
    set thumbs_undo_url [export_vars -base "/intranet-wall/thumbs-action" {return_url {ticket_id $wall_id} {direction undo}}]
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


