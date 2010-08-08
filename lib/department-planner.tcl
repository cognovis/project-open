# /packages/intranet-portfolio-management/lib/department-planner.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.

# Expects the variables:
# - start_date
# - end_date
# - view_name


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


# Check that Start & End-Date have correct format
im_date_ansi_to_julian $start_date
im_date_ansi_to_julian $end_date


# ---------------------------------------------------------------
# Get the multirow for the table
# ---------------------------------------------------------------

# Get the "department_planner" multirows:
#	- dynview_columns: The first columns with priority, project name 
#	  and customer extensible columns
#	- cost_centers:
#	  The list of cost centers to be shown.
#	- department_planner:
#	  The main "body" of the planner: One row per project,
#	  with columns for DynView and CostCenters
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

    # Set the hash values for the columns, so that the body can subtract
    # the project's required days from the days available at the cost center
    set remaining_days($cost_center_id) $department_planner_days_per_year
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
	set rem_days [expr $remaining_days($cost_center_id) - $$cc_var]
	set remaining_days($cost_center_id) $rem_days

	set bgcolor_html "bgcolor=\#80FF80"
	if {$rem_days < 0.0} { set bgcolor_html "bgcolor=\#FF8080" }
	append body_html "<td $bgcolor_html>$rem_days</td>"
    }
    append body_html "</tr>\n"

}

