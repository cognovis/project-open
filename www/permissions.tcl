# /packages/intranet-dynfield/www/permissions.tcl
#
# Copyright (C) 2004 - 2009 ]project-open[
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
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    object_type:optional
    nomaster_p:optional
    attribute_id:optional
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

# If used as 
if {![info exists nomaster_p]} { set nomaster_p 0 }
if {![info exists object_type]} { set object_type "" }
if {![info exists attribute_id]} { set attribute_id "" }

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [im_url_with_query] }

set page_title "Dynfield Permissions"
if {"" != $object_type} { append page_title " for $object_type" }


set context_bar [im_context_bar [list /intranet-dynfield/ "DynField"] $page_title]

set dynfield_url "/intranet-dynfield/attribute-new"
set object_type_url "/intranet-dynfield/object-type"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# ------------------------------------------------------
# Get the list of all dynfields
# and generate the dynamic part of the SQL
# ------------------------------------------------------

set table_header "
<tr>
  <td class=rowtitle>Object Type</td>
  <td class=rowtitle>Attribute</td>
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
}

set main_sql_select ""
set num_groups 0
set object_type_constraint "1 = 1"

set group_ids [list]
set group_names [list]

db_foreach group_list $group_list_sql {

    lappend group_ids $group_id
    lappend group_names $group_name

    append main_sql_select "\tim_object_permission_p(fa.attribute_id, $group_id, 'read') as p${group_id}_read_p,\n"
    append main_sql_select "\tim_object_permission_p(fa.attribute_id, $group_id, 'write') as p${group_id}_write_p,\n"

    append table_header "
      <td class=rowtitle><A href=$group_url?group_id=$group_id>
      [im_gif $profile_gif $group_name]
    </A></td>\n"
    incr num_groups
}
append table_header "
  <td class=rowtitle>[im_gif del "Delete Dynfield"]</td>
</tr>
"


# ------------------------------------------------------
# Main SQL: Extract the permissions for all Dynfields
# ------------------------------------------------------

set table "
<form action=dynfield-action method=post>
[export_form_vars object_type return_url]
<table>
$table_header\n"

set object_type_where ""
if {"" != $object_type} { set object_type_where "and aa.object_type = :object_type" }
if {"" != $attribute_id} { set object_type_where "and fa.attribute_id = :attribute_id" }


set attributes_sql "
    select 
        ${main_sql_select}
	aa.attribute_name,
	aot.object_type,
	aot.pretty_name as object_type_pretty_name,
        aa.pretty_name,
        aa.pretty_plural,
	aa.table_name,
        aa.attribute_id as acs_attribute_id,
        fa.attribute_id as im_dynfield_attribute_id,
        fa.widget_name,
	w.widget_id,
	w.widget,
	w.parameters
    from 
	acs_attributes aa
	right outer join 
		im_dynfield_attributes fa 
		on (aa.attribute_id = fa.acs_attribute_id),
	im_dynfield_widgets w,
	acs_object_types aot
    where 
	$object_type_constraint
	and fa.widget_name = w.widget_name
	and aa.object_type = aot.object_type
	$object_type_where
    order by
	aa.object_type,
	aa.attribute_id
"


set ctr 0
set old_package_name ""
db_foreach attributes $attributes_sql {
    incr ctr
    append table "\n<tr$bgcolor([expr $ctr % 2])>\n"
    append table "
  <td>
    <A href=$object_type_url?object_type=$object_type&return_url=$return_url>
      $object_type_pretty_name
    </A>
  </td>
  <td>
    <A href=$dynfield_url?attribute_id=$im_dynfield_attribute_id&return_url=$return_url>
      $attribute_name
    </A>
  </td>
"

    foreach horiz_group_id $group_ids {
        set read_p [expr "\$p${horiz_group_id}_read_p"]
        set write_p [expr "\$p${horiz_group_id}_write_p"]
	set object_id $im_dynfield_attribute_id

	set action "add_readable"
	set letter "r"
        if {$read_p == "t"} {
	    set action "remove_readable"
	    set letter "<b>R</b>"
        }
	set read "<A href=$toggle_url?[export_url_vars horiz_group_id object_id action return_url]>$letter</A>"

	set action "add_writable"
	set letter "w"
        if {$write_p == "t"} {
	    set action "remove_writable"
	    set letter "<b>W</b>"
        }
	set write "<A href=$toggle_url?[export_url_vars horiz_group_id object_id action return_url]>$letter</A>"

        append table "
  <td align=center>
    $read$write
  </td>
"
    }

    append table "
  <td>
    <input type=checkbox name=attribute_id.$im_dynfield_attribute_id>
  </td>
</tr>
"
}

append table "
</table>
</form>
"
