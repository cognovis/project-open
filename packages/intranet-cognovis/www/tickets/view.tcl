# /packages/intranet-timesheet2-task/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    { ticket_id "" }
}

set page_title [_ intranet-helpdesk.Ticket_Info]
set context [list $page_title]



# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

db_1row select_project { 
    SELECT parent_id as project_id FROM im_projects WHERE project_id = :ticket_id
}

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    -components \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_task"] 


