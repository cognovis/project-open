# /packages/intranet-cost/www/cost-centers/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the permissions for all cost_centers in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Cost Centers"
set context_bar [im_context_bar $page_title]
set context ""

set cost_center_url "/intranet-cost/cost-centers/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

if {"" == $return_url} {
    set return_url [ad_conn url]
}


# ------------------------------------------------------
# Get the list of all relevant "Profiles"
# and generate the dynamic part of the SQL
# ------------------------------------------------------

set group_list_sql {
select DISTINCT
        g.group_name,
        g.group_id,
	p.profile_gif
from
        acs_objects o,
        groups g,
	im_profiles p
where
        g.group_id = o.object_id
	and g.group_id = p.profile_id
        and o.object_type = 'im_profile'
}


set group_ids [list]
set group_names [list]
set table_header "
<tr>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=150></td>
"

set main_sql_select ""
set num_profiles 0
db_foreach group_list $group_list_sql {
    lappend group_ids $group_id
    lappend group_names $group_name
    append main_sql_select "\tim_object_permission_p(m.cost_center_id, $group_id, 'read') as p${group_id}_read_p,\n"
    append table_header "
      <td class=rowtitle><A href=$group_url?group_id=$group_id>
      [im_gif $profile_gif $group_name]
    </A></td>\n"
    incr num_profiles
}
append table_header "
  <td class=rowtitle>[im_gif del "Delete Cost Center"]</td>
</tr>
"

# ------------------------------------------------------
# Main SQL: Extract the permissions for all Cost Centers
# ------------------------------------------------------

set main_sql "
select
${main_sql_select}	m.*,
	length(cost_center_code) / 2 as indent_level,
	(9 - (length(cost_center_code)/2)) as colspan_level
from
	im_cost_centers m
order by cost_center_code
"

set table "
<form action=cost-center-action method=post>
[export_form_vars return_url]
<table>
$table_header\n"

set ctr 0
set old_package_name ""
db_foreach cost_centers $main_sql {
    incr ctr

    append table "\n<tr$bgcolor([expr $ctr % 2])>\n"

    if {0 != $indent_level} {
	append table "\n<td colspan=$indent_level>&nbsp;</td>"
    }

    append table "
  <td colspan=$colspan_level>
    <A href=$cost_center_url?cost_center_id=$cost_center_id&return_url=$return_url>$cost_center_code - $cost_center_name</A>
  </td>
"

    foreach horiz_group_id $group_ids {
        set read_p [expr "\$p${horiz_group_id}_read_p"]
	set object_id $cost_center_id
        set read "<A href=$toggle_url?action=add_readable&[export_url_vars object_id horiz_group_id return_url]>r</A>\n"
        if {$read_p == "t"} {
            set read "<A href=$toggle_url?action=remove_readable&[export_url_vars object_id horiz_group_id return_url]><b>R</b></A>\n"
        }

        append table "
  <td align=center>
    $read
  </td>
"
    }

    append table "
  <td>
    <input type=checkbox name=cost_center_id.$cost_center_id>
  </td>
</tr>
"
}

append table "
<tr>
  <td colspan=[expr $num_profiles + 9] align=right>
    <A href=new?[export_url_vars return_url]>New Cost Center</a>
  </td>
  <td>
    <input type=submit value='Del'>
  </td>
</tr>
</table>
</form>
"
