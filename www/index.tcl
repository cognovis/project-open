# /packages/intranet-reporting/www/index.tcl
#
# Copyright (C) 2004 Project/Open
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
set reports_exist_p [db_table_exists "im_reports"]

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting"

set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}


if {"" == $return_url} { set return_url [ad_conn url] }

set page_title [lang::message::lookup "" intranet-reporting.Available_Reports "Available Reports"]
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action_list [list "[_ intranet-reporting.Add_new_Report]" "[export_vars -base "new" {return_url}]" "[_ intranet-reporting.Add_new_Report]"]

set elements_list {
    name {
	label $page_title
	display_template {
	    <if @reports.indent_level@ gt 4>
	    @reports.indent_spaces;noquote@ 
	    <a href="@reports.url@">@reports.name@</a>
	    </if>
	    <else>
	    <b>@reports.name@</b>
	    </else>
	}
    }
}


if {$reports_exist_p && $user_admin_p} {
    lappend elements_list \
        edit {
            label "[im_gif wrench]"
            display_template {
                @reports.edit_html;noquote@
            }
        }
}



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
        

if {$reports_exist_p} {

    set report_sql "
	select	report_id,
		report_menu_id
	from	im_reports
	where	report_type_id = [im_report_type_simple_sql]
    "
    db_foreach reports $report_sql {
	set report($report_menu_id) $report_id
    }

}


db_multirow -extend {report_url indent_spaces edit_html} reports get_reports "
	select
		m.*,
	        length(tree_sortkey) as indent_level,
	        (9-length(tree_sortkey)) as colspan_level
	from
	        im_menus m
	where
	        tree_sortkey like '$top_menu_sortkey%'
		and 't' = im_object_permission_p(m.menu_id, :current_user_id, 'read')
	order by tree_sortkey
" {
    set report_url [export_vars -base "new" {menu_id return_url}]
    
    set indent_spaces ""
    for {set i 0} {$i < $indent_level} {incr i} {
	append indent_spaces "&nbsp;"
    }
    
    set report_id 0
    if {[info exists report($menu_id)]} { set report_id $report($menu_id) }
    set edit_html "<a href='[export_vars -base "new" {report_id}]'>[im_gif "wrench"]</a>"
    if {0 == $report_id} { set edit_html "" }
}


