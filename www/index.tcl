# /packages/intranet-reporting/www/index.tcl
#
# Copyright (C) 2004 - 2009 ]project-open[
#
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
    Show all the Reports

    @author juanjoruizx@yahoo.es
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set reports_exist_p [im_table_exists "im_reports"]


# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting"

set read_p [util_memoize [list db_string report_perms "
        select  im_object_permission_p(m.menu_id, $current_user_id, 'read')
        from    im_menus m
        where   m.label = '$menu_label'
" -default 'f']]

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}


if {"" == $return_url} { set return_url [ad_conn url] }

set page_title [lang::message::lookup "" intranet-reporting.Available_Reports "Available Reports"]
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------
# Check for new Menu entries
#
# ------------------------------------------------------

# This is a bit ugly.
# Somebody might have added a new menu via a database operation.
# In this case we need to re-calculate the menu hierarchy.
# Otherwise the new report menu will not appear below.
set new_menu_exists_p [db_string new_menu_exists_p "
	select	count(*)
	from	im_menus
	where	tree_sortkey is NULL
"]
if {$new_menu_exists_p} { im_menu_update_hierarchy }


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action_list [list "[_ intranet-reporting.Add_new_Report]" "[export_vars -base "new" {return_url}]" "[_ intranet-reporting.Add_new_Report]"]

set elements_list {
    name {
	label $page_title
	display_template {
	    <nobr>
	    <if @reports.indent_level@ gt 4>
	    @reports.indent_spaces;noquote@ 
	    <a href="@reports.url@">@reports.name@</a>
	    </if>
	    <else>
	    <b>@reports.name@</b>
	    </else>
	    </nobr>
	}
    }
}


set main_sql_select ""
set group_list [list]

if {$reports_exist_p && $user_admin_p} {
    lappend elements_list \
        edit {
            label "[im_gif wrench]"
            display_template {
                @reports.edit_html;noquote@
            }
        }
    

    # ---------------------------------------------------
    # Add columns for each of the profiles

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

    db_foreach group_list $group_list_sql {
	lappend group_list $group_id
	lappend elements_list \
	    p${group_id}_read_p [list \
				     label "[im_gif $profile_gif $group_name]" \
				     display_template "@reports.p${group_id}_read_p;noquote@" \
				    ]
	
	append main_sql_select "\tim_object_permission_p(m.menu_id, $group_id, 'read') as p${group_id}_read_p,\n"
    }

}


# ---------------------------------------------------
# 

set top_menu_sortkey [db_string top_menu_sortkey "
	select tree_sortkey 
	from im_menus 
	where label = 'reporting'
" -default ""]

list::create \
        -name report_list \
        -multirow reports \
        -key menu_id \
        -elements $elements_list \
        -filters {
        	return_url
        }

db_multirow -extend {indent_spaces edit_html} reports get_reports "
	select
		r.report_id,
		$main_sql_select
		m.*,
	        length(tree_sortkey) as indent_level,
	        (9-length(tree_sortkey)) as colspan_level
	from
	        im_menus m
		LEFT OUTER JOIN im_reports r ON (r.report_menu_id = m.menu_id)
	where
		(m.enabled_p = 't' OR m.enabled_p is null) and
	        tree_sortkey like '$top_menu_sortkey%'
		and 't' = im_object_permission_p(m.menu_id, :current_user_id, 'read')
		and m.label != 'reporting'
	order by tree_sortkey
" {
    # Pass the report name though the localization system
    regsub -all {[^0-9a-zA-Z]} $name "_" name_key
    set name [lang::message::lookup "" "intranet-reporting.$name_key" $name]

    set indent_spaces ""
    for {set i 0} {$i < $indent_level} {incr i} {
	append indent_spaces "&nbsp;"
    }

    # Show an "edit" icon for dynamic reports
    set edit_html "<a href='[export_vars -base "new" {report_id}]'>[im_gif "wrench"]</a>"
    if {"" == $report_id} { 
	set edit_html "" 
    } else {
	set url [export_vars -base "view" {report_id}]
    }

    # Format the group permission display
    foreach gid $group_list {

	set varname "p${gid}_read_p"
	set t_or_f [set $varname]
	if {"t" == $t_or_f} {
	    set toggle_url [export_vars -base "/intranet/admin/toggle" {{action remove_readable} {horiz_group_id $gid} {object_id $menu_id} return_url}]
	    set p${gid}_read_p "<a href='$toggle_url'><b>R</b></a>\n"
	} else {
	    set toggle_url [export_vars -base "/intranet/admin/toggle" {{action add_readable} {horiz_group_id $gid} {object_id $menu_id} return_url}]
	    set p${gid}_read_p "<a href='$toggle_url'>r</a>\n"
	}

	if {$indent_level < 5} {
	    set p${gid}_read_p ""
	}

    }
}

# Sort the multirow according to 
multirow_sort_tree reports menu_id parent_menu_id name



# ------------------------------------------------------
# Left Menu
# ------------------------------------------------------

set left_menu_html ""

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
        <div class='filter-block'>
                <div class='filter-title'>
                   [lang::message::lookup "" intranet-reporting.Admin_Reports "Admin Reports"]
                </div>
		<ul>
		<li><a href=\"[export_vars -base "/intranet-reporting/new" {{form_mode edit}}]\">[_ intranet-reporting.New_Report]</a>
		</ul>
        </div>
	<hr/>
"
if {!$user_admin_p} { set left_navbar_html "" }
