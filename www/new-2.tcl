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

  Save (changes) in risk. (new.tcl doesn't exist, changes are submitted from view.tcl)

  @param risk_id       ID of risk to change/save
  @param owner_id      user saving the risk
  @param project_id    the project the risk belongs to
  @param title         title of the risk
  @param description   mor details
  @param probability   pro. the incident desribed by the risk occurs
  @param impact        the impact the incident would have
  @param type     the type of this risk
  @param return_url    the url to return back to

  @author mai-bee@gmx.net
} {
  risk_id:integer 
  owner_id:notnull
  project_id:notnull
  title:notnull
  description:notnull
  probability:notnull
  impact:notnull
  type:notnull
  return_url
}

set user_id [ad_maybe_redirect_for_registration]

if {![im_permission $user_id "add_risks"]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to add/modify risks."
}

set exception_count 0
set exception_text ""


if { $probability < 0 || $probability > 100 } {
    incr exception_count
    append exception_text "<li>The probability must be between 0 and 100 %"
}
if { $impact < 0 } {
    incr exception_count
    append exception_text "<li>The impact must be positive or 0"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if {$risk_id > 0} {

    if [catch {
	db_dml update_risk "UPDATE
        im_risks SET
        owner_id = :owner_id,
        project_id = :project_id,
        probability = :probability,
        impact = :impact,
        title = :title,
        description = :description WHERE
        risk_id = :risk_id"
    } errmsg ] {
	ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
	return

    }
} else {
    if [catch {
	db_dml insert_risk "INSERT INTO im_risks
        (risk_id, owner_id, project_id, probability, impact, title, description, type) values
        ([im_new_object_id], :owner_id, :project_id, :probability, :impact, :title, :description, :type)"
    } errmsg] {
	ad_return_complaint "Argument Error" " <ul>$errmsg</ul>"
    }
}

db_release_unused_handles

if { [info exists return_url] && ![empty_string_p $return_url] } {
    ad_returnredirect "$return_url"
} else {
    ad_returnredirect "/intranet/projects/view?project_id=$project_id"
}

