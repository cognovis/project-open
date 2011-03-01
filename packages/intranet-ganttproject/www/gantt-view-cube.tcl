# /packages/intranet-reporting/www/gantt-view-cube.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Gantt View "Cube"

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param level_of_details Details of date axis: 1 (month), 2 (week) or 3 (day)
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
    @param user_name_link_opened List of users with details shown
} {
    { start_date "" }
    { end_date "" }
    { top_vars "" }
    { project_id:multiple "" }
    { customer_id:integer 0 }
    { user_name_link_opened "" }
    { opened_projects "" }
    { zoom "" }
    { max_col 999 }
    { max_row 100 }
}


# ---------------------------------------------------------------
# Default & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

foreach pid $project_id {
    im_project_permissions $user_id $pid view read write admin
    if {!$read} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
	return
    }
}

set show_context_help_p 0
set main_navbar_label "reporting"

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

set sub_navbar ""
if {[llength $project_id] == 1} {
    # Exactly one project - quite a frequent case.
    # Show a ProjectMenu so that it looks like we've gone to a different tab.

    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]

    set sub_navbar [im_sub_navbar \
       -components \
       -base_url "/intranet/projects/view?project_id=$project_id" \
       $project_menu_id \
       $bind_vars "" "pagedesriptionbar" "project_gantt"] 



    set main_navbar_label "projects"

}


# ------------------------------------------------------------
# Defaults

set page_title [lang::message::lookup "" intranet-reporting.Gantt_Diagram "Gantt Diagram"]


set html [im_ganttproject_gantt_component \
	-auto_open 0 \
	-export_var_list [list project_id] \
	-start_date $start_date \
	-end_date $end_date \
	-top_vars $top_vars \
	-project_id $project_id \
	-customer_id $customer_id \
	-opened_projects $opened_projects \
	-zoom $zoom \
	-max_col $max_col \
	-max_row $max_row \
]


