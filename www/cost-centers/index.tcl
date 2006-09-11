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
set toggle_url "/intranet/admin/toggle-privilege"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

if {"" == $return_url} {
    set return_url [ad_conn url]
}

set privs [list invoices quotes delivery_notes bills pos timesheets expense_reports]

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
	and g.group_name not in (
		'Customers', 'Freelancers', 'Freelance Managers', 'HR Managers', 'P/O Admins'
	)
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

    append main_sql_select "\tim_object_permission_p(m.cost_center_id, $group_id, 'fi_read_all') as p${group_id}_read_p,\n"
    append main_sql_select "\tim_object_permission_p(m.cost_center_id, $group_id, 'fi_write_all') as p${group_id}_write_p,\n"

    foreach priv $privs {
	append main_sql_select "\tim_object_permission_p(m.cost_center_id, $group_id, 'fi_read_$priv') as p${group_id}_read_${priv}_p,\n"
	append main_sql_select "\tim_object_permission_p(m.cost_center_id, $group_id, 'fi_write_$priv') as p${group_id}_write_${priv}_p,\n"
    }

    append table_header "
      <td class=rowtitle align=center><A href=$group_url?group_id=$group_id>
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

set table ""
set ctr 0
set old_package_name ""
db_foreach cost_centers $main_sql {

    incr ctr
    set object_id $cost_center_id

    append table "\n<tr$bgcolor([expr $ctr % 2])>\n"
    if {0 != $indent_level} {
	append table "\n<td colspan=$indent_level>&nbsp;</td>"
    }

    append table "
	  <td colspan=$colspan_level>
            <nobr>
	    <A href=$cost_center_url?cost_center_id=$cost_center_id&return_url=$return_url
	    >$cost_center_code - $cost_center_name</A>
            </nobr>
	  </td>
    "

    foreach horiz_group_id $group_ids {

	append table "<td align=left>\n"

	# ---------------------------- Read Group -------------------------------
	append table "<nobr>\n"

        set read_p [expr "\$p${horiz_group_id}_read_p"]
        if {$read_p == "t"} {
	    set action "revoke"
	    set render "<b>R</b>"
	} else {
	    set action "grant"
	    set render "r"
	}

	set privilege "fi_read_all"
        append table "<A href=\"[export_vars -base $toggle_url {object_id horiz_group_id action privilege return_url}]\">$render</A>\n"

	foreach priv $privs {

	    set priv_initial [string range $priv 0 0]
	    set read_p [expr "\$p${horiz_group_id}_read_${priv}_p"]
	    set privilege "fi_read_$priv"

	    if {$read_p == "t"} {
		set action "revoke"
		set render "<b>[string toupper "r$priv_initial"]</b>"
	    } else {
		set action "grant"
		set render "r$priv_initial"
	    }
	    append table "<A href=\"[export_vars -base $toggle_url {object_id horiz_group_id action privilege return_url}]\">$render</A>\n"
	}
	append table "</nobr>\n"


	# ---------------------------- Write Group -------------------------------
	append table "<nobr>\n"

        set write_p [expr "\$p${horiz_group_id}_write_p"]
        if {$write_p == "t"} {
	    set action "revoke"
	    set render "<b>W</b>"
	} else {
	    set action "grant"
	    set render "w"
	}

	set privilege "fi_write_all"
        append table "<A href=\"[export_vars -base $toggle_url {object_id horiz_group_id action privilege return_url}]\">$render</A>\n"

	foreach priv $privs {
	    set priv_initial [string range $priv 0 0]
	    set write_p [expr "\$p${horiz_group_id}_write_${priv}_p"]
	    set privilege "fi_write_$priv"

	    if {$write_p == "t"} {
		set action "revoke"
		set render "<b>[string toupper "w$priv_initial"]</b>"
	    } else {
		set action "grant"
		set render "w$priv_initial"
	    }

	    append table "<A href=\"[export_vars -base $toggle_url {object_id horiz_group_id action privilege return_url}]\">$render</A>\n"
	}
	append table "</nobr>\n"


	append table "</td>\n"
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
"
