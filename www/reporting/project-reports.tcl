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

set page_title [lang::message::lookup "" intranet-simple-survey.Project_Reports "Project Reports"]
set context_bar [im_context_bar $page_title]
set context ""
set show_context_help_p 1

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
    set menu_select_label "projects_gantt_resources"
    set sub_navbar [im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter project_status_id] $menu_select_label]

}

# ------------------------------------------------------------
# Defaults

if {"" == $start_date} { set start_date [db_string start_date "select now()::date - 90"] }
if {"" == $end_date} { set end_date [db_string start_date "select now()::date + 7"] }

set project_url "/intranet/projects/view?project_id="


# ------------------------------------------------------------
# SQLs for pulling out date:
# Together, the tree SQL define left dimension, upper dimension and the two dimensional 
# table in the middle.
#	- The "innter" SQL determines the "facts": All responses between start- and end date.
#	- The "projects" SQL shows the different main-projects where reports have been filed.
#	- The "date" SQL shows the date interval between start- and end date.

set inner_sql "
	select	sr.survey_id,
		sr.response_id,
		ss.name as survey_name,
		to_char(o.creation_date, 'J')::integer - to_char(o.creation_date, 'D')::integer + 2 as monday_julian,
		sr.related_object_id as project_id,
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
			where	to_char(im_day_enumerator, 'D') = 2
			order by monday_julian
		) e
"

# ------------------------------------------------------------
# Create dimensions top & left and the inner matrix

set border 0
set gif_size 16
db_foreach inner $inner_sql {
    set key "$project_id-$monday_julian"

    # Convert Green/Yellow/Red responses into BB images
    set color [string tolower $response]
    if {[lsearch {green yellow red purple blue cyan} $color] < 0} { continue }
    set alt_text ""
    set gif [im_gif "bb_$color" $alt_text $border $gif_size $gif_size]
    set link "<a href=''>$gif</a>\n"

    # Append value to the cell
    set val ""
    if {[info exists report_hash($key)]} { set val $report_hash($key) }
    if {"" != $val} { append val "<br>" }
    append val $link
    set report_hash($key) $val
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
foreach date_tuple $top_dim {
    set monday_julian [lindex $date_tuple 0]
    set year [lindex $date_tuple 1]
    set week [lindex $date_tuple 2]
    append top_html "<td class=rowtitle>$year<br>$week</td>\n"
}
append top_html "</tr>\n"

# ad_return_complaint 1 $left_dim

set body_html ""
foreach project_tuple $left_dim {
    set project_id [lindex $project_tuple 0]
    set project_name [lindex $project_tuple 1]
    set status_id [lindex $project_tuple 2]
    set status [lindex $project_tuple 3]
    set type_id [lindex $project_tuple 4]
    set type [lindex $project_tuple 5]

    set row_html "<tr><td><a href='$project_url/$project_id'>$project_name</a></td>\n"

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

set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           #intranet-core.Filter_Projects#
        	</div>

        <form action='/intranet-ganttproject/gantt-resources-cube' method=GET>
        <table border=0 cellspacing=1 cellpadding=1>
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
