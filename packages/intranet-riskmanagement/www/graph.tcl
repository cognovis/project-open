# /packages/intranet-core/www/intranet/companies/new.tcl
#
# Copyright (C) 2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Displays a graph representing all the risks corresponding to one project.
    @param absence_id which component should be modified
    @param return_url the url to be send back after the saving

    @author mai-bee@gmx.net
} {
    project_id:integer
}

set user_id [ad_maybe_redirect_for_registration]

if {![im_permission $user_id "view_risks"]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see risks."
}

if {[info exists project_id] && ![empty_string_p $project_id] && $project_id > 0} {
    set sql "select r.*, n.project_name from im_risks r, (select project_name from im_projects where project_id = :project_id) n where project_id = :project_id"

    set data [list]
    set settings [list 0 30 800 400 "t"]
    set max_impact 1

    db_foreach get_project_risks $sql {
	if { $type == 5100 } {
	    set curr_image "images/bullet-red.gif"
	} else {
	    set curr_image "images/bullet-green.gif"
	}
	lappend data [list $impact $probability 10 "$title" "/intranet-riskmanagement/view?risk_id=$risk_id" $curr_image]
	set max_impact [max $max_impact $impact]
    }

    if { [llength $data] < 1 } {
        set page_body "<br><b>This project doesn't seem to have any risks.</b>\n"
    } else {
	set x_axis [list 0 [expr $max_impact * 1.1] [im_get_axis $max_impact 10] "&euro;"]
	set y_axis [list 0 101 10 "%"]
	set page_body [im_get_chart $x_axis $y_axis $data $settings]
    }
    set page_title "Risks for project \"$project_name\""
    set context_bar [im_context_bar $page_title]

    # add legend
    append page_body "
<img src=\"images/bullet-red.gif\" width=10 height=10> External Risks<br>
<img src=\"images/bullet-green.gif\" width=10 height=10> Internal Risks"

} else {
    ad_return_complaint "Bad Project ID" "<li>The project ID submitted didn't have the right format!"
    return

}

doc_return  200 text/html [im_return_template]
