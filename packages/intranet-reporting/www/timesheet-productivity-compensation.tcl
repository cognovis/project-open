# /packages/intranet-reporting/www/timesheet-productivity.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
# 
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {

    Report for the componsation

    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { start_date "" }
    { level_of_detail 1 }
    { output_format "html" }
    { user_id 0 }
    { manager_id 0}
    { no_assignment_project_type_id "10000031"}
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

set page_title "Timesheet Productivity Report"
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
set hours_per_day [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter TimesheetHoursPerDay -default "8.0"]
set work_days_per_year [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter TimesheetWorkDaysPerYear -default "210.0"]


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

set levels {1 "User Only" 2 "User+Company" 3 "User+Company+Project" 4 "All Details" 5 "Absences"} 
set num_format "999,990.99"

set label_diff_worked_workable_hours  [lang::message::lookup "" intranet-reporting.DiffWorkedWorkableHours "Workable-Worked"]
set label_compensation_hours  [lang::message::lookup "" intranet-reporting.CompensationHours "Compensation Hours"]
set label_ratio_workable_hours_to_external_hours  [lang::message::lookup "" intranet-reporting.RatioWorkableExternal "Ratio: Workable/External"]

# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]
set abs_criteria [list]
if {[info exists user_id] && 0 != $user_id && "" != $user_id} {
    lappend criteria "h.user_id = :user_id"
    lappend abs_criteria "owner_id = :user_id"
}

if {[exists_and_not_null manager_id]} {
    lappend criteria "h.user_id in (select employee_id from im_employees where supervisor_id = :manager_id)"
    lappend abs_criteria "owner_id in (select employee_id from im_employees where supervisor_id = :manager_id)"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set abs_where_clause [join $abs_criteria " and\n            "]
if { ![empty_string_p $abs_where_clause] } {
    set abs_where_clause " and $abs_where_clause"
}

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set date_list [split $start_date "-"]
set year [lindex $date_list 0]
set month [lindex $date_list 1]


set num_days [db_string num_days "SELECT date_part('day', (:year || '-' || :month || '-01') ::date + '1 month'::interval - '1 day'::interval)" ]
set end_date "${year}-${month}-$num_days"

set inner_sql "
select
	h.day::date as date,
	h.user_id,
        p.parent_id as project_id,
	p2.company_id,
	h.hours as hours,
	e.availability,
        p.project_type_id
from
	im_hours h,
	im_projects p,
        im_projects p2,
        im_timesheet_tasks t,
	users u
	LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
where
	h.project_id = t.task_id
	and p2.project_status_id not in ([im_project_status_deleted])
	and h.user_id = u.user_id
	and h.day >= to_date(:start_date, 'YYYY-MM')
	and h.day <= to_date(:end_date, 'YYYY-MM-DD')
	and :start_date = to_char(h.day, 'YYYY-MM')
        and p2.project_id = p.parent_id
        and t.task_id = p.project_id
	$where_clause
UNION
select
	h.day::date as date,
	h.user_id,
        p.project_id as project_id,
	p.company_id,
	h.hours as hours,
	e.availability,
        p.project_type_id
from
	im_hours h,
	im_projects p,
	users u
	LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
where
	h.project_id = p.project_id
	and p.project_status_id not in ([im_project_status_deleted])
	and h.user_id = u.user_id
	and h.day >= to_date(:start_date, 'YYYY-MM')
	and h.day <= to_date(:end_date, 'YYYY-MM-DD')
	and :start_date = to_char(h.day, 'YYYY-MM')
        and project_type_id != [im_project_type_task]
	$where_clause

"

if {$level_of_detail == 5} {
    set level_of_detail 4
    # Absences only!

    set sql "
select  start_date::date as date,
        100 as availability,
        (select count(distinct absence_query.days) * $hours_per_day from (select * from im_absences_month_absence_type (owner_id, :month, :year, absence_type_id) AS (days date)) absence_query) as hours,
        0 as hours_intl,
        0 as hours_extl,
        0 as hours_no_assignment,
        (select count(distinct absence_query.days) * $hours_per_day from (select * from im_absences_month_absence_type (owner_id, :month, :year, absence_type_id) AS (days date)) absence_query) as hours_absence,
        owner_id as user_id,
        im_name_from_user_id(owner_id) as user_name,
        absence_type_id as project_id,
        im_name_from_id(absence_type_id) as project_nr,
        im_name_from_id(absence_type_id) as project_name,
        9999999 as company_id,
        'Absences' as company_nr,
        'Absences' as company_name
from 
        im_user_absences
where 
	start_date <= to_date(:end_date, 'YYYY-MM-DD') and
        end_date >= to_date(:start_date, 'YYYY-MM')
        $abs_where_clause
order by
	user_name,
	company_id,
	project_id,
	date
"

} else {
set sql "
select * from (
select
        s.date,
        s.availability,
        s.hours,
	CASE c.company_id = :internal_company_id WHEN true THEN s.hours ELSE 0 END as hours_intl,
	CASE c.company_id != :internal_company_id WHEN true THEN s.hours ELSE 0 END as hours_extl,
        CASE p.project_type_id = :no_assignment_project_type_id WHEN true THEN s.hours ELSE 0 END as hours_no_assignment,
        0 as hours_absence,
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name,
	p.project_id,
	p.project_nr,
	p.project_name,
	c.company_id,
	c.company_path as company_nr,
	c.company_name
from
	($inner_sql) s,
	im_companies c,
	im_projects p,
	cc_users u
where
	s.user_id = u.user_id
	and p.project_status_id not in ([im_project_status_deleted])
	and s.company_id = c.company_id
	and s.project_id = p.project_id

UNION

select  start_date::date as date,
        100 as availability,
        (select count(distinct absence_query.days) * $hours_per_day from (select * from im_absences_month_absence_type (owner_id, :month, :year, absence_type_id) AS (days date)) absence_query) as hours,
        0 as hours_intl,
        0 as hours_extl,
        0 as hours_no_assignment,
        (select count(distinct absence_query.days) * $hours_per_day from (select * from im_absences_month_absence_type (owner_id, :month, :year, absence_type_id) AS (days date)) absence_query) as hours_absence,
        owner_id as user_id,
        im_name_from_user_id(owner_id) as user_name,
        absence_type_id as project_id,
        im_name_from_id(absence_type_id) as project_nr,
        im_name_from_id(absence_type_id) as project_name,
        9999999 as company_id,
        'Absences' as company_nr,
        'Absences' as company_name
from 
        im_user_absences
where 
	start_date <= to_date(:end_date, 'YYYY-MM-DD') and
        end_date >= to_date(:start_date, 'YYYY-MM')
        $abs_where_clause
) hours_and_absences
order by
	user_name,
	company_id,
	project_id,
	date

"
}

set report_def [list \
    group_by user_id \
    header {
	"\#colspan=9 <b><a href=$user_url$user_id>$user_name</a></b>"
    } \
    content [list  \
	group_by company_id \
	header {
	    ""
	    $company_name_pretty
	} \
	content [list \
	    group_by project_id \
	    header {
		""
		""
		$project_name_pretty
	    } \
	    content [list \
		    header {
			"" 
			""
			""
			"" ""
			$hours_intl
			$hours_extl
		        $hours_absence
			$hours
		    } \
		    content {} \
	    ] \
	    footer {
		"" 
		""
		""
		"" ""
		"<small>$hours_project_intl_subtotal</small>" 
		"<small>$hours_project_extl_subtotal</small>" 
		"<small>$hours_project_absence_subtotal</small>" 
		"<small>$hours_project_subtotal</small>" 
	    } \
	] \
	footer {
	    "" 
	    "" "" "" ""
	    "<i>$hours_company_intl_subtotal</i>" 
	    "<i>$hours_company_extl_subtotal</i>" 
	    "<i>$hours_company_absence_subtotal</i>" 
	    "<i>$hours_company_subtotal</i>" 
	} \
    ] \
    footer {
	"" 
	"" "" "" 
	"<b>$availability %</b> &nbsp;"
	"<b>$hours_user_intl_subtotal</b>" 
	"<b>$hours_user_extl_subtotal</b>" 
	"" 
	"<b>$hours_user_subtotal</b>" 
    } \
]

# Global header/footer
set header0 {"Employee" "Customer" "Project" "&nbsp;" Avail "Intl<br>Hours" "Extl<br>Hours" "Absence<br/>Hours" "Total<br>Hours"}
set footer0 {"" "" "" "" "" "" "" "" ""}

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

set hours_user_no_assignment_counter [list \
	pretty_name HoursNoAssignment \
	var hours_user_no_assignment_subtotal \
	reset \$user_id \
	expr \$hours_no_assignment
]

set hours_company_counter [list \
	pretty_name Hours \
	var hours_company_subtotal \
	reset \$company_id \
	expr \$hours
]

set hours_company_intl_counter [list \
	pretty_name HoursIntl \
	var hours_company_intl_subtotal \
	reset \$company_id \
	expr \$hours_intl
]

set hours_company_extl_counter [list \
	pretty_name HoursExtl \
	var hours_company_extl_subtotal \
	reset \$company_id \
	expr \$hours_extl
]

set hours_company_absence_counter [list \
	pretty_name HoursAbsence \
	var hours_company_absence_subtotal \
	reset \$company_id \
	expr \$hours_absence
]

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

set hours_project_absence_counter [list \
	pretty_name HoursAbsence \
	var hours_project_absence_subtotal \
	reset \$project_id \
	expr \$hours_absence
]

set counters [list \
	$hours_user_counter \
	$hours_user_intl_counter \
	$hours_user_extl_counter \
	$hours_user_no_assignment_counter \
	$hours_company_counter \
	$hours_company_intl_counter \
	$hours_company_extl_counter \
	$hours_project_counter \
	$hours_project_intl_counter \
	$hours_project_extl_counter \
	$hours_project_absence_counter \
	$hours_company_absence_counter \
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
		  <td class=form-label>Manager</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -group_id [im_profile_employees] manager_id $manager_id]
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

set previous_user_id ""
set previous_user_name ""

db_foreach sql $sql {

    # Does the user prefer to read project_name instead of project_nr? (Genedata...)
    if {$use_project_name_p} {
	set project_nr $project_name
	set project_name [im_reporting_sub_project_name_path -exlude_main_project_p 0 $project_id]
	set user_initials $user_name
	set company_nr $company_name
    }

    # Find out if these are absences. Then the company_id is 9999999
    if {$company_id == "9999999"} {
	set company_name_pretty "\#colspan=8 <b>$company_name</b>"
	set project_name_pretty "\#colspan=7 <b>$project_name</b>"
    } else {
	set company_name_pretty "\#colspan=8 <b><a href=$company_url$company_id>$company_name</a></b>"
	set project_name_pretty "\#colspan=7 <b><a href=$project_url$project_id>$project_name</a></b>"
    }

    if {$previous_user_id == ""} {
	set previous_user_id $user_id
	set previous_user_name $user_name
    }

    im_report_display_footer \
	-output_format $output_format \
	-group_def $report_def \
	-footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list \
	-level_of_detail $level_of_detail \
	-row_class $class \
	-cell_class $class

    # Figure out if we are already changing the user

    if {$user_id ne $previous_user_id} {
	set previous_user_id $user_id
	# Now display the additional row for the last user as well
	set working_hours [db_string working_days "select count(*) * $hours_per_day as working_hours from (select * from im_absences_working_days_month(:previous_user_id,:month,:year) t(days int))ct" -default 0]
	set workable_hours [expr $working_hours + $hours_company_absence_subtotal]
	
	set hours_diff [expr $hours_user_subtotal - $workable_hours]
	im_report_render_row \
	    -output_format $output_format \
	    -row [list "$label_diff_worked_workable_hours" "" "" "" "" "" "" "" "<b>$hours_diff</b>"] \
	    -row_class "rowodd" \
	    -cell_class "rowodd"
	
	set compensation_hours [expr $hours_diff - $hours_user_no_assignment_subtotal]
	im_report_render_row \
	    -output_format $output_format \
	    -row [list "$label_compensation_hours" "" "" "" "" "" "" "" "<b>$compensation_hours</b>"] \
	    -row_class "rowodd" \
	    -cell_class "rowodd"
	
	set working_percent [format "%0.2f" [expr (($hours_user_subtotal - $hours_company_absence_subtotal) / $workable_hours)*100]]%
	
	im_report_render_row \
	    -output_format $output_format \
	    -row [list "$label_ratio_workable_hours_to_external_hours" "" "" "" "" "" "" "" "<b>$working_percent</b>"] \
	    -row_class "rowodd" \
	    -cell_class "rowodd"
	
    }    
    
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

if {[info exists hours_company_absence_subtotal]} {
    # Now display the additional row for the last user as well
    set working_hours [db_string working_days "select count(*) * $hours_per_day as working_hours from (select * from im_absences_working_days_month(:previous_user_id,:month,:year) t(days int))ct" -default 0]
    set workable_hours [expr $working_hours + $hours_company_absence_subtotal]
    
    set hours_diff [expr $hours_user_subtotal - $workable_hours]
    im_report_render_row \
	-output_format $output_format \
	-row [list "$label_diff_worked_workable_hours" "" "" "" "" "" "" "" "<b>$hours_diff</b>"] \
	-row_class "rowodd" \
	-cell_class "rowodd"
    
    set compensation_hours [expr $hours_diff - $hours_user_no_assignment_subtotal]
    im_report_render_row \
	-output_format $output_format \
	-row [list "$label_compensation_hours" "" "" "" "" "" "" "" "<b>$compensation_hours</b>"] \
	-row_class "rowodd" \
	-cell_class "rowodd"
    
    set working_percent [format "%0.2f" [expr (($hours_user_subtotal - $hours_company_absence_subtotal) / $workable_hours)*100]]%
    
    im_report_render_row \
	-output_format $output_format \
	-row [list "$label_ratio_workable_hours_to_external_hours" "" "" "" "" "" "" "" "<b>$working_percent</b>"] \
	-row_class "rowodd" \
	-cell_class "rowodd"
    
}

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class


switch $output_format {
    html { ns_write "</table>\n[im_footer]\n" }
}
