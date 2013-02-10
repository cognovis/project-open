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
    { project_id "" }
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

if {![info exists start_date] || "" == $start_date} { set start_date "$todays_year-01-01" }
if {![info exists end_date] || "" == $end_date} { set end_date "[expr $todays_year+1]-01-01" }

set report_start_date $start_date
set report_end_date $end_date


# ---------------------------------------------------------------
# Sub-Menu
# ---------------------------------------------------------------

set sub_navbar ""
set main_navbar_label "resource_management"
set bind_vars [ns_set create]
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label = 'resource_management'" -default ""]
set sub_navbar [im_sub_navbar \
                    -base_url "/intranet-resource-management/index" \
                    -plugin_url "/intranet-resource-management/index" \
                    -menu_gif_type "none" \
                    $parent_menu_id \
		    $bind_vars "" "pagedesriptionbar" "department_planner" \
		    ]


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

