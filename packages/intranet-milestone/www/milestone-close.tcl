# /packages/intranet-milestone/www/milestone-close.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Marks the selectec milestones as "closed"

    @param return_url the url to return to
    @author frank.bergmann@project-open.com
} {
    milestone_id:multiple,optional
    return_url
}

set user_id [ad_maybe_redirect_for_registration]

if {![info exists milestone_id]} {
    ad_return_complaint 1 "No milestone_id specified"
    ad_script_abort
}



set project_list $milestone_id

if {0 == [llength $project_list]} { ad_returnredirect $return_url }

# Convert the list of selected projects into a "project_id in (1,2,3,4...)" clause
#
set project_in_clause "and project_id in ("
lappend project_list 0
append project_in_clause [join $project_list ", "]
append project_in_clause ")\n"

ns_log Notice "milestone-close: project_in_clause=$project_in_clause"

set sql "
	update im_projects
	set project_status_id = [im_project_status_closed]
	where	1=1
		$project_in_clause
"
db_dml del_projects $sql

foreach pid $project_list {
    im_audit -object_id $pid
}

ad_returnredirect $return_url

