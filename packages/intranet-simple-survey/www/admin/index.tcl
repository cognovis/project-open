# /packages/intranet-simple-survey/www/admin/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the permissions for all menus in the system

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

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title "Simple Survey Permissions"
set context_bar [im_context_bar [list /intranet-simple-survey/ "Simple Surveys"] $page_title]

set survsimp_url "/intranet-simple-survey/admin/new"
set survsimp_admin_url "/simple-survey/admin/one"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"


set survsimp_package_id [db_string sursimp_package "
	select	package_id
	from	apm_packages
	where	package_key = 'simple-survey'
"]


# ------------------------------------------------------
# Get the list of all dynfields
# and generate the dynamic part of the SQL
# ------------------------------------------------------

set table_header "
<tr>
  <td class=rowtitle>Survey</td>
\n"


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
UNION
	select	'Registered Users', -2,	''
}


set main_sql_select ""
set num_groups 0

set group_ids [list]
set group_names [list]

db_foreach group_list $group_list_sql {

    lappend group_ids $group_id
    lappend group_names $group_name
    regsub -all {\-} $group_id "_" gid
    append main_sql_select "\tim_object_permission_p(ss.survey_id, $group_id, 'read') as p${gid}_read_p,\n"

    append table_header "
      <td class=rowtitle><A href=$group_url?group_id=$group_id>
      [im_gif $profile_gif $group_name]
    </A></td>\n"
    incr num_groups
}
append table_header "
  <td class=rowtitle>[im_gif del "Delete Simple Survey"]</td>
</tr>
"


# ------------------------------------------------------
# Main SQL: Extract permissions
# ------------------------------------------------------

set table "
<form action=dynfield-action method=post>
[export_form_vars return_url]
<table>
$table_header\n"

set ttt {
set survsimp_sql "
	select
		${main_sql_select}
		som.*,
		som.name as som_name,
		som.note as som_note,
		ss.*,
		aot.*,
		aot.pretty_name as object_type_pretty_name
	from
		im_survsimp_object_map som,
		survsimp_surveys ss,
		acs_object_types aot
	where
		som.survey_id = ss.survey_id
		and som.acs_object_type = aot.object_type
"
}


set survsimp_sql "
	select
		${main_sql_select}
		ss.*,
		ss.name as survey_name
	from
		survsimp_surveys ss
	where
		1=1
	order by
		ss.name
"


set ctr 0
set old_package_name ""
db_foreach survsimp_query $survsimp_sql {
    incr ctr
    append table "\n<tr$bgcolor([expr $ctr % 2])>\n"
    append table "
  <td>
    <A href=[export_vars -base $survsimp_admin_url {survey_id return_url}]>
      $survey_name
    </A>
  </td>
"

    foreach horiz_group_id $group_ids {

	set object_id $survey_id
	regsub -all {\-} $horiz_group_id "_" horiz_gid

	set read_p [expr "\$p${horiz_gid}_read_p"]
	set action "add_readable"
	set letter "r"
	if {$read_p == "t"} {
	    set read "<A href=$toggle_url?object_id=$survey_id&action=remove_readable&[export_url_vars horiz_group_id return_url]><b>R</b></A>\n"
	    set action "remove_readable"
	    set letter "<b>R</b>"
	}
	set read "<A href=$toggle_url?[export_url_vars horiz_group_id object_id action return_url]>$letter</A>\n"

	append table "
  <td align=center>
    $read
  </td>
"
    }

    append table "
  <td>
    <input type=checkbox name=survey_id.$survey_id>
  </td>
</tr>
"
}

append table "
</table>
</form>
"
