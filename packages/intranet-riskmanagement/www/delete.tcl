# /packages/intranet-core/www/admin/categories/category-add-2.tcl
#
# Copyright (C) 1998-2004 various parties
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

  Delete a risk.

  @param risk_id       ID of risk to change/save
  @param state         pending or aproved
  @param return_url    the url to return to
  @param project_id    the current project_id

  @author mai-bee@gmx.net
} {
    risk_id:integer
    { state "" }
    { return_url "" }
    { project_id "" }
}

set user_id [ad_maybe_redirect_for_registration]

if {![im_permission $user_id "add_risks"]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to add/modify risks."
}

if { ![info exists state] || $state == "" } {
    set state "pending"
}

switch $state {
    "pending" {
	set page_body "<form action=\"delete.tcl\" method=GET>The risk is going to be deleted! 
<input type=hidden name=state value=approved><input type=hidden name=risk_id value=$risk_id>
<input type=hidden name=project_id value=$project_id><input type=submit name=submit value=OK></form>"

	doc_return  200 text/html [im_return_template]
    }
    "approved" {
	if {$risk_id > 0} {
	    if [catch {
		db_dml delete_risk "DELETE from im_risks where risk_id = :risk_id"
	    } errmsg ] {
		ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
	    }
	}
	if { [info exists return_url] && ![empty_string_p $return_url] } {
	    ad_returnredirect "$return_url"
	} else {
	    ad_returnredirect "/intranet/projects/view?project_id=$project_id"
	}
    }
}