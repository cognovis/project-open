# /www/admin/categories/one.tcl
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
    Displays and edits a risk.
    @param risk_id which component should be modified
    @param curr_project_id only used on creation of new risk

    @author mai-bee@gmx.net
} {
    { risk_id:integer 0 }
    { curr_project_id:integer 0 }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "View Risk"
set context_bar [ad_context_bar $page_title]

# ---------------------------------------------------------------
# Permission
# ---------------------------------------------------------------

if {![im_permission $user_id "view_risks"]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see risks."
}

# ---------------------------------------------------------------
# Get Risk Data
# ---------------------------------------------------------------

if {[info exists risk_id] && ![empty_string_p $risk_id] && $risk_id > 0} {
    if { ![db_0or1row risk_data "select r.*, im_name_from_user_id(owner_id) as owner_name from im_risks r where r.risk_id = :risk_id" ] } {
	ad_return_complaint "Bad Risk" "<li>We couldn't find the risk \#$risk_id; Hmm... there must be something wrong with our page!"
	return
    }
    
    db_1row pro_name "select project_name from im_projects where project_id = :project_id"
    set page_title "Edit Risk"
    set context_bar [ad_context_bar $page_title]

} elseif { [info exists curr_project_id] && ![empty_string_p $curr_project_id] && $curr_project_id > 0 } {
    # create a new risk
    set owner_id $user_id
    set project_id $curr_project_id
    db_1row pro_name "select project_name from im_projects where project_id = :project_id"
    db_1row user_name_date "select im_name_from_user_id(:user_id) as owner_name from dual"
    set risk_id 0
    set probability "0.00"
    set impact "0"
    set title ""
    set description ""
    set type 5100

    set page_title "New Risk"
    set context_bar [ad_context_bar $page_title]
} else {
     ad_return_complaint "Missing Parameters" "<li>To crate a new risk, at least the project ID must be specified (curr_project_id)!"
}

# ---------------------------------------------------------------
# Format Risk Data
# ---------------------------------------------------------------

set html_hidden_info [export_form_vars owner_id risk_id project_id return_url]

set page_body "
<form action=\"new-2.tcl\" method=GET>
$html_hidden_info
<TABLE border=0>
  <TBODY>
  <TR>
    <TD class=rowtitle align=middle colSpan=2>Risk</TD></TR>
  <TR class=rowodd>
    <TD>User</TD>
    <TD><a href=\"/intranet/users/view?[export_url_vars owner_id]\">$owner_name</a></TD></TR>
  <TR class=roweven>
    <TD>Project</TD>
    <TD><a href=\"/intranet/projects/view?[export_url_vars project_id]\">$project_name</a></TD></TR>
  <TR class=rowodd>
    <TD>Title</TD>
    <TD><input name=\"title\" type=\"text\" size=\"50\" value=$title></TD></TR>
  <TR class=rowodd>
    <TD>Probability</TD>
    <TD><input name=\"probability\" type=\"text\" size=\"30\" value=$probability>%</TD></TR>
  <TR class=roweven>
    <TD>Impact</TD>
    <TD><input name=\"impact\" type=\"text\" size=\"30\" value=$impact></TD></TR>
  <TR class=rowodd>
    <TD>Description</TD>
    <TD><textarea name=\"description\" cols=\"50\" rows=\"5\">$description</textarea></TD></TR>
  <TR class=rowodd>
    <TD>Risk Type</TD>
    <TD>[im_category_select "Intranet Risk Type" type $type]</TD></TR>
</TBODY></TABLE>
<input type=submit name=submit value=Save></form><form action=\"delete.tcl\" method=GET><input type=submit name=submit value=Delete>
<input type=hidden name=state value=pending>
<input type=hidden name=risk_id value=$risk_id>
<input type=hidden name=project_id value=$project_id>
</form>
"

doc_return  200 text/html [im_return_template]
