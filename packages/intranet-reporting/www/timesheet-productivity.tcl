# /packages/intranet-reporting/www/timesheet-productivity.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { start_date "" }
    { level_of_detail 1 }
    { output_format "html" }
    { user_id 0 }
}

# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-timesheet-productivity"
set current_user_id [ad_maybe_redirect_for_registration]
set use_project_name_p [parameter::get_from_package_key -package_key intranet-reporting -parameter "UseProjectNameInsteadOfProjectNr" -default 0]

set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

set page_title  [lang::message::lookup "" intranet-reporting.Timesheet_Logging "Timesheet Productivity Report"]
set context_bar [im_context_bar $page_title]
set context ""


# Start data - end date doesn't make sense for this report.
# However, when called from the Project Timesheet Component,
# the page will set start- and end date to 2000-01-01 and 2100-01-01.
# In this case overwrite the date and set to current month.
if {"2000-01-01" == $start_date} { set start_date "" }


# Check that Start-Date have correct format
set start_date [string range $start_date 0 6]
if {"" != $start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]$} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM'"
}

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

set days_in_past 0

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month
from dual
"

if {"" == $start_date} { 
    set start_date "$todays_year-$todays_month"
}

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="

set this_url [export_vars -base "/intranet-reporting/timesheet-productivity" {start_date} ]

set internal_company_id [im_company_internal]

set levels {1 "User Only" 2 "User+Company" 3 "User+Company+Project" 4 "All Details"} 

set num_format "999,990.99"


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {[info exists user_id] && 0 != $user_id && "" != $user_id} {
    lappend criteria "h.user_id = :user_id"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}



# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set inner_sql "
select
	h.day::date as date,
	h.user_id,
	p.project_id,
	p.company_id,
	h.hours as hours,
	h.note,
	h.billing_rate,
	e.availability,
	to_char(e.salary, :num_format) || '&nbsp;' || e.currency as salary,
	to_char(e.social_security, :num_format) || '&nbsp;' || e.currency as social_security,
	to_char(e.insurance, :num_format) || '&nbsp;' || e.currency as insurance,
	to_char(e.other_costs, :num_format) || '&nbsp;' || e.currency as other_costs,
	to_char(e.hourly_cost, :num_format) || '&nbsp;' || e.currency as hourly_cost,
	e.currency,
	e.salary_payments_per_year,
	(e.salary + e.social_security + e.insurance + e.other_costs) * e.salary_payments_per_year / 12 as total_cost
from
	im_costs co,
	im_hours h,
	im_projects p,
	users u
	LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
where
	h.cost_id = co.cost_id
	and h.project_id = p.project_id
	and p.project_status_id not in ([im_project_status_deleted])
	and h.user_id = u.user_id
	and h.day >= to_date(:start_date, 'YYYY-MM')
	and h.day < to_date(:start_date, 'YYYY-MM') + 31
	and :start_date = to_char(h.day, 'YYYY-MM')
	$where_clause
"

set sql "
select
	s.*,
	CASE c.company_id = :internal_company_id WHEN true THEN s.hours ELSE 0 END as hours_intl,
	CASE c.company_id != :internal_company_id WHEN true THEN s.hours ELSE 0 END as hours_extl,
	to_char(s.date, 'YYYY-MM-DD') as date,
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name,
	p.project_id,
	p.project_nr,
	p.project_name,
	c.company_id,
	c.company_path as company_nr,
	c.company_name,
	to_char(s.hours, :num_format) as hours_pretty,
	to_char(s.total_cost, :num_format) as total_cost_pretty,
	100000.0 * coalesce(u.user_id, 1) + coalesce(c.company_id, 1) as user_company_prod
from
	($inner_sql) s,
	im_companies c,
	im_projects p,
	users u
where
	s.user_id = u.user_id
	and p.project_status_id not in ([im_project_status_deleted])
	and s.company_id = c.company_id
	and s.project_id = p.project_id
order by
	user_name,
	s.company_id,
	p.project_id,
	s.date
"

set report_def [list \
    group_by user_id \
    header {
	"\#colspan=99 <b><a href=$user_url$user_id>$user_name</a></b>"
    } \
    content [list  \
	group_by company_id \
	header {
	    $user_name
	    "\#colspan=99 <b><a href=$company_url$company_id>$company_name</a></b>"
	} \
	content [list \
	    group_by project_id \
	    header {
		$user_name
		$company_nr 
		"\#colspan=99 <b><a href=$project_url$project_id>$project_name</a></b>"
	    } \
	    content [list \
		    header {
			$user_name
			$company_nr
			$project_nr
			$date
			"" "" "" "" "" "" "" "" ""
			$hours_intl
			$hours_extl
			""
			$hours
		    } \
		    content {} \
	    ] \
	    footer {
		$user_name
		$company_nr 
		$project_nr 
		"" "" "" "" "" "" "" "" "" ""
		"<small>$hours_project_intl_subtotal</small>" 
		"<small>$hours_project_extl_subtotal</small>" 
		"" 
		"<small>$hours_project_subtotal</small>" 
	    } \
	] \
	footer {
	    $user_name 
	    "" "" "" "" "" "" "" "" "" "" "" ""
	    "<i>$hours_company_intl_subtotal</i>" 
	    "<i>$hours_company_extl_subtotal</i>" 
	    "" 
	    "<i>$hours_company_subtotal</i>" 
	} \
    ] \
    footer {
	$user_name 
	"" "" ""
	"$availability %"
        $salary
        $social_security
        $insurance
        $other_costs
        $salary_payments_per_year
        "<b>$total_cost_pretty $currency</b>"
        $hourly_cost
	""
	"<b>$hours_user_intl_subtotal</b>" 
	"<b>$hours_user_extl_subtotal</b>" 
	"" 
	"<b>$hours_user_subtotal</b>" 
    } \
]

# Global header/footer
set header0 {"Employee" "Customer" "Project" "Date" Avail Salary SS Ins Other "\#Pay" Total "Hourly<br>Rate" "&nbsp;" "Intl<br>Hours" "Extl<br>Hours" "&nbsp;" "Total<br>Hours"}
set footer0 {"" "" "" "" "" "" "" "" ""}

# --------------------------------------------------------------
set hours_user_counter [list \
	pretty_name Hours \
	var hours_user_subtotal \
	reset \$user_id \
	expr \$hours
]

set hours_user_intl_counter [list \
	pretty_name HoursIntl \
	var hours_user_intl_subtotal \
	reset \$user_id \
	expr \$hours_intl
]

set hours_user_extl_counter [list \
	pretty_name HoursExtl \
	var hours_user_extl_subtotal \
	reset \$user_id \
	expr \$hours_extl
]

# --------------------------------------------------------------
set hours_company_counter [list \
	pretty_name Hours \
	var hours_company_subtotal \
	reset \$user_company_prod \
	expr \$hours
]

set hours_company_intl_counter [list \
	pretty_name HoursIntl \
	var hours_company_intl_subtotal \
	reset \$user_company_prod \
	expr \$hours_intl
]

set hours_company_extl_counter [list \
	pretty_name HoursExtl \
	var hours_company_extl_subtotal \
	reset \$user_company_prod \
	expr \$hours_extl
]

# --------------------------------------------------------------
set hours_project_counter [list \
	pretty_name Hours \
	var hours_project_subtotal \
	reset \$project_id \
	expr \$hours
]

set hours_project_intl_counter [list \
	pretty_name HoursIntl \
	var hours_project_intl_subtotal \
	reset \$project_id \
	expr \$hours_intl
]

set hours_project_extl_counter [list \
	pretty_name HoursExtl \
	var hours_project_extl_subtotal \
	reset \$project_id \
	expr \$hours_extl
]

set counters [list \
	$hours_user_counter \
	$hours_user_intl_counter \
	$hours_user_extl_counter \
	$hours_company_counter \
	$hours_company_intl_counter \
	$hours_company_extl_counter \
	$hours_project_counter \
	$hours_project_intl_counter \
	$hours_project_extl_counter \
]


# ------------------------------------------------------------
# Start formatting the page
#

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

# Add the HTML select box to the head of the page
switch $output_format {
    html {
        ns_write "
	[im_header]
	[im_navbar]
	<form>
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
		  <td class=form-label>Level of Details</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Month</td>
		  <td class=form-widget>
		    <input type=textfield name=start_date value=$start_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>User</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 user_id $user_id]
		  </td>
		</tr>
                <tr>
                  <td class=form-label>Format</td>
                  <td class=form-widget>
                    [im_report_output_format_select output_format "" $output_format]
                  </td>
                </tr>
		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value=Submit></td>
		</tr>
		</table>
	</form>
	<table border=0 cellspacing=1 cellpadding=1>\n"
    }
}

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"
db_foreach sql $sql {
    
    # Does the user prefer to read project_name instead of project_nr? (Genedata...)
    if {$use_project_name_p} {
	set project_nr $project_name
	set project_name [im_reporting_sub_project_name_path -exlude_main_project_p 0 $project_id]
	set user_initials $user_name
	set company_nr $company_name
    }


    im_report_display_footer \
	-output_format $output_format \
	-group_def $report_def \
	-footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list \
	-level_of_detail $level_of_detail \
	-row_class $class \
	-cell_class $class
    
    im_report_update_counters -counters $counters
    
    set last_value_list [im_report_render_header \
			     -output_format $output_format \
			     -group_def $report_def \
			     -last_value_array_list $last_value_list \
			     -level_of_detail $level_of_detail \
			     -row_class $class \
			     -cell_class $class
			]
    
    set footer_array_list [im_report_render_footer \
			       -output_format $output_format \
			       -group_def $report_def \
			       -last_value_array_list $last_value_list \
			       -level_of_detail $level_of_detail \
			       -row_class $class \
			       -cell_class $class
			  ]
}

im_report_display_footer \
    -output_format $output_format \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class


switch $output_format {
    html { ns_write "</table>\n[im_footer]\n" }
}
