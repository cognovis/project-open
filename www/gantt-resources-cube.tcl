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
    { left_vars "dept_name user_name_link project_name_link" }
    { project_id:multiple "" }
    { customer_id:integer 0 }
    { user_name_link_opened "" }
    { zoom "" }
    { max_col 20 }
    { max_row 100 }
    { config "" }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set show_context_help_p 0

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "view_projects_all"]} {
    ad_return_complaint 1 "You don't have permissions to see this page"
    ad_script_abort
}


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

set sub_navbar ""
set main_navbar_label "projects"

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

    set project_name [db_string project_name "select project_name from im_projects where project_id = :project_id" -default "undefined"]
    set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources_for_project "Gantt Resources for %project_name%"]


} else {

    # Show the same header as the ProjectListPage
    set letter ""
    set next_page_url ""
    set previous_page_url ""
    set menu_select_label "projects_gantt_resources"
    set sub_navbar [im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter project_status_id] $menu_select_label]

    set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources "Gantt Resources"]

}


# ------------------------------------------------------------
# Defaults


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



# ------------------------------------------------------------
# Left Navbar is the filter/select part of the left bar

set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           #intranet-core.Filter_Projects#
        	</div>

        <form action='/intranet-ganttproject/gantt-resources-cube' method=GET>
        <table border=0 cellspacing=1 cellpadding=1>
        <tr>
          <td class=form-label>#intranet-core.Start_Date#</td>
          <td class=form-widget>
            <input type=textfield name=start_date value='$start_date'>
          </td>
        </tr>
        <tr>
          <td class=form-label>#intranet-core.End_Date#</td>
          <td class=form-widget>
            <input type=textfield name=end_date value='$end_date'>
          </td>
        </tr>
        <tr>
          <td class=form-label></td>
          <td class=form-widget><input type=submit value='#intranet-core.Submit#'></td>
        </tr>
        </table>
        </form>

      	</div>
      <hr/>
"
