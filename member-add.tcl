# /www/intranet/member-add.tcl

ad_page_contract {
    Presents a search form to find a user to add to a group.

    @param group_id group to which to add
    @param role role in which to add
    @param also_add_to_group_id Additional groups to which to add
    @param return_url Return URL

    @author        mbryzek@arsdigita.com
    @creation-date 16 April 2000
    @cvs-id        member-add.tcl,v 3.5.2.6 2000/09/22 01:38:22 kevin Exp
} {
    group_id:naturalnum
    { role "" }
    { return_url "" }
    { also_add_to_group_id:naturalnum "" }
    { select_from_group:naturalnum "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_member_p [ad_user_group_member $group_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_admin_p [|| $user_is_admin_p $user_is_group_admin_p]
set user_admin_p [|| $user_admin_p $user_is_wheel_p]

# --------------- Permissions Stuff --------------------------
#
# - System or Intranet admins can give all permissions
# - Manager and member rights can only be given by Managers or SysAdmins
# - Sub-Roles (Translator, ...) can be given by managers and
#   members

if {!$user_is_group_member_p && !$user_admin_p} {
    ad_return_complaint "Insufficient Permissions" "<li>You need to be member of the group to add members."
}

set role_options "
<option value=translator>Translator</option>
<option value=editor>Editor</option>
<option value=proofer>Proof Reader</option>
"

if {$user_admin_p > 0} {
set role_options "
<option value=administrator>Administrator</option>
<option value=member>Member</option>
$role_options"
}


# Find out the project/customer name and deal with the case that the name
# may be empty.
#
set group_name [db_string group_name_for_one_group_id "select group_name from user_groups where group_id = :group_id"]
if {[string equal "" $group_name]} {
    set group_name [db_string group_name_for_one_group_id "select short_name from user_groups where group_id = :group_id"]
}

set page_title "Add new member to $group_name"
set context_bar [ad_context_bar_ws "Add member"]

set locate_form "
<form method=POST action=/user-search>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"group_id role return_url also_add_to_group_id notify_asignee\">

<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=middle>Existing User</td>
  </tr>
  <tr> 
    <td>by Email</td>
    <td><input type=text name=email size=20></td>
  </tr>
  <tr> 
    <td>or Last Name</td>
    <td><input type=text name=last_name size=20></td>
  </tr>
  <tr> 
    <td>add as</td>
    <td>
      <select name=role>
      $role_options
      </select>
    </td>
  </tr>
  <tr> 
    <td></td>
    <td>
      <input type=submit value=Search>
      <input type=checkbox name=notify_asignee value=1 checked>Notify<br>
    </td>
  </tr>


</table>
</form>
"

# Get the list of all employees as a shortcut
#
set employee_select [im_employee_select_multiple "user_id_from_search" "" 7 ""]

set select_form "
<form method=POST action=/intranet/member-add-2>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"group_id role return_url also_add_to_group_id\">
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td class=rowtitle align=middle>Employee</td>
  </tr>
  <tr> 
    <td>
$employee_select
    </td>
  </tr>
  <tr> 
    <td>add as 
<select name=role>
$role_options
</select>
    </td>
  </tr>
  <tr> 
    <td>
      <input type=submit value=Add>
      <input type=checkbox name=notify_asignee value=1 checked>Notify
    </td>
  </tr>
</table>
</form>
"



# ---------------------------------------------------------------
# Make the freelance list:
# ---------------------------------------------------------------

set freelance_html [im_freelance_member_select_component $group_id $role_options $return_url]

# ------------------------------------------------------------
set sql "
select
	u.first_names||' '||u.last_name as user_name,
	fa.*,
	im_category_from_id (fa.status_id) as status
from
	im_freelance_applications fa,
	users u,
	im_projects p
where
	u.user_id = fa.user_id
	and p.group_id = fa.project_id
        and fa.project_id = :group_id
order by
	fa.status_id DESC
"

set application_html "
<form method=GET action=/intranet/member-add-2>
[export_form_vars group_id return_url]
\n<table border=0>
<tr><td colspan=10 align=center class=rowtitle>Freelance Applications</td></tr>\n
<tr class=rowtitle>
<td>Freelance</td>
<td>Rates</td>
<td>Availability</td>
<td>Trans. SWords</td>
<td>Edit SWords</td>
<td>Proof SWords</td>
<td>Status</td>
<td>Add</td>
<td>Refuse</td></tr>\n"

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0

db_foreach application_table $sql {
    append application_html "<tr $bgcolor([expr $ctr % 2])>
<td><a href=users/view?user_id=$user_id>$user_name</a></td>
<td></td>
<td>$availavility_percentage</td>
<td>$trans_swords</td>
<td>$edit_swords</td>
<td>$proof_swords</td>
<td>$status</td>"
    if { [string equal $status "Accepted"] || [string equal $status "Refused"] || [string equal $status "Declined"] } {
	append application_html "<td></td><td></td></tr>"    
    } else {
	append application_html "
<td><input type=checkbox name=user_add_to_project.$user_id value=Add></td>
<td><input type=checkbox name=user_refuse_from_project.$user_id value=Refuse></td></tr>\n"
    }
    incr ctr
}
append application_html "<tr>
<td colspan=7 align=right>add as <select name=role>$role_options</select>
<input type=checkbox name=notify_asignee value=1 checked>Notify
</td>
<td> <input type=submit value=Add name=action></td>
<td> <input type=submit value=Refuse name=action></td>
</tr>\n
</table>
</form>"

# ---------------------------------------------------------------
# Join Stuff together
# ---------------------------------------------------------------



set page_content "
<table cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
    $locate_form
  </td>
  <td valign=top>
    $select_form
  </td>
</tr>
<tr>
<td colspan=2 valign=top>
    $application_html
    $freelance_html
</td>
</tr>
</table>
"

doc_return  200 text/html [im_return_template]
