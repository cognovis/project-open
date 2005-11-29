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

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
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
        
db_multirow -extend {report_url indent_spaces} reports get_reports "
	select
		m.*,
	        length(tree_sortkey) as indent_level,
	        (9-length(tree_sortkey)) as colspan_level
	from
	        im_menus m
	where
	        tree_sortkey like '$top_menu_sortkey%'
	order by tree_sortkey
" {
	set report_url [export_vars -base "new" {menu_id return_url}]

	set indent_spaces ""
	for {set i 0} {$i < $indent_level} {incr i} {
	    append indent_spaces "&nbsp;"
	}
}


