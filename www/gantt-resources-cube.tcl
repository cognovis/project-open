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
    { level_of_detail:integer 2 }
    { left_vars "user_name_link project_name_link" }
    { project_id:multiple "" }
    { customer_id:integer 0 }
    { user_name_link_opened "" }
}



# ------------------------------------------------------------
# Defaults

set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources "Gantt Resources"]


set html [im_ganttproject_resource_component \
	-start_date $start_date \
	-end_date $end_date \
	-level_of_detail $level_of_detail \
	-left_vars $left_vars \
	-project_id $project_id \
	-customer_id $customer_id \
	-user_name_link_opened $user_name_link_opened  \
]

