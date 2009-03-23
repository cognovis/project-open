# /packages/intranet-reporting/www/survsimp-cube.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Cost Cube
} {
    { start_date "" }
    { end_date "" }
    { top_var1 "creation_user" }
    { top_var2 "" }
    { top_var3 "" }
    { left_var1 "answer" }
    { left_var2 "" }
    { left_var3 "" }
    { survey_id:integer 0 }
    { question_id:integer 0 }
    { creation_user_id:integer 0 }
    { related_object_id:integer 0 }
    { related_context_id:integer 0 }

    { left_vars "" }
    { top_vars "" }
}

# ------------------------------------------------------------
# Define Dimensions

# Make sure question_id and survey_id fit together
if {"" != $question_id && 0 != $question_id} {
    set survey_id [db_string sid "select survey_id from survsimp_questions where question_id = :question_id" -default 0]
}


# Left Dimension - defined by users selects
set left {}
if {"" != $left_vars} {
    # override left vars with elements from list
    set left_var1 [lindex $left_vars 0]
    set left_var2 [lindex $left_vars 1]
    set left_var3 [lindex $left_vars 2]
}
if {"" != $left_var1} { lappend left $left_var1 }
if {"" != $left_var2} { lappend left $left_var2 }
if {"" != $left_var3} { lappend left $left_var3 }

# Top Dimension
set top_var1 [ns_urldecode $top_var1]

set top {}
if {"" != $top_var1} { lappend top $top_var1 }
if {"" != $top_var2} { lappend top $top_var2 }
if {"" != $top_var3} { lappend top $top_var3 }

# Flatten lists - kinda dirty...
regsub -all {[\{\}]} $top "" top
regsub -all {[\{\}]} $left "" left


# The complete set of dimensions - used as the key for
# the "cell" hash. Subtotals are calculated by dropping on
# or more of these dimensions
set dimension_vars [concat $top $left]

# Check for duplicate variables
set unique_dimension_vars [lsort -unique $dimension_vars]
if {[llength $dimension_vars] != [llength $unique_dimension_vars]} {
    ad_return_complaint 1 "<b>Duplicate Variable</b>:<br>
    You have specified a variable more then once."
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-cubes-survsimp"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

set read_p "t"

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}


# ------------------------------------------------------------
# Check Parameters

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

# ------------------------------------------------------------
# Page Title & Help Text

set page_title [lang::message::lookup "" intranet-reporting.Simple_Survey_Cube "Simple Survey Cube"]
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>

This Pivot Table ('cube') is a kind of report that shows answers of
Simple Surveys. This cube effectively replaces a dozen of specific 
reports and allows you to 'drill down' into results.
<p>
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set gray "gray"
set sigma "&Sigma;"
set days_in_past 365

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} { 
    set start_date "$todays_year-$todays_month-01"
}

db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + :days_in_past::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { 
    set end_date "$end_year-$end_month-01"
}


set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/survsimp-cube" {start_date end_date} ]


# ------------------------------------------------------------
# Options

set top_vars_options {
	"" "No Date Dimension" 
	"year" "Year" 
	"year quarter_of_year" "Year and Quarter" 
	"month_of_year year" "Month and Year (compare months)"
}

set left_scale_options {
	"" ""
	"survey" "Survey"
	"question" "Question"
	"answer" "Answer"

	"object" "Evaluated Object"
	"context" "Evaluation Context"
	"creation_user" "Surveyee"
}

set survey_options [db_list_of_lists surveys "
	select	name, survey_id
	from	survsimp_surveys
	order by name
"]
set survey_options [linsert $survey_options 0 {"" ""}]

set question_options [db_list_of_lists surveys "
	select	ss.name || ' - ' || sq.question_text, sq.question_id
	from	survsimp_surveys ss,
		survsimp_questions sq
	where	sq.survey_id = ss.survey_id
	order by 
		ss.name,
		sq.question_text
"]
set question_options [linsert $question_options 0 {"" ""}]

set creation_user_options [db_list_of_lists creation_users "
	select	distinct
		im_name_from_user_id(sro.creation_user) as creation_user_name, 
		sro.creation_user
	from
		survsimp_surveys ss,
		survsimp_responses sr,
		acs_objects sro
	where
		sr.survey_id = ss.survey_id and
		sr.response_id = sro.object_id
	order by 
		creation_user_name
"]
set creation_user_options [linsert $creation_user_options 0 {"" ""}]

set object_options [db_list_of_lists surveys "
	select distinct
		acs_object__name(sr.related_object_id) as object,
		sr.related_object_id
	from	survsimp_surveys ss,
		survsimp_responses sr
	where	sr.survey_id = ss.survey_id
		and sr.related_object_id is not null
	order by 
		object
"]
set object_options [linsert $object_options 0 {"" ""}]

set context_options [db_list_of_lists surveys "
	select distinct
		acs_object__name(sr.related_context_id) as context,
		sr.related_context_id
	from	survsimp_surveys ss,
		survsimp_responses sr
	where	sr.survey_id = ss.survey_id
		and sr.related_context_id is not null
	order by 
		context
"]
set context_options [linsert $context_options 0 {"" ""}]



# ------------------------------------------------------------
# Start formatting the page
#

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format "html"

ns_write "
[im_header]
[im_navbar]
<table cellspacing=0 cellpadding=0 border=0>
<form>
[export_form_vars project_id]
<tr valign=top><td>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Start Date</td>
	  <td class=form-widget colspan=3>
	    <input type=textfield name=start_date value=$start_date>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>End Date</td>
	  <td class=form-widget colspan=3>
	    <input type=textfield name=end_date value=$end_date>
	  </td>
	</tr>
        <tr>
          <td class=form-label>Survey</td>
          <td class=form-widget colspan=3>
	    [im_select -ad_form_option_list_style_p 1 -translate_p 0 survey_id $survey_options $survey_id]
          </td>
        </tr>
        <tr>
          <td class=form-label>Question</td>
          <td class=form-widget colspan=3>
	    [im_select -ad_form_option_list_style_p 1 -translate_p 0 question_id $question_options $question_id]
          </td>
        </tr>
        <tr>
          <td class=form-label>Rated Object</td>
          <td class=form-widget colspan=3>
	    [im_select -ad_form_option_list_style_p 1 -translate_p 0 related_object_id $object_options $related_object_id]
          </td>
        </tr>
        <tr>
          <td class=form-label>Rating Context</td>
          <td class=form-widget colspan=3>
	    [im_select -ad_form_option_list_style_p 1 -translate_p 0 related_context_id $context_options $related_context_id]
          </td>
        </tr>
        <tr>
          <td class=form-label>Creation Users</td>
          <td class=form-widget colspan=3>
	    [im_select -ad_form_option_list_style_p 1 -translate_p 0 creation_user_id $creation_user_options $creation_user_id]
          </td>
        </tr>
	<tr>
	  <td class=form-widget colspan=2 align=center>Left-Dimension</td>
	  <td class=form-widget colspan=2 align=center>Top-Dimension</td>
	</tr>
	<tr>
	  <td class=form-label>Left 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_var1 $left_scale_options $left_var1]
	  </td>
	  <td class=form-label>Date Dimension</td>
	    <td class=form-widget>
	      [im_select -translate_p 0 top_var1 $top_vars_options $top_var1]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_var2 $left_scale_options $left_var2]
	  </td>

	  <td class=form-label>Top 1</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 top_var2 $left_scale_options $top_var2]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Left 3</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 left_var3 $left_scale_options $left_var3]
	  </td>
	  <td class=form-label>Top 2</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 top_var3 $left_scale_options $top_var3]
	  </td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget colspan=3><input type=submit value=Submit></td>
	</tr>
	</table>
</td>
<td>
	<table>
	</table>
</td>
<td>
	<table cellspacing=2 width=90%>
	<tr><td>$help_text</td></tr>
	</table>
</td>
</tr>
</form>
</table>
"


# ------------------------------------------------------------
# Get the cube data
#

set cube_array [im_reporting_cubes_cube \
    -cube_name "survsimp" \
    -start_date $start_date \
    -end_date $end_date \
    -left_vars $left \
    -top_vars $top \
    -survey_id $survey_id \
    -creation_user_id $creation_user_id \
    -related_object_id $related_object_id \
    -related_context_id $related_context_id \
    -no_cache_p 1 \
]

if {"" != $cube_array} {
    array set cube $cube_array

    # Extract the variables from cube
    set left_scale $cube(left_scale)
    set top_scale $cube(top_scale)
    array set hash $cube(hash_array)


    # ------------------------------------------------------------
    # Display the Cube Table
    
    ns_write [im_reporting_cubes_display \
	      -hash_array [array get hash] \
	      -left_vars $left \
	      -top_vars $top \
	      -top_scale $top_scale \
	      -left_scale $left_scale \
    ]
}


# ------------------------------------------------------------
# Finish up the table

ns_write "[im_footer]\n"


