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

set page_title "[_ intranet-reporting.Manage_Reports]"
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action_list [list "[_ intranet-reporting.Add_new_Report]" "[export_vars -base "new" {return_url}]" "[_ intranet-reporting.Add_new_Report]"]

set elements_list {
  report_id {
    label "[_ intranet-reporting.Report_Id]"
  }
  report_name {
    label "[_ intranet-reporting.Report_Name]"
    display_template {
	    <a href="@reports.report_url@">@reports.report_name@</a>
    }
  }
  view_name {
	label "[_ intranet-reporting.View_Name]"
  }
  report_type {
  	label "[_ intranet-reporting.Report_Type]"
  }
  report_status {
  	label "[_ intranet-reporting.Report_Status]"
  }  
}

list::create \
        -name report_list \
        -multirow reports \
        -key report_id \
        -actions $action_list \
        -elements $elements_list \
        -filters {
        	return_url
        }
        
db_multirow -extend {report_url} reports get_reports { 
	select 	r.report_id,
		r.report_name,
		c.category as report_type,
		c2.category as report_status,
		v.view_name as view_name 
	from im_reports r
		LEFT OUTER JOIN
	     im_views v ON r.view_id = v.view_id
		LEFT OUTER JOIN
	     im_categories c ON r.report_type_id = c.category_id
	     	LEFT OUTER JOIN
	     im_categories c2 ON r.report_status_id = c2.category_id
	order by r.report_name	 
} {
	set report_url [export_vars -base "new" {report_id return_url}]
}