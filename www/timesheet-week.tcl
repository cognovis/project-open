# /packages/intranet-reporting/www/timesheet.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
} {
    { date_dimension "day" }
    { start_year "" }
    { start_month "" }
    { start_day "" }
    { num_units "10000" }
    { max_level 9 }
}

# ------------------------------------------------------------
# Security

set errmsg ""
if {[string length $start_year] > 4} { append errmsg "<li> start_year too long" }
if {[string length $start_month] > 2} { append errmsg "<li> start_month too long" }
if {[string length $start_day] > 2} { append errmsg "<li> start_day too long" }

if {"" != $errmsg} {
    ad_return_complaint 1 $errmsg
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Timesheet Report"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------------
# Defaults

set todays_year [db_string today "select to_char(sysdate, 'YYYY') from dual"]
set todays_month [db_string today "select to_char(sysdate, 'MM') from dual"]
set todays_day [db_string today "select to_char(sysdate, 'DD') from dual"]

if {"" == $start_year} { set start_year $todays_year }
if {"" == $start_day} { set start_day $todays_day }
if {"" == $start_month} { set start_month $todays_month }

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="

set y $start_year
set m $start_month
set d $start_day

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set ttt "
--	to_char(h.day, 'YY-IW') as log_week,
--	to_char(h.day, 'YY-MM-DD') as log_day,
--	to_char(h.day, 'YY-MM') as log_month, "


set inner_sql "
select
	h.day::date as date,
	to_char(h.day, 'J')::integer - to_char(to_date('$y-$m-$d', 'YYYY-MM-DD'), 'J')::integer as date_diff,
	h.user_id,
	p.project_id,
	p.company_id,
	sum(h.hours) as hours,
	avg(h.billing_rate) as billing_rate
from
	im_hours h,
	im_projects p,
	cc_users u
where
	h.project_id = p.project_id
	and h.user_id = u.user_id
	and h.day >= to_date('$y-$m-$d', 'YYYY-MM-DD')
	and h.day <= to_date('$y-$m-$d', 'YYYY-MM-DD') + :num_units::integer
group by
	p.project_id,
	p.company_id,
	h.user_id,
	p.tree_sortkey,
	h.day
"

set sql "
select
	to_char(s.date, 'YYYY-MM-DD') as date,
	s.date_diff,
	u.user_id,
	u.first_names || ' ' || u.last_name as user_name,
	p.project_id,
	p.project_nr,
	c.company_id,
	c.company_path as company_nr,
	c.company_name,
	to_char(s.hours, '999,999.9') as hours,
	to_char(s.billing_rate, '999,999.9') as billing_rate,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') THEN s.hours ELSE 0 END as hours0,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +1 THEN s.hours ELSE 0 END as hours1,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +2 THEN s.hours ELSE 0 END as hours2,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +3 THEN s.hours ELSE 0 END as hours3,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +4 THEN s.hours ELSE 0 END as hours4,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +5 THEN s.hours ELSE 0 END as hours5,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +6 THEN s.hours ELSE 0 END as hours6,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +7 THEN s.hours ELSE 0 END as hours7,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +8 THEN s.hours ELSE 0 END as hours8,
	CASE s.date WHEN to_date('$y-$m-$d', 'YYYY-MM-DD') +9 THEN s.hours ELSE 0 END as hours9
from
	($inner_sql) s,
	im_companies c,
	im_projects p,
	cc_users u
where
	s.user_id = u.user_id
	and s.company_id = c.company_id
	and s.project_id = p.project_id
order by
	s.company_id,
	p.project_id,
	u.user_id,
	s.date
"

set report_def [list \
    group_by company_nr \
    header {
	header1
	"<b><a href=$company_url$company_id>$company_nr</a></b>"
	"" "" "" "" "" "" "" ""
    } \
    content [list  \
	group_by project_nr \
	header {
	    header2
	    $company_nr 
	    "<b><a href=$project_url$project_id>$project_nr</a></b>"
	    "" ""	 ""	 ""	 ""	 ""	 ""
	} \
	content [list \
	    group_by user_id \
	    header {
		header3
		$company_nr 
		$project_nr 
		"<b><a href=$user_url$user_id>$user_name</a></b>"
		"" "" "" "" "" "" ""
	    } \
	    content [list \
		    header {
			header4
			$company_nr
			$project_nr
			$user_name
			$date
			$date_diff
			$hours
			$billing_rate
			"$hours0"
			"$hours1"
			"$hours2"
			"$hours3"
			"$hours4"
			"$hours5"
			"$hours6"
		    } \
		    content {} \
	    ] \
	    footer {
		footer3
		$company_nr 
		$project_nr 
		$user_name
		date
		diff
		hours
		rate
		$hours0_subtotal
		$hours1_subtotal
		$hours2_subtotal
		$hours3_subtotal
		$hours4_subtotal
		$hours5_subtotal
		$hours6_subtotal
	    } \
	] \
    ] \
    footer {footer1 "" "" "" "" "" "" "" "" ""} \
]

# Global header/footer
set header0 {header0 "Customer" "Project" "User" "Date" Diff Hours Rate "0" "1" "2" "3" "4" "5" "6"}
set footer0 {footer0 "" "" "" "" "" ""}

set hours_counter [list \
	pretty_name Hours \
	var hours_subtotal \
	reset \$company_id \
	expr \$hours
]

set hours0_counter [list \
	pretty_name Hours0 \
	var hours0_subtotal \
	reset \$user_id \
	expr \$hours0
]

set hours1_counter [list \
	pretty_name Hours1 \
	var hours1_subtotal \
	reset \$user_id \
	expr \$hours1
]

set hours2_counter [list \
	pretty_name Hours2 \
	var hours2_subtotal \
	reset \$user_id \
	expr \$hours2
]

set hours3_counter [list \
	pretty_name Hours3 \
	var hours3_subtotal \
	reset \$user_id \
	expr \$hours3
]

set hours4_counter [list \
	pretty_name Hours4 \
	var hours4_subtotal \
	reset \$user_id \
	expr \$hours4
]

set hours5_counter [list \
	pretty_name Hours5 \
	var hours5_subtotal \
	reset \$user_id \
	expr \$hours5
]

set hours6_counter [list \
	pretty_name Hours6 \
	var hours6_subtotal \
	reset \$user_id \
	expr \$hours6
]

set counters [list \
	$hours_counter \
	$hours0_counter \
	$hours1_counter \
	$hours2_counter \
	$hours3_counter \
	$hours4_counter \
	$hours5_counter \
	$hours6_counter \
]


# ------------------------------------------------------------
# Constants
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_weeks {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31 32 32 33 33 34 34 35 35 36 36 37 37 38 38 39 39 40 40 41 41 42 42 43 43 44 44 45 45 46 46 47 47 48 48 49 49 50 50 51 51 52 52}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10} 

# ------------------------------------------------------------
# Start formatting the page
#

set start_units $start_months
if {"week" == $date_dimension} { set start_units $start_months }

ad_return_top_of_page "
[im_header]
[im_navbar]

<form>
<table border=0 cellspacing=1 cellpadding=1>
<tr>
  <td class=form-label>Time Resolution</td>
  <td class=form-widget>
    [im_select -translate_p 0 date_dimension {day Day week Week month Month} $date_dimension]
  </td>
</tr>
<tr>
  <td class=form-label>Max Level</td>
  <td class=form-widget>
    [im_select -translate_p 0 max_level $levels $max_level]
  </td>
</tr>
<tr>
  <td class=form-label>Start Date</td>
  <td class=form-widget>
    [im_select -translate_p 0 start_year $start_years $start_year]
    [im_select -translate_p 0 start_month $start_months $start_month]
    [im_select -translate_p 0 start_day $start_days $start_day]
  </td>
</tr>
<tr>
  <td></td>
  <td><input type=submit value=Submit></td>
</tr>
</table>
</form>

<table border=0 cellspacing=1 cellpadding=1>\n"

im_report_render_row \
    -row $header0 \
    -row_class rowtitle \
    -field_class rowtitle


set footer_array_list [list]
set last_value_list [list]
db_foreach sql $sql {

	im_report_display_footer \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -max_level $max_level
	
	im_report_update_counters -counters $counters
	
	set last_value_list [im_report_render_header \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -max_level $max_level \
        ]

        set footer_array_list [im_report_render_footer \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -max_level $max_level \
        ]


}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -display_all_footers_p 1

im_report_render_row \
    -row $footer0

ns_write "</table>\n[im_footer]\n"
