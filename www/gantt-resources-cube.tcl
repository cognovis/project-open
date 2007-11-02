# /packages/intranet-reporting/www/gantt-resources-cube.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Gantt Resource "Cube"

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param level_of_details Details of date axis: 1 (month), 2 (week) or 3 (day)
    @param left_vars Variables to show at the left-hand side
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
    @param user_name_link_opened List of users with details shown
} {
    { start_date "" }
    { end_date "" }
    { top_vars "" }
    { left_vars "user_name_link project_name_link" }
    { project_id:multiple "" }
    { customer_id:integer 0 }
    { user_name_link_opened "" }
    { zoom "" }
    { max_col 20 }
    { max_row 100 }
    { config "" }
}



# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

set main_navbar_label "reporting"

set project_menu ""
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
       $bind_vars "" "pagedesriptionbar" "project_resources"] 

    set main_navbar_label "projects"
}


# ------------------------------------------------------------
# Defaults

set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources "Gantt Resources"]


switch $config {
    resource_planning_report {
	# Configure the parameters to show the current month only
	set start_date [db_string start_date "select to_char(now()::date, 'YYYY-MM-DD')"]
	set end_date [db_string start_date "select to_char(now()::date+14, 'YYYY-MM-DD')"]
	set max_col 30
    }
}



# ------------------------------------------------------------
# Contents

set html [im_ganttproject_resource_component \
	-start_date $start_date \
	-end_date $end_date \
	-top_vars $top_vars \
	-left_vars $left_vars \
	-project_id $project_id \
	-customer_id $customer_id \
	-user_name_link_opened $user_name_link_opened  \
	-zoom $zoom \
	-max_col $max_col \
	-max_row $max_row \
]

if {"" == $html} { 
    set html [lang::message::lookup "" intrant-ganttproject.No_resource_assignments_found "No resource assignments found"]
    set html "<p>&nbsp;<p><blockquote><i>$html</i></blockquote><p>&nbsp;<p>\n"
}


