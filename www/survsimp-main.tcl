# /packages/intranet-reporting/www/survsimp-main.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Report listing all main projects in the system with all available
    fields + DynFields from projects and customers
} {
    { level_of_detail 2 }
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { number_locale "" }
    { creation_user_id:integer 0}
    { related_object_id:integer 0}
    { related_context_id:integer 0}
    { survey_id:integer 0}
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-survsimp-main"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default "f"]

set read_p "t"

# ------------------------------------------------------------
# Constants

set locale [lang::user::locale]
if {"" == $number_locale} { set number_locale $locale  }

set date_format "YYYY-MM-DD"
set number_format "999,999.99"


# ------------------------------------------------------------

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set page_title [lang::message::lookup "" intranet-reporting.Survsim_main "Simple Survey Report"]
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set days_in_past 7

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} { 
    set start_date "$todays_year-01-01"
}

# Maxlevel is 4. Normalize in order to show the right drop-down element
if {$level_of_detail > 4} { set level_of_detail 4 }


db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { 
    set end_date "2099-12-31"
}


set user_url "/intranet/users/view?user_id="
set survey_url "/simple-survey/admin/one?survey_id="
set this_url [export_vars -base "/intranet-reporting/survsimp-main" {start_date end_date level_of_detail survey_id related_context_id related_object_id creation_user_id} ]

# BaseURL for drill-down.
set base_url [export_vars -base "/intranet-reporting/survsimp-main" {start_date end_date} ]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {0 != $survey_id && "" != $survey_id} { lappend criteria "ss.survey_id = :survey_id" }

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# List of survsimp variables to show

# Global header/footer
set header0 {Survey "Creation User" Response "Object" "Context" Question Answer}
set footer0 {}
set counters [list]

# Variables per survsimp
set survsimp_vars {
    "<nobr>$survey_name</nobr>"
    "<nobr><a href=$user_url$creation_user_id>$creation_user_name</a></nobr>"
    "<nobr>$response_id</nobr>"
    "<nobr><a href=$related_object_url$related_object_id>$related_object_name</a></nobr>"
    "<nobr><a href=$related_context_url$related_context_id>$related_context_name</a></nobr>"
    "<nobr>$survey_question</nobr>"
    "<nobr>$survey_answer</nobr>"
}

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
	select
		*,
		sqc.label as choice,
		ss.name as survey_name,
		srot.creation_user as creation_user_id,
		sq.question_text as survey_question,
		im_name_from_user_id(srot.creation_user) as creation_user_name,
		acs_object__name(related_object_id) as related_object_name,
		sro.url as related_object_url,
		acs_object__name(related_context_id) as related_context_name,
		src.url as related_context_url
	from
		survsimp_surveys ss,
		survsimp_questions sq,
		survsimp_responses sr
		LEFT OUTER JOIN (
			select	*
			from	acs_objects o,
				im_biz_object_urls u
			where	o.object_type = u.object_type and
				u.url_type = 'view'
		) sro ON (sro.object_id = sr.related_object_id)
		LEFT OUTER JOIN (
			select	*
			from	acs_objects o,
				im_biz_object_urls u
			where	o.object_type = u.object_type and
				u.url_type = 'view'
		) src ON (src.object_id = sr.related_context_id),
		acs_objects srot,
		survsimp_question_responses sqr
		LEFT OUTER JOIN survsimp_question_choices sqc ON (sqr.choice_id = sqc.choice_id)
	where
		ss.survey_id = sq.survey_id and
		sq.survey_id = sr.survey_id and
		sqr.response_id = sr.response_id and
		sqr.question_id = sq.question_id and
		sr.response_id = srot.object_id
		$where_clause
	order by
		ss.short_name,
		creation_user_name,
		sqr.response_id,
		sq.question_id,
		sq.question_text
"

set ttt {
		sqr.date_answer >= to_timestamp(:start_date, 'YYYY-MM-DD') and
		sqr.date_answer < to_timestamp(:end_date, 'YYYY-MM-DD')
}


switch $output_format {
    html {
	set report_def [list \
	    group_by survey_name \
	    header {
		"\#colspan=99 <a href=$base_url&level_of_detail=4 target=_blank><img src=/intranet/images/plus_9.gif border=0></a> <b><a href=$survey_url$survey_id>$survey_name</a></b>"
	    } \
	    content [list \
		 header $survsimp_vars \
		 content [list]
	    ] \
	    footer {"" "" "" "" "" "" ""} \
	]
    }
    default {
	set report_def [list \
		group_by survey_name \
		header $survsimp_vars \
		content [list] \
		footer [list] \
	]
    }
}


# ------------------------------------------------------------
# Constants
#

set start_years {2000 2000 2001 2001 2002 2002 2003 2003 2004 2004 2005 2005 2006 2006}
set start_months {01 Jan 02 Feb 03 Mar 04 Apr 05 May 06 Jun 07 Jul 08 Aug 09 Sep 10 Oct 11 Nov 12 Dec}
set start_days {01 1 02 2 03 3 04 4 05 5 06 6 07 7 08 8 09 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23 24 24 25 25 26 26 27 27 28 28 29 29 30 30 31 31}
set levels {1 "Customer Only" 2 "Customer+Survsimp"} 

# ------------------------------------------------------------
# Start Formatting the HTML Page Contents

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header $page_title]
	[im_navbar]
	<form>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr valign=top><td>
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
		  <td class=form-label>Creator</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" creation_user_id $creation_user_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Related Object</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" related_object_id $related_object_id]
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
	</td><td>
		<table border=0 cellspacing=1 cellpadding=1>
		</table>
	</td></tr>
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

    set survey_answer "$choice $boolean_answer $clob_answer $number_answer $varchar_answer $date_answer"

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


# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>\n[im_footer]\n"}
}
