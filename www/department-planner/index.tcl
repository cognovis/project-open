# /packages/intranet-project-portfolio-mgmt/www/department-planner/index.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows a portfolio of projects ordered by priority.
    The assigned work days to the project's tasks are deduced from the
    resources available per cost_center.

    Note: There is only a single portfolio here, as the cost center's 
    resources are not separated per portfolio.

    @author frank.bergmann@project-open.com
} {
    { start_date "" }
    { end_date "" }
    { view_name "" }
}


# ---------------------------------------------------------------
# Title
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-portfolio-mgmt.Department_Planner "Department Planner"]
set context_bar [im_context_bar $page_title]

# ---------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set current_user_id [im_require_login]
set menu_label "reporting-department-planner"
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']
set read_p "t"
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

set project_base_url "/intranet/projects/view"
set this_base_url "/intranet-portfolio-management/department-planner/index"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "


# ---------------------------------------------------------------
# Start and End Date
# ---------------------------------------------------------------

db_1row todays_date "
select
        to_char(sysdate::date, 'YYYY') as todays_year,
        to_char(sysdate::date, 'MM') as todays_month,
        to_char(sysdate::date, 'DD') as todays_day
from dual
"

if {"" == $start_date} { set start_date "$todays_year-01-01" }
if {"" == $end_date} { set end_date "[expr $todays_year+1]-01-01" }

# Check that Start & End-Date have correct format
im_date_ansi_to_julian $start_date
im_date_ansi_to_julian $end_date

# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

set filter_html "
	<form method=GET name=filter action='$this_base_url'>
	[export_form_vars]
	<table border=0 cellpadding=0 cellspacing=1>
"

append filter_html "
	<tr>
	<td class=form-label>[_ intranet-core.Start_Date]</td>
        <td class=form-widget><input type=textfield name=start_date value=$start_date></td>
	</tr>
	<tr>
	<td class=form-label>[lang::message::lookup "" intranet-core.End_Date "End Date"]</td>
        <td class=form-widget><input type=textfield name=end_date value=$end_date></td>
	</tr>
"

append filter_html "
  <tr>
    <td class=form-label></td>
    <td class=form-widget>
	  <input type=submit value='[lang::message::lookup "" intranet-core.Action_Go "Go"]' name=submit>
    </td>
  </tr>
"

append filter_html "</table>\n</form>\n"

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
		[lang::message::lookup "" intranet-core.Filter "Filter"]
        	</div>
            	$filter_html
      	</div>
      <hr/>
"


# ---------------------------------------------------------------
# Get the multirow for the table
# ---------------------------------------------------------------

# Get the "department_planner" multirow.
# The procedure returns the three lists:
#	1. The list of localized column titles
#	2. The list of multirow names for the columns
#
set error_html [im_department_planner_get_list_multirow \
		 -start_date $start_date \
		 -end_date $end_date \
		 -view_name $view_name \
]


# ---------------------------------------------------------------
# Build the header from multirows
# ---------------------------------------------------------------

set header_html ""
template::multirow foreach dynview_columns {
    append header_html "<td class=rowtitle>$column_title</td>"
}
template::multirow foreach cost_centers {
    append header_html "<td class=rowtitle>$cost_center_name</td>"
}
set header_html "<tr class=rowtitle>$header_html</tr>\n"

# ---------------------------------------------------------------
# Build the first line from multirows
# ---------------------------------------------------------------

set first_line_html ""
template::multirow foreach dynview_columns {
    append first_line_html "<td class=rowtitle>&nbsp;</td>\n"
}
template::multirow foreach cost_centers {
    append first_line_html "<td class=rowtitle>$department_planner_days_per_year</td>\n"
}
set first_line_html "<tr class=rowtitle>$first_line_html</tr>\n"


# ---------------------------------------------------------------
# Build the table body from multirows
# ---------------------------------------------------------------

set body_html ""
template::multirow foreach department_planner {

    append body_html "<tr>\n"
    template::multirow foreach dynview_columns {
	set dynview_var "col_$column_ctr"
	set dynview_val [expr $$dynview_var]
	append body_html "<td>$dynview_val</td>"
    }
    template::multirow foreach cost_centers {
	set cc_var "cc_$cost_center_id"
	set cc_val [expr $$cc_var]
	set bgcolor_html "bgcolor=\#80FF80"
	if {$cc_val < 0.0} { set bgcolor_html "bgcolor=\#FF8080" }
	append body_html "<td $bgcolor_html>$cc_val</td>"
    }
    append body_html "</tr>\n"

}
