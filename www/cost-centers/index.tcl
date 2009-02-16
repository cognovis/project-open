# /packages/intranet-cost/www/cost-centers/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

if {"" == $return_url} {
    set return_url [ad_conn url]
}

set table_header "
<tr>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=20>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td width=150>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
"

append table_header "
  <td class=rowtitle align=center>[lang::message::lookup "" intranet-cost.DeptQuest "Dept?"]</td>
  <td class=rowtitle align=center>[lang::message::lookup "" intranet-cost.Manager "Manager"]</td>
  <td class=rowtitle align=center>[lang::message::lookup "" intranet-cost.Employees "Employees"]</td>
"

append table_header "
  <td class=rowtitle>[im_gif del "Delete Cost Center"]</td>
</tr>
"

# ------------------------------------------------------
# Main SQL: Extract the permissions for all Cost Centers
# ------------------------------------------------------

set main_sql "
	select distinct
		m.*,
		length(cost_center_code) / 2 as indent_level,
		(9 - (length(cost_center_code)/2)) as colspan_level,
		im_name_from_user_id(m.manager_id) as manager_name,
		e.employee_id as employee_id,
		im_name_from_user_id(e.employee_id) as employee_name
	from
		im_cost_centers m
		LEFT JOIN im_employees e ON (department_id=cost_center_id)
	order by cost_center_code,employee_name
"

set table ""
set ctr 0
set old_package_name ""
set last_id 0
db_foreach cost_centers $main_sql {

    incr ctr
    set object_id $cost_center_id

    append table "\n<tr$bgcolor([expr $ctr % 2])>\n"
    if {0 != $indent_level} {
	append table "\n<td colspan=$indent_level>&nbsp;</td>"
    }

    if {$last_id != $cost_center_id} {
	append table "
	  <td colspan=$colspan_level>
	    <nobr>
	    <A href=$cost_center_url?cost_center_id=$cost_center_id&return_url=$return_url
	    >$cost_center_code - $cost_center_name</A>
	    </nobr>
	  </td>
	  <td>$department_p</td>
	  <td><a href=[export_vars -base "/intranet/users/view" -override {{user_id $manager_id}}]>$manager_name</a></td>
	"
    } else {
	append table "
	  <td colspan=[expr 9+2-$indent_level]></td>
	"
    }

    append table "
	  <td>
	      <nobr><a href=[export_vars -base "/intranet/users/view" -override {{user_id $employee_id}}]>$employee_name</a></nobr>
	  </td>
	  <td>
       "
    
    if {$last_id!=$cost_center_id} {
	append table "<input type=checkbox name=cost_center_id.$cost_center_id>"
    }

    append table "
	  </td>
	</tr>
    "
	set last_id $cost_center_id

}

append table "
	<tr>
	  <td colspan=9 align=right>
	    <A href=new?[export_url_vars return_url]>New Cost Center</a>
	  </td>
	  <td>
	    <input type=submit value='Del'>
	  </td>
	</tr>
"
