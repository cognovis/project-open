# /packages/intranet-simple-survey/www/reporting/survsimp-results.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Shows the results of the evaluated users
} {
    { start_date "" }
    { end_date "" }
    { level_of_detail 2 }
    { output_format "html" }
    { survey_id "" }
    { evaluee_id 0 }
}

# ------------------------------------------------------------
# Security
# ------------------------------------------------------------

set menu_label "reporting_survsimp_results"
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

set page_title "Simple Survey Results"
set context_bar [im_context_bar $page_title]
set context ""

if {"" == $survey_id} {
    set survey_id [db_string sid "
	select	survey_id
	from	(
		select	survey_id,
			count(*) as cnt
		from	survsimp_responses
		group by survey_id
		) s
	order by s.cnt DESC
	limit 1
    " -default 0]
}

# Check Date formats
set start_date [string range $start_date 0 9]
if {"" != $start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set end_date [string range $end_date 0 9]
if {"" != $end_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}


# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

set days_in_future 31
db_1row todays_date "
select
	to_char(sysdate::date + :days_in_future::integer, 'YYYY') as todays_year,
	to_char(sysdate::date + :days_in_future::integer, 'MM') as todays_month
from dual
"

if {"" == $start_date} { set start_date "2000-01-01" }
if {"" == $end_date} { set end_date "$todays_year-$todays_month-01" }

set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/timesheet-productivity" {start_date} ]
set levels {2 "Evaluees + Evaluators"} 
set survey_options [db_list_of_lists soptions "
	select	name, survey_id
	from	survsimp_surveys
	order by name	
"]

# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {[info exists evaluee_id] && 0 != $evaluee_id && "" != $evaluee_id} {
    lappend criteria "h.user_id = :evaluee_id"
}

if {[exists_and_not_null start_date]} {
    lappend criteria "ro.creation_date >= :start_date::timestamptz"
}

if {[exists_and_not_null end_date]} {
    lappend criteria "ro.creation_date <= :end_date::timestamptz"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

# ------------------------------------------------------------
# Questions - converted into horizontal columns
#
set question_sql "
	select	q.question_id,
		substring(q.question_text for 30) as question_text
	from	survsimp_questions q
	where   q.survey_id = :survey_id
	order by sort_key;
"


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set question_select ""
set cnt 0
db_foreach q_sql $question_sql {
    append question_select "
		,(	select	coalesce(sqc.label,qr.clob_answer,qr.number_answer::varchar)
			from	survsimp_question_responses qr
				LEFT OUTER JOIN survsimp_question_choices sqc ON (qr.choice_id = sqc.choice_id)
			where	qr.response_id = r.response_id and
				qr.question_id = $question_id
		) as answer_$cnt
    "
    incr cnt
}

set sql "
	select
		r.response_id,
		to_char(ro.creation_date, 'YYYY-MM-DD') as creation_date_pretty,
		ro.creation_user as creation_user_id,
		im_name_from_user_id(ro.creation_user) as creation_user_name,
		r.related_context_id,
		acs_object__name(r.related_context_id) as related_context_name,
		r.related_object_id,
		acs_object__name(r.related_object_id) as related_object_name
		$question_select
	from
		survsimp_responses r,
		acs_objects ro
	where
		r.survey_id = :survey_id and
		ro.object_id = r.response_id
		$where_clause
	order by
		r.related_object_id,
		r.response_id DESC
"

# ---------------------------------------------
# Report Definition

# Fixed columns
set column_vars {
    $related_object_name
    $creation_user_name
    $related_context_name
    $creation_date_pretty
}

# Add cols for survey questions
set cnt 0
db_foreach q_sql $question_sql {
    lappend column_vars "\$answer_$cnt"
    incr cnt
}


set report_def [list \
    group_by related_object_id \
    header {
	"\#colspan=99 <b>$related_object_name</b>"
    } \
    content [list  \
	header $column_vars \
	content {} \
	footer {
	    "#colspan=99"
	} \
    ] \
    footer { 
	"\#colspan=99 &nbsp;"
    } \
]

# Global header/footer
set header0 {"Evaluee" "Evaluator" "Context" "Date"}
set footer0 {}

# Add cols for survey questions
db_foreach q_sql $question_sql {
    lappend header0 "$question_text"
    incr cnt
}



set counters [list]

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
		  <td class=form-label>Start Date</td>
		  <td class=form-widget>
		    <input type=textfield name=start_date value=$start_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>End Date</td>
		  <td class=form-widget>
		    <input type=textfield name=end_date value=$end_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Survey</td>
		  <td class=form-widget>
	            [im_select -ad_form_option_list_style_p 1 -translate_p 0 survey_id $survey_options $survey_id]
        	  </td>
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

    if {"" == $related_object_name} { set related_object_name "undefined" }

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
