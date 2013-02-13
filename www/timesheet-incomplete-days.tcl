# /packages/intranet-reporting/www/timesheet-incomplete-days.tcl
#
# Copyright (C) 2003 - 2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    @param start_date 
    @param end_date 
} {
    { start_date "" }
    { end_date "" }
    { level_of_detail 3 }
    { output_format "html" }
    { user_id:optional }
    { cost_center_id 0 }
    { department_id 0 }
}

# ------------------------------------------------------------
# Security & Permissions
# ------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Check privileges 
set view_hours_all_p [im_permission $current_user_id view_hours_all]
if { [im_is_user_site_wide_or_intranet_admin $current_user_id] } { set view_hours_all_p 1 }
if { !$view_hours_all_p }  {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# Provides MENU security context for this report
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = 'timesheet-incomplete-days'
" -default 'f']

if {![string equal "t" $read_p] && ![im_is_user_site_wide_or_intranet_admin $current_user_id]} {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# ------------------------------------------------------------
# Validate form 
# ------------------------------------------------------------

# Preset dates 
if { "" == $start_date } { set start_date [clock format [clock scan $start_date] -format %Y-%m-01] }
if { "" == $end_date } { set end_date [clock format [clock add [clock add [clock scan $start_date] +1 month ] -1 day] -format %Y-%m-%d] }

# Check that Start & End-Date have correct format
if { $start_date != [dt_julian_to_ansi [dt_ansi_to_julian_single_arg $start_date]] } {
    ad_return_complaint 1 "<strong>Start Date</strong> doesn't have the right format or date is not valid.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"    
}

if { $end_date != [dt_julian_to_ansi [dt_ansi_to_julian_single_arg $end_date]] } {
    ad_return_complaint 1 "<strong>End Date</strong> doesn't have the right format or date is not valid.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if { [dt_ansi_to_julian_single_arg $start_date] > [dt_ansi_to_julian_single_arg $end_date] } {
    ad_return_complaint 1 "<strong>End Date</strong> must be later than <strong>Start Date</strong>"
}

set duration_in_days [expr [db_string get_data "select date_part('day', :end_date::timestamp - :start_date::timestamp)" -default 0] +1]

if { $duration_in_days > 365 } {
    ad_return_complaint 1 "Periods > 1 year are not allowed"
}

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

set date_format "YYYY-MM-DD"
set debug 0
set timesheet_hours_per_day [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "TimesheetHoursPerDay" -default 8]
set page_title [lang::message::lookup "" intranet-reporting.TimesheetIncompleteDays "Timesheet - Incomplete Days"]
set context_bar [im_context_bar $page_title]
set context ""
set todays_date [db_string todays_date "select to_char(now(), :date_format) from dual" -default ""]

set user_url "/intranet/users/view?user_id="

# Default values for start/end 


# include jQuery date picker
template::head::add_javascript -src "/intranet/js/jquery-ui.custom.min.js" -order "99"
template::head::add_css -href "/intranet/style/jquery/overcast/jquery-ui.custom.css" -media "screen" -order "99"

# ------------------------------------------------------------
# Conditional SQL Where-Clause
# ------------------------------------------------------------

set inner_where ""
set criteria_inner [list]

# Check for filter "Employee"  
if { [info exists user_id] && $user_id != "" } { lappend criteria_inner "user_id = :user_id" } else { set user_id ""}

# Check for filter "Cost Center"  
if { "0" != $cost_center_id &&  "" != $cost_center_id } {
        lappend criteria_inner "
        	user_id in (select employee_id from im_employees where department_id in (select object_id from acs_object_context_index where ancestor_id = $cost_center_id))
	"
}

# Check for filter "Department"  
if { "0" != $department_id &&  "" != $department_id } {
  	lappend criteria_inner "
                user_id in (
                        select employee_id from im_employees where department_id in (
                                select
                                        object_id
                                from
                                        acs_object_context_index
                                where
                                        ancestor_id = $department_id
                	)
           	)
        "
}

set skill_profile_id [im_profile_skill_profile]
if { 0 != $skill_profile_id  } {
        lappend criteria_inner "
		u.user_id not in (select object_id_two from acs_rels where object_id_one = :skill_profile_id) 
	"
}

# Create "inner where" 
if { ![empty_string_p $criteria_inner] } { 
   set inner_where [join $criteria_inner " and\n   "] 
} 
if {"" != $inner_where} { set inner_where "and $inner_where" }

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set day_placeholders ""
set day_header ""
set inner_sql_list [list]
set outer_sql_list [list]
set this_day $start_date

# Loop to generate SQL's and HEADER  
for { set i 0 } { $i < $duration_in_days } { incr i } {

    set this_day_key [clock format [clock scan "$this_day"] -format %Y%m%d]

    # Validate date
    if { [catch { set end_date_ansi [clock format [clock scan $this_day] -format %Y-%m-%d] } ""] } {
        ad_return_complaint 1 "Found wrong date, please contact your System Administrator"
    }

    lappend inner_sql_list "
    (select sum(hours) from im_hours h where h.user_id = s.user_id and date_trunc('day', day) = '$this_day') as day_$this_day_key,
    (select sum(duration_days) from im_absences_get_absences_for_user_duration(s.user_id, '$this_day', '$this_day', null) AS (absence_date date, absence_type_id int, absence_id int, duration_days numeric)) as duration_days_$this_day_key" 

    lappend outer_sql_list "
	((t.duration_days_$this_day_key * $timesheet_hours_per_day) + t.day_$this_day_key) as hours_total_$this_day_key
    " 
    append day_placeholders "\\" "\$hours_total_$this_day_key "

    # Setting headers 

    set date_elements [split $this_day -]
    set this_day_html "[lindex $date_elements 0]<br>[lindex $date_elements 1]<br>[lindex $date_elements 2]"
    set dow [clock format [clock scan "$this_day"] -format %w]
    if { 0 == $dow || 6 == $dow } {
        append day_header "\"<span style='color:#800000'>$this_day_html</span>\""
    } else {
        append day_header \"$this_day_html\"
    }
    append day_header " "

    set this_day [clock format [clock add [clock scan $this_day] 1 day] -format %Y-%m-%d]
}

set inner_sql [join $inner_sql_list ", "]
set outer_sql [join $outer_sql_list ", "]

set sql "

    	select
		0 as project_id,
		t.user_id,
		t.department_name,
		(select cost_center_name from im_cost_centers where cost_center_id in (select parent_id from im_cost_centers where cost_center_id=t.department_id)) as cc_name,
		im_name_from_user_id(t.user_id,3) as user_name,
		$outer_sql
	from
		(select 
			user_id, 
			$inner_sql,
			(select cost_center_name from im_cost_centers where cost_center_id = department_id) as department_name,
			department_id
               	from
                        (
                         select distinct 
                                u.user_id,
                                e.department_id
                         from
                                cc_users u
                                LEFT OUTER JOIN
                                        im_employees e
                                        on (u.user_id = e.employee_id)
			 where 
			        u.member_state = 'approved'
				$inner_where
                         order by
                                u.user_id
                        ) s
 		) t
         where
               1=1
         order by
              user_name
"

# -----------------------------------------------
# Define Report Elements: Line 
# -----------------------------------------------

set line_str " \"<b><a href=\$user_url\$user_id>\$user_name</a></b>\" "
append line_str " \"<b>\$department_name</b>\" "
append line_str " \"<b>\$cc_name</b>\" "
append line_str $day_placeholders 

# -----------------------------------------------
# Define Report 
# -----------------------------------------------
set report_def 		[list group_by user_id header $line_str content {}]
lappend report_def 	footer ""

# Set Global HEADER/FOOTER
set header0 "\" [lang::message::lookup "" intranet-core.Employee "Employee"]\" \"[lang::message::lookup "" intranet-core.Department "Department"]\" \"[lang::message::lookup "" intranet-cost.Cost_Center "Cost Center"]\" $day_header "
set footer0 {"" "" "" "" "" "" "" "" "" ""}

# ------------------------------------------------------------
# Start formatting the page
#

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format -report_name "timesheet-monthly-hours-absences"

# Add the HTML select box to the head of the page
switch $output_format {
    html {
        ns_write "
		[im_header]
		[im_navbar]
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
		<td>
		<form id='timesheet-incomplete-days' name='timesheet-incomplete-days'>
			<table border=0 cellspacing=1 cellpadding=1>
                <tr>
                  <td class=form-label>Start Date</td>
                  <td class=form-widget>
		     <input size='10' maxlength='10' name='start_date' id='start_date' value='$start_date' type='input'>
                  </td>
                </tr>
                <tr>
                  <td class=form-label>End Date</td>
                  <td class=form-widget>
		     <input size='10' maxlength='10' name='end_date' id='end_date' value='$end_date' type='input'>
                  </td>
                </tr>

		<tr>
                  <td class=form-label>[_ intranet-core.Cost_Center]:</td>
                  <td class=form-widget>
		      [im_cost_center_select -include_empty 1  -department_only_p 0  cost_center_id $cost_center_id [im_cost_type_timesheet]]
                 </td>
		</tr>
		<tr>
                  <td class=form-label>[_ intranet-core.Department]:</td>
                  <td class=form-widget>
		      [im_cost_center_select -include_empty 1  -department_only_p 1  department_id $department_id [im_cost_type_timesheet]]
                 </td>
		</tr>
		<tr>
		  <td class=form-label>Employee</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 user_id $user_id]
		  </td>
		</tr>
                <tr>
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
		<br><br>
	</form>
	</td>
	<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
	<td valign='top' width='600px'>
	    	<ul>
			<li>Report considers hours logged and absences</li>
		</ul>
		<br><br><br><strong> [lang::message::lookup "" intranet-reporting.Statistics "Statistics"]:</strong><br> 
		&nbsp;&nbsp;&nbsp;[lang::message::lookup "" intranet-reporting.TotalUsersSelected "Total users selected/Users with exception"]:&nbsp;
                <span id='total_users_ctr'>calculating ...</span>/<span id='output_users_ctr'>calculating...</span>
	</td>
	</table>

        <script>
        jQuery().ready(function(){
                \$(function() {
                \$( \"\#start_date\" ).datepicker({ dateFormat: \"yyyy-mm-dd\" });
                \$( \"\#end_date\" ).datepicker({ dateFormat: \"yyyy-mm-dd\" });
                });

        });
        </script>
	<table border=0 cellspacing=5 cellpadding=5>\n
	"
    }
}

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set absence_array_list [list]

set last_value_list [list]
set class "rowodd"

set counters [list]
 
#------------------------
# Initialize
#------------------------ 

set saved_user_id 0
set number_hours_project_ctr 0
set total_users_ctr 0 
set output_users_ctr 0 

db_foreach sql $sql {
    
    incr total_users_ctr
    set found_missing_hours_p 0
    set this_day $start_date

    # Show record only when at least one weekday entry is found that is below 'timesheet_hours_per_day'
    for { set i 1 } { $i <= $duration_in_days } { incr i } {
	set this_day_key [clock format [clock scan "$this_day"] -format %Y%m%d]
	# Check only for weekdays 
	set dow [clock format [clock scan "$this_day"] -format %w]
	if { 0 != $dow && 6 != $dow } {
	    set cmd "set var_helper \$hours_total_$this_day_key"
	    eval $cmd
	    if { "" == $var_helper  } {
		set cmd "set hours_total_$this_day_key 0"
		eval $cmd
	    }
	    if { $var_helper < $timesheet_hours_per_day } {
		set found_missing_hours_p 1
	    }
	} 
	set this_day [clock format [clock add [clock scan $this_day] 1 day] -format %Y-%m-%d]
    }

    if { !$found_missing_hours_p } { continue }
    incr output_users_ctr
    
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
    html { 
	ns_write "</table>\n[im_footer]\n" 
	ns_write "
		<script type='text/javascript'>
			document.getElementById('total_users_ctr').innerHTML = '$total_users_ctr';
			document.getElementById('output_users_ctr').innerHTML = '$output_users_ctr';
		</script>
	"
    }
    cvs { }
}

