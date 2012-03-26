# /packages/intranet-simple-survey/www/reporting/project-reports.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Project (and other) Reports per Week with Reminders

    @param start_date	Hard start of reporting period. Defaults to start of first project
    @param end_date	Hard end of replorting period. Defaults to end of last project
    @param survey_id	Filters reports to a specific survey
    @param project_id	Filters reports to a specific projectk
    @param customer_id	Filters reports to projects from a specific customer
    @param user_id	Filters reports from the specified user
    @param cost_center_id Limits
} {
    { start_date "" }
    { end_date "" }
    { survey_id "" }
    { project_id:multiple "" }
    { customer_id:integer "" }
    { user_id "" }
    { cost_center_id "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set menu_label "reporting_survsimp_results"
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

# Check for the default survey name if survey_id was not specified
if {"" == $survey_id} {
    set default_survey_name [parameter::get_from_package_key -package_key "intranet-simple-survey" -parameter DefaultProjectReportSurveyName -default "Project Status Report"]
    set survey_id [db_string default_survey "select survey_id from survsimp_surveys where lower(trim(name)) = lower(trim(:default_survey_name))" -default ""]
}

if {"" == $survey_id} { set survey_id [db_string last_survey "select min(survey_id) from survsimp_surveys" -default ""] }
if {"" == $survey_id} { 
    ad_return_complaint 1 "No surveys defined yet"
    ad_script_abort
}

# ad_return_complaint 1 $survey_id


set page_title [lang::message::lookup "" intranet-simple-survey.Project_Reports "Project Reports"]
set context_bar [im_context_bar $page_title]
set context ""
set show_context_help_p 1

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# Valid colors for color coding
set valid_colors {white gray black green yellow red purple blue cyan clear}


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

set sub_navbar ""
set main_navbar_label "projects"

set project_menu ""
if {[llength $project_id] == 1} {

    # Exactly one project - quite a frequent case.
    # Show a ProjectMenu so that it looks like we've gone to a different tab.
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set sub_navbar [im_sub_navbar \
       -components \
       -base_url "/intranet/projects/view?project_id=$project_id" \
       $project_menu_id \
       $bind_vars "" "pagedesriptionbar" "project_resources"] 
    set main_navbar_label "projects"

} else {

    # Show the same header as the ProjectListPage
    set letter ""
    set next_page_url ""
    set previous_page_url ""
    set menu_select_label "project_reports"
    set sub_navbar [im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list] $menu_select_label]

}



# ------------------------------------------------------------
# Defaults

if {"" == $start_date} { set start_date [db_string start_date "select now()::date - 90"] }
if {"" == $end_date} { set end_date [db_string start_date "select now()::date + 3"] }

set project_url "/intranet/projects/view?project_id="
set one_response_url "/intranet-simple-survey/one-response?response_id="


# ------------------------------------------------------------
# Check which surveys contain at least one "green/yellow/red" 
# question.
# As a result we'll get a list of questions that only contain
# color values. In a second step with check to wich surveys
# these questions belong to get the list of "color surveys".
# 

set color_question_sql "
	select distinct
		sq.question_id,
		sq.question_text, 
		lower(trim(sqc.label)) as label
	from
		survsimp_question_choices sqc, 
		survsimp_questions sq
	where 
		sqc.question_id = sq.question_id and
		lower(trim(sqc.label)) in ('[join $valid_colors "', '"]')
	order by 
		sq.question_id, sq.question_text
"
db_foreach color_question $color_question_sql {
    # First ocurrence? Set to question_id to indicate that it's OK.
    if {![info exists color_question($question_id)]} { set color_question($question_id) $question_id }
    if {[lsearch $valid_colors $label] < 0} {
	# Not a valid color. Set to "" to mark as bad.
	set color_question($question_id) ""
    }
}

# Get the list of questions that are "pure color"
set color_question_list {0}
foreach qid [array names color_question] {
    set question_id $color_question($qid)
    if {"" != $question_id} { lappend color_question_list $question_id }
}

# Extract the surveys of the "pure color questions" and store
# in hash array for faster access
set color_survey_sql "
	select	survey_id as color_survey_id
	from	survsimp_questions
	where	question_id in ([join $color_question_list ","])
"
db_foreach color_surveys $color_survey_sql {
    set color_survey($color_survey_id) $color_survey_id
}



# ------------------------------------------------------------
# SQLs for pulling out date:
# Together, the tree SQL define left dimension, upper dimension and the two dimensional 
# table in the middle.
#	- The "innter" SQL determines the "facts": All responses between start- and end date.
#	- The "projects" SQL shows the different main-projects where reports have been filed.
#	- The "date" SQL shows the date interval between start- and end date.

set inner_sql "
	select	sr.response_id,
		ss.name as survey_name,
		to_char(o.creation_date, 'J')::integer - to_char(o.creation_date, 'D')::integer + 2 as monday_julian,
		sr.related_object_id as project_id,
		sq.question_id,
		sq.question_text,
		sqc.label as response
	from	acs_objects o,
		survsimp_surveys ss,
		survsimp_questions sq,
		survsimp_responses sr,
		survsimp_question_responses sqr
		LEFT OUTER JOIN survsimp_question_choices sqc ON (sqr.question_id = sqc.question_id and sqr.choice_id = sqc.choice_id)
	where	sr.response_id = o.object_id and
		ss.survey_id = sq.survey_id and
		ss.survey_id = sr.survey_id and
		ss.survey_id = :survey_id and
		sr.response_id = sqr.response_id and
		sq.question_id = sqr.question_id and
		o.creation_date > :start_date::date and
		o.creation_date < :end_date::date
	order by
		ss.survey_id,
		sr.response_id,
		sq.question_id
"

set projects_sql "
	select distinct
		parent.project_id,
		parent.project_name,
		parent.project_status_id,
		im_category_from_id(parent.project_status_id) as project_status,
		parent.project_type_id,
		im_category_from_id(parent.project_type_id) as project_type
	from
		($inner_sql) i,
		im_projects parent,
		im_projects children
	where
		parent.parent_id is null and
		children.project_id = i.project_id and
		children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
		children.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
	order by
		parent.project_name
"

set date_sql "
	select	e.monday_julian,
		to_char(to_date(e.monday_julian, 'J'), 'YYYY') as year,
		to_char(to_date(e.monday_julian, 'J'), 'IW') as week
	from	(
			select distinct 
				to_char(im_day_enumerator, 'J') as monday_julian 
			from	im_day_enumerator (:start_date::date, :end_date::date)
			where	to_char(im_day_enumerator, 'D') = '2'
			order by monday_julian
		) e
"


# ------------------------------------------------------------
# Create dimensions top & left and the inner matrix


set border 0
set gif_size 16
if {[info exists color_survey($survey_id)]} {

    # A "color survey" with at least one "color question" consisting of know color codes
    db_foreach inner $inner_sql {
	set key "$project_id-$monday_julian"
	
	set color_question_p [info exists color_question($question_id)]
	if {$color_question_p && "" == $color_question($question_id)} { set color_question_p 0 }
	if {!$color_question_p} { continue }
	
	# Convert Green/Yellow/Red responses into BB images
	set color [string tolower $response]
	set alt_text $question_text
	set gif [im_gif "bb_$color" $alt_text $border $gif_size $gif_size]
	set html "<a href='$one_response_url$response_id'>$gif</a>\n"
	
	# Append html to the cell
	set val ""
	if {[info exists report_hash($key)]} { set val $report_hash($key) }
	if {"" != $val} { append val "<br>" }
	append val $html
	set report_hash($key) $val
    }
    
} else {

    db_foreach inner $inner_sql {
	set key "$project_id-$monday_julian"
	
	set alt_text $survey_name
	set gif [im_gif "bb_green" $alt_text $border $gif_size $gif_size]
	set html "<a href='$one_response_url$response_id'>$gif</a>\n"
	
	# Write to HTML cell (no append!)
	set report_hash($key) $html
    }

}


# The left dimension consists of infos about the project:
# 0:project_id, 1:project_name, 2:status_id, 3:status, 4:type_id, 5:type
set left_dim [db_list_of_lists projects_left_dim $projects_sql]

# The top dimension is per week
# 0:monday_julian, 1:year, 2:week
set top_dim [db_list_of_lists date_top_dim $date_sql]


# ------------------------------------------------------------
# Write out the HTML

set top_html "<tr class=rowtitle>\n"
append top_html "<td class=rowtitle>[lang::message::lookup "" intranet-simple-survey.Week "Week"]</td>\n"
foreach date_tuple $top_dim {
    set monday_julian [lindex $date_tuple 0]
    set year [lindex $date_tuple 1]
    set week [lindex $date_tuple 2]
    append top_html "<td class=rowtitle>$year<br>$week</td>\n"
}
append top_html "</tr>\n"

# ad_return_complaint 1 $left_dim

set body_html ""
set ctr 0
foreach project_tuple $left_dim {
    set project_id [lindex $project_tuple 0]
    set project_name [lindex $project_tuple 1]
    set status_id [lindex $project_tuple 2]
    set status [lindex $project_tuple 3]
    set type_id [lindex $project_tuple 4]
    set type [lindex $project_tuple 5]

    set row_html "<tr$bgcolor([expr $ctr % 2])><td><a href='$project_url$project_id'>$project_name</a></td>\n"

    foreach date_tuple $top_dim {
	set monday_julian [lindex $date_tuple 0]
	set year [lindex $date_tuple 1]
	set week [lindex $date_tuple 2]

	set key "$project_id-$monday_julian"
	set val ""
	if {[info exists report_hash($key)]} { set val $report_hash($key) }
	append row_html "<td>$val</td>\n"
    }

    append row_html "</tr>\n"
    append body_html $row_html
    incr ctr
}

set html "
	<table>
	$top_html
	$body_html
	</table>
"


if {"" == $html} { 
    set html [lang::message::lookup "" intrant-simple-survey.No_project_reports_found "No project reports found"]
    set html "<p>&nbsp;<p><blockquote><i>$html</i></blockquote><p>&nbsp;<p>\n"
}


# ------------------------------------------------------------
# Left Navbar is the filter/select part of the left bar

set survey_options [db_list_of_lists survey_options "
	select	ss.name,
		ss.survey_id
	from	survsimp_surveys ss
	where	ss.enabled_p = 't'
"]

#set survey_options [linsert $survey_options 0 [list "" ""]]

set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           #intranet-core.Filter_Projects#
        	</div>

        <form action='/intranet-simple-survey/reporting/project-reports' method=GET>
        <table border=0 cellspacing=1 cellpadding=1>
        <tr>
          <td class=form-label>[lang::message::lookup "" intranet-simple-survey.Survey "Survey"]</td>
          <td class=form-widget>
            [im_select -ad_form_option_list_style_p 1 -translate_p 0 survey_id $survey_options $survey_id]
          </td>
        </tr>
        <tr>
          <td class=form-label>#intranet-core.Start_Date#</td>
          <td class=form-widget>
            <input type=textfield name=start_date value='$start_date'>
          </td>
        </tr>
        <tr>
          <td class=form-label>#intranet-core.End_Date#</td>
          <td class=form-widget>
            <input type=textfield name=end_date value='$end_date'>
          </td>
        </tr>
        <tr>
          <td class=form-label></td>
          <td class=form-widget><input type=submit value='#intranet-core.Submit#'></td>
        </tr>
        </table>
        </form>

      	</div>
      <hr/>
"
