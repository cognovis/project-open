# /packages/intranet-timesheet2-task-popup/www/index.tcl
#
# Copyright (C) 2003-2005 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    This page allows the user to log the timesheet task that he or she
    is currently working on.

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { header "" }
    { message "" }

    { julian_date "" }
    { date "" }
    { project_id:integer "" }
    { return_url "" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_name [db_string user_name_sql "select im_name_from_user_id(:user_id) from dual"]

if {"" == $return_url} {
    set return_url "[ad_conn url]?[ad_conn form]"
}

set page_title "[lang::message:lookup "" intranet-timesheet2-task-popup.Timesheet_Popup "Timesheet Popup"]
set context_bar [im_context_bar $page_title]

# Get the project name restriction in case project_id is set
set project_restriction ""
if {"" != $project_id} {
    set project_name [db_string project_name "select project_name from im_projects where project_id = :project_id"]
    append page_title " on $project_name"
    set project_restriction "and project_id = :project_id"
}

# Default the date to today if there is no date specified
if {"" ==  $date } {
    if {"" != $julian_date} {
	set date [db_string julian_date_select "select to_char( to_date(:julian_date,'J'), 'YYYY-MM-DD') from dual"]
    } else {
	set date [db_string ansi_date_select "select to_char( sysdate, 'YYYY-MM-DD') from dual"]
    }
} 
ns_log Notice "/intranet-timesheet2/index: date=$date"



# ---------------------------------------------------------------
# Render the Calendar widget
# ---------------------------------------------------------------

doc_return  200 text/html [im_return_template]

