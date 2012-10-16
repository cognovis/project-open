# /packages/intranet-reporting/www/timesheet-productivity-calendar-view.tcl
#
# Copyright (C) 2003 - 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { report_year_month "" }
    { level_of_detail 3 }
    { output_format "html" }
    { user_id 0 }
    { project_id 0 }
    { project_status_id 76 }
    { customer_id 0 }
    { daily_hours 0 }
    { different_from_project_p "" }
}

# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

# Label: Provides the security context for this report
set menu_label "timesheet-productivity-calendar-view-workdays-simple"

set current_user_id [ad_maybe_redirect_for_registration]

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

set page_title [lang::message::lookup "" intranet-reporting.Timesheet_Logging_Report___Monthly_View___Simple "Timesheet Productivity Report - Monthly View - Simple"]
set context_bar [im_context_bar $page_title]
set context ""

# Check that Start-Date have correct format
set report_year_month [string range $report_year_month 0 6]
if {"" != $report_year_month && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]$} $report_year_month]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$report_year_month'<br>
    Expected format: 'YYYY-MM'"
}

set date_format "YYYY-MM-DD"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

set todays_date [db_string todays_date "select to_char(now(), :date_format) from dual" -default ""]

if { [empty_string_p $report_year_month] } {
    set report_year_month "[string range $todays_date 0 3]-[string range $todays_date 5 6]"
}    

set report_year [string range $report_year_month 0 3]
set report_month [string range $report_year_month 5 6 ]

set first_day_of_month "$report_year-$report_month-01"
set first_day_next_month [string range [db_string get_number_days_month "SELECT '$first_day_of_month'::date + '1 month'::interval" -default 0] 0 9 ]

set duration [db_string get_number_days_month "SELECT date_part('day','$first_day_of_month'::date + '1 month'::interval - '1 day'::interval)" -default 0]

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="

set internal_company_id [im_company_internal]

set num_format "999,990.99"

set im_absence_type_vacation 5000
set im_absence_type_personal 5001
set im_absence_type_sick 5002
set im_absence_type_travel 5003
set im_absence_type_bankholiday 5005
set im_absence_type_training 5004

# ------------------------------------------------------------
# Conditional SQL Where-Clause
#
 
if {[empty_string_p $different_from_project_p]} {
   set mm_checked ""
   set mm_value  ""
} else {
   set mm_checked "checked"
   set mm_value  "value='on'"
}

set criteria [list]

if {"" != $project_id && 0 != $project_id && $different_from_project_p == ""} {	
    lappend criteria "
		p.project_id in (
		select 
			children.project_id as subproject_id
		from
			im_projects parent,
			im_projects children
		where
		        tree_ancestor_key(children.tree_sortkey, 1) = parent.tree_sortkey 
			and parent.project_id = :project_id
			)
    "
}

 if {"" != $project_id && 0 != $project_id && $different_from_project_p != ""} {
        lappend criteria "
		p.project_id in (
		select 
			children.project_id as subproject_id
		from
			im_projects parent,
			im_projects children
		where
			tree_ancestor_key(children.tree_sortkey, 1) = parent.tree_sortkey 
			and parent.project_id <> :project_id
			)
    "
}

if {"" != $customer_id && 0 != $customer_id} {
	 lappend criteria "p.company_id = :customer_id" 
}

if { ![empty_string_p $project_status_id] && $project_status_id > 0 } {
    lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
}

if {[info exists user_id] && 0 != $user_id && "" != $user_id} {
    lappend criteria "h.user_id = :user_id"
}

set show_user_only_p 1 

if { [im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "Senior Managers"] -user_id $current_user_id] } {
	set show_user_only_p 0
}

if { [im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "HR Managers"] -user_id $current_user_id] } {
        set show_user_only_p 0
}

if { [im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "P/O Admins"] -user_id $current_user_id] } {
        set show_user_only_p 0
}

if { $show_user_only_p } {
	lappend criteria "u.user_id = $current_user_id"
}

# ad_return_complaint 1 $show_user_only_p

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

# if {"" != $daily_hours && 0 != $daily_hours} {
#    set criteria_inner_sql "and h.hours > :daily_hours"
#} else {
#    set criteria_inner_sql "and 1=1"
#}

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set day_placeholders ""
set day_header ""

for { set i 1 } { $i < $duration + 1 } { incr i } {
    if { 1 == [string length $i]} { set day_double_digit 0$i } else { set day_double_digit $i }
    lappend inner_sql_list "sum((select sum(hours) from im_hours h where
            h.user_id = s.user_id
            and h.project_id in (
                select
                        children.project_id as subproject_id
                from
                        im_projects parent,
                        im_projects children
                where
                          tree_ancestor_key(children.tree_sortkey, 1) = parent.tree_sortkey 
                        )
	    and h.project_id = s.sub_project_id
            and date_trunc('day', day) = '$report_year-$report_month-$day_double_digit'    
	)) as day$day_double_digit
    "
    lappend outer_sql_list "
	sum(CASE WHEN day$day_double_digit <= $daily_hours THEN null ELSE day$day_double_digit
	END) as day$day_double_digit
    " 
    append day_placeholders "\\" "\$day$day_double_digit "
    append day_header \"$day_double_digit\"
    append day_header " "
}


set inner_sql [join $inner_sql_list ", "]
set outer_sql [join $outer_sql_list ", "]

set sql "
	select
        	user_id,
		user_name,
	        top_parent_project_id,
		top_project_name,
		(select project_nr from im_projects where project_id = top_parent_project_id) as top_project_nr,
		sub_project_id,
		CASE WHEN t.sub_project_id = t.top_parent_project_id THEN NULL ELSE t.sub_project_name END as sub_project_name,
                CASE WHEN t.sub_project_id = t.top_parent_project_id THEN NULL ELSE t.sub_project_nr END as sub_project_nr,
                (select count(*) from (select * from im_absences_working_days_month(user_id,$report_month,$report_year) t(days int))ct) as work_days,
                (select count(distinct absence_query.days) from (select * from im_absences_month_absence_type (user_id, $report_month, $report_year, $im_absence_type_vacation) AS (days date)) absence_query) as vacation_days,
                (select count(distinct absence_query.days) from (select * from im_absences_month_absence_type (user_id, $report_month, $report_year, $im_absence_type_training) AS (days date)) absence_query) as training_days,
                (select count(distinct absence_query.days) from (select * from im_absences_month_absence_type (user_id, $report_month, $report_year, $im_absence_type_travel) AS (days date)) absence_query) as travel_days,
                (select count(distinct absence_query.days) from (select * from im_absences_month_absence_type (user_id, $report_month, $report_year, $im_absence_type_sick) AS (days date)) absence_query) as sick_days,
                (select count(distinct absence_query.days) from (select * from im_absences_month_absence_type (user_id, $report_month, $report_year, $im_absence_type_personal) AS (days date)) absence_query) as personal_days,
	        $outer_sql
	from
        	(select
                	user_id,
	                user_name,
        	        s.top_parent_project_id,
                	(select project_name from im_projects where project_id = s.top_parent_project_id) as top_project_name,
                	(select project_nr from im_projects where project_id = s.top_parent_project_id) as top_project_nr,			
                        	 CASE
                                         WHEN s.project_type_id = 100 THEN
                                         (select project_name from im_projects where project_id = s.sub_project_id)
                                         ELSE
                                         s.sub_project_name
                                END as sub_project_name,
                                CASE
                                         WHEN s.project_type_id = 100 THEN
                                         (select project_nr from im_projects where project_id in (select parent_id from im_projects where project_id = s.sub_project_id))
                                         ELSE
                                         s.sub_project_nr
                                END as sub_project_nr,
                                CASE
                                         WHEN s.project_type_id = 100 THEN
                                         (select project_id from im_projects where project_id = s.sub_project_id)
                                         ELSE
                                         s.sub_project_id
                                END as sub_project_id,
			$inner_sql
        	from
                	(
			 select	distinct p.project_id, 
                	        u.user_id,
                        	im_name_from_user_id(u.user_id) as user_name,
	                        (select main_p.project_id from im_projects pr, im_projects main_p where pr.project_id = h.project_id and tree_ancestor_key(pr.tree_sortkey, 1) = main_p.tree_sortkey limit 1) as top_parent_project_id,
				p.project_name   as sub_project_name,
				p.project_id	 as sub_project_id,
				p.project_nr     as  sub_project_nr,
				p.project_type_id
		   	from
                        	im_hours h,
	                        im_projects p,
        	                users u
                	        LEFT OUTER JOIN
                        	        im_employees e
                                	on (u.user_id = e.employee_id)
	                where
        	                h.project_id = p.project_id
                	        and h.user_id = u.user_id
                        	and h.day >= to_date('$first_day_of_month', 'YYYY-MM-DD')
	                        and h.day < to_date('$first_day_next_month', 'YYYY-MM-DD')
        	                $where_clause
                	order by
                        	p.project_id,
	                        u.user_id
                	) s
		group by 
                	user_id,
	                user_name,
        	        top_parent_project_id,
                	top_project_name,
			project_type_id,
	                sub_project_id,
 			sub_project_nr,
        	        sub_project_name
	 ) t
group by 
	user_id,
	user_name,
	top_parent_project_id,
	top_project_name,
	top_project_nr,
	sub_project_id,
	sub_project_name,
	sub_project_nr
order by
        user_id,
	top_parent_project_id
"

# This string represents a project/sub project
set line_str " \"\" \"<b><a href=\$project_url\$top_parent_project_id>\${top_project_nr} - \${top_project_name}</a></b>\" \"<b><a href=\$project_url\$sub_project_id>\${sub_project_nr} - \${sub_project_name}</a></b>\" "
append line_str $day_placeholders "\$number_hours_project_ctr" 

set no_empty_columns [expr $duration+1]

set report_def 		[list group_by user_id header {"\#colspan=99 <a href=$user_url$user_id>$user_name</a>"} content]
lappend report_def 	[list group_by project_id header $line_str content {}]


if {$duration == 28} {
lappend report_def      footer { "<strong>Summary</strong>" \
				 "&nbsp;"
				 "&nbsp;"
				 "<strong>$thours_arr(day01)</strong>" \
				 "<strong>$thours_arr(day02)</strong>" \
				 "<strong>$thours_arr(day03)</strong>" \
				 "<strong>$thours_arr(day04)</strong>" \
				 "<strong>$thours_arr(day05)</strong>" \
				 "<strong>$thours_arr(day06)</strong>" \
				 "<strong>$thours_arr(day07)</strong>" \
				 "<strong>$thours_arr(day08)</strong>" \
				 "<strong>$thours_arr(day09)</strong>" \
				 "<strong>$thours_arr(day10)</strong>" \
				 "<strong>$thours_arr(day11)</strong>" \
				 "<strong>$thours_arr(day12)</strong>" \
				 "<strong>$thours_arr(day13)</strong>" \
				 "<strong>$thours_arr(day14)</strong>" \
				 "<strong>$thours_arr(day15)</strong>" \
				 "<strong>$thours_arr(day16)</strong>" \
				 "<strong>$thours_arr(day17)</strong>" \
				 "<strong>$thours_arr(day18)</strong>" \
				 "<strong>$thours_arr(day19)</strong>" \
				 "<strong>$thours_arr(day20)</strong>" \
				 "<strong>$thours_arr(day21)</strong>" \
				 "<strong>$thours_arr(day22)</strong>" \
				 "<strong>$thours_arr(day23)</strong>" \
				 "<strong>$thours_arr(day24)</strong>" \
				 "<strong>$thours_arr(day25)</strong>" \
				 "<strong>$thours_arr(day26)</strong>" \
				 "<strong>$thours_arr(day27)</strong>" \
				 "<strong>$thours_arr(day28)</strong>" \
                                 "<strong>$number_hours_ctr_pretty</strong><tr><td colspan='99'>&nbsp;</td></tr>"
}}

if {$duration == 29} {
lappend report_def      footer { "<strong>Summary</strong>" \
				 "&nbsp;"
				 "&nbsp;"
				 "<strong>$thours_arr(day01)</strong>" \
				 "<strong>$thours_arr(day02)</strong>" \
				 "<strong>$thours_arr(day03)</strong>" \
				 "<strong>$thours_arr(day04)</strong>" \
				 "<strong>$thours_arr(day05)</strong>" \
				 "<strong>$thours_arr(day06)</strong>" \
				 "<strong>$thours_arr(day07)</strong>" \
				 "<strong>$thours_arr(day08)</strong>" \
				 "<strong>$thours_arr(day09)</strong>" \
				 "<strong>$thours_arr(day10)</strong>" \
				 "<strong>$thours_arr(day11)</strong>" \
				 "<strong>$thours_arr(day12)</strong>" \
				 "<strong>$thours_arr(day13)</strong>" \
				 "<strong>$thours_arr(day14)</strong>" \
				 "<strong>$thours_arr(day15)</strong>" \
				 "<strong>$thours_arr(day16)</strong>" \
				 "<strong>$thours_arr(day17)</strong>" \
				 "<strong>$thours_arr(day18)</strong>" \
				 "<strong>$thours_arr(day19)</strong>" \
				 "<strong>$thours_arr(day20)</strong>" \
				 "<strong>$thours_arr(day21)</strong>" \
				 "<strong>$thours_arr(day22)</strong>" \
				 "<strong>$thours_arr(day23)</strong>" \
				 "<strong>$thours_arr(day24)</strong>" \
				 "<strong>$thours_arr(day25)</strong>" \
				 "<strong>$thours_arr(day26)</strong>" \
				 "<strong>$thours_arr(day27)</strong>" \
				 "<strong>$thours_arr(day28)</strong>" \
				 "<strong>$thours_arr(day29)</strong>" \
                                 "<strong>$number_hours_ctr_pretty</strong><tr><td colspan='99'>&nbsp;</td></tr>"
}}

if {$duration == 30} {
lappend report_def      footer { "<strong>Summary</strong>" \
				 "&nbsp;"
				 "&nbsp;"
				 "<strong>$thours_arr(day01)</strong>" \
				 "<strong>$thours_arr(day02)</strong>" \
				 "<strong>$thours_arr(day03)</strong>" \
				 "<strong>$thours_arr(day04)</strong>" \
				 "<strong>$thours_arr(day05)</strong>" \
				 "<strong>$thours_arr(day06)</strong>" \
				 "<strong>$thours_arr(day07)</strong>" \
				 "<strong>$thours_arr(day08)</strong>" \
				 "<strong>$thours_arr(day09)</strong>" \
				 "<strong>$thours_arr(day10)</strong>" \
				 "<strong>$thours_arr(day11)</strong>" \
				 "<strong>$thours_arr(day12)</strong>" \
				 "<strong>$thours_arr(day13)</strong>" \
				 "<strong>$thours_arr(day14)</strong>" \
				 "<strong>$thours_arr(day15)</strong>" \
				 "<strong>$thours_arr(day16)</strong>" \
				 "<strong>$thours_arr(day17)</strong>" \
				 "<strong>$thours_arr(day18)</strong>" \
				 "<strong>$thours_arr(day19)</strong>" \
				 "<strong>$thours_arr(day20)</strong>" \
				 "<strong>$thours_arr(day21)</strong>" \
				 "<strong>$thours_arr(day22)</strong>" \
				 "<strong>$thours_arr(day23)</strong>" \
				 "<strong>$thours_arr(day24)</strong>" \
				 "<strong>$thours_arr(day25)</strong>" \
				 "<strong>$thours_arr(day26)</strong>" \
				 "<strong>$thours_arr(day27)</strong>" \
				 "<strong>$thours_arr(day28)</strong>" \
				 "<strong>$thours_arr(day29)</strong>" \
				 "<strong>$thours_arr(day30)</strong>" \
                                 "<strong>$number_hours_ctr_pretty</strong><tr><td colspan='99'>&nbsp;</td></tr>"
}}

if {$duration == 31} {
lappend report_def      footer { "<strong>Summary</strong>" \
				 "&nbsp;"
				 "&nbsp;"
				 "<strong><strong>$thours_arr(day01)</strong>" \
				 "<strong>$thours_arr(day02)</strong>" \
				 "<strong>$thours_arr(day03)</strong>" \
				 "<strong>$thours_arr(day04)</strong>" \
				 "<strong>$thours_arr(day05)</strong>" \
				 "<strong>$thours_arr(day06)</strong>" \
				 "<strong>$thours_arr(day07)</strong>" \
				 "<strong>$thours_arr(day08)</strong>" \
				 "<strong>$thours_arr(day09)</strong>" \
				 "<strong>$thours_arr(day10)</strong>" \
				 "<strong>$thours_arr(day11)</strong>" \
				 "<strong>$thours_arr(day12)</strong>" \
				 "<strong>$thours_arr(day13)</strong>" \
				 "<strong>$thours_arr(day14)</strong>" \
				 "<strong>$thours_arr(day15)</strong>" \
				 "<strong>$thours_arr(day16)</strong>" \
				 "<strong>$thours_arr(day17)</strong>" \
				 "<strong>$thours_arr(day18)</strong>" \
				 "<strong>$thours_arr(day19)</strong>" \
				 "<strong>$thours_arr(day20)</strong>" \
				 "<strong>$thours_arr(day21)</strong>" \
				 "<strong>$thours_arr(day22)</strong>" \
				 "<strong>$thours_arr(day23)</strong>" \
				 "<strong>$thours_arr(day24)</strong>" \
				 "<strong>$thours_arr(day25)</strong>" \
				 "<strong>$thours_arr(day26)</strong>" \
				 "<strong>$thours_arr(day27)</strong>" \
				 "<strong>$thours_arr(day28)</strong>" \
				 "<strong>$thours_arr(day29)</strong>" \
				 "<strong>$thours_arr(day30)</strong>" \
				 "<strong>$thours_arr(day31)</strong>" \
				 "<strong>$number_hours_ctr_pretty </strong> <tr><td colspan='99'>&nbsp;</td></tr>" 
}}

# Global header/footer
set header0 "\"Employee\" \"Project\" \"Sub-Project\" $day_header \"Hours\" "
set footer0 {"" "" "" "" "" "" "" "" "" ""}

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
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
		<td>
		<form>
			<table border=0 cellspacing=1 cellpadding=1>
			<tr>
			  <td class=form-label>Month</td>
			  <td class=form-widget>
			    <input type=textfield name='report_year_month' value='$report_year_month'>
			  </td>
			</tr>
	"

	if { !$show_user_only_p  } {
        	ns_write "
			<tr>
			  <td class=form-label>Employee</td>
			  <td class=form-widget>
			    [im_user_select -include_empty_p 1 user_id $user_id]
			  </td>
			</tr>
		"
	}

        ns_write "
                <tr>
                  <td class=form-label>Customer</td>
                  <td class=form-widget>
                    [im_company_select customer_id $customer_id]
                  </td>
                </tr>
                <tr>
                <tr>
                  <td class=form-label>Project</td>
                  <td class=form-widget>
                    Not:&nbsp;
		    <input name=different_from_project_p type=checkbox $mm_value $mm_checked> 
		    &nbsp;
                    [im_project_select -include_empty_p 1 project_id $project_id]
                  </td>
                </tr>	    
                <tr>
                  <td class=form-label>Project Status</td>
                  <td class=form-widget>
 			[im_category_select -include_empty_p 1 "Intranet Project Status" project_status_id ""]
                  </td>
                </tr>
                <tr>
                  <td class=form-label>Daily hours</td>
                  <td class=form-widget>
			<select name='daily_hours'>
	"

	if {0==$daily_hours || ""==$daily_hours } {ns_write " <option selected value='0'>all</option>"} else {ns_write "<option value='0'>all</option>" }
	for {set ctr 2} {$ctr < 9} {incr ctr} {
        	if { "$ctr"==$daily_hours } {ns_write " <option selected value='$ctr'>>$ctr hours</option>"} else {ns_write "<option value='$ctr'>>$ctr hours</option>" }
	}

	ns_write "
			</select>
                  </td>
                </tr>
		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value=Submit></td>
		</tr>
		</table>
	</form>
</td>
<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
<td valign='top' width='600px'>
	<ul>
    	<li>Up to two project levels are shown (Main Project/Sub Project), levels underneath are accumulated</strong></li>
    	<li>Report shows only content for days where the logged hours pass a threshold as defined in filter: <strong>'Daily hours'</strong></li>
        <li>Hours logged on sub-projects are accumulated</li>
	</ul>
</td>
</tr>
</table>
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
set last_value_list [list]
set class "rowodd"

set number_days_ctr 0
set number_days_counter [list \
       pretty_name "Number days" \
       var number_days_ctr_pretty \
       reset \$user_id \
       expr "\$number_days_ctr+0" \
]

set counters [list $number_days_counter ]
 
#------------------------
# Initialize
#------------------------ 

set saved_user_id 0
set number_hours_project_ctr 0

for { set i 1 } { $i < $duration + 1 } { incr i } {
        if { 1 == [string length $i]} { set day_double_digit day0$i } else { set day_double_digit day$i }
	set month_arr($day_double_digit) 0
	set thours_arr($day_double_digit) ""
}

db_foreach sql $sql {

        set number_days_ctr 0
        set number_hours_ctr 0

	im_report_display_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

        set number_hours_project_ctr 0

	if { $user_id != $saved_user_id } {
		set saved_user_id $user_id
		for { set i 1 } { $i < $duration + 1 } { incr i } {
	        	if { 1 == [string length $i]} { set day_double_digit day0$i } else { set day_double_digit day$i }
	        	set month_arr($day_double_digit) 0
			set thours_arr($day_double_digit) ""
 		    	set number_hours_ctr_pretty 0
		}
	}	

	for { set i 1 } { $i < $duration + 1 } { incr i } {
	        # Make sure that day_double_digit is always a 2-digit number  
		if { 1 == [string length $i]} { set day_double_digit day0$i } else { set day_double_digit day$i }

		if { "" != [expr $$day_double_digit] } {
			set thours_arr($day_double_digit) [expr $thours_arr($day_double_digit) + $$day_double_digit]

   		        set number_hours_project_ctr [expr $number_hours_project_ctr + [expr $$day_double_digit]] 
		        set number_hours_ctr_pretty [expr $number_hours_ctr_pretty + [expr $$day_double_digit]]

			if { 0 == $month_arr($day_double_digit) } {
				set month_arr($day_double_digit) 1
			        set number_hours_ctr [expr $number_hours_ctr + $thours_arr($day_double_digit)] 
			}

		}
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

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class


switch $output_format {
    html { ns_write "</table>\n[im_footer]\n" }
}

