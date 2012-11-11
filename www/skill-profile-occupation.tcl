# /packages/sencha-reporting-portfolio/www/skill-profile-occupation.tcl
#
# Copyright (C) 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

ad_page_contract {
    Shows the list of skill profiles and their occupation.
    @author frank.bergmann@project-open.com
} {
    {group_id ""}
    {cost_center_id ""}
    {project_status_id ""}
    {start_date ""}
    {end_date ""}
    {aggregation_level "month"}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-reporting-portfolio.Skill_Profile_Occupation "Skill Profile Occupation"]
set context [im_context_bar $page_title]

if {"" == $start_date} { set start_date [db_string start_date "select now()::date - 90 from dual"] }
if {"" == $end_date} { set end_date [db_string start_date "select now()::date + 360 from dual"] }
if {"" == $group_id} { set group_id [im_profile_skill_profile] }

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

set skill_profile_sql "
	select	pe.person_id,
		pe.first_names,
		pe.last_name,
		pa.email,
		coalesce(e.availability, 100) / 100.0 * 8.0 as availability
	from	persons pe,
		parties pa
		LEFT OUTER JOIN im_employees e ON (pa.party_id = e.employee_id)
	where	pe.person_id = pa.party_id and
		pe.person_id in (select member_id from group_distinct_member_map where group_id = :group_id)
	order by pe.first_names, pe.last_name
"
set skill_profiles [db_list_of_lists skill_profiles $skill_profile_sql]


set body ""
foreach tuple $skill_profiles {
    set skill_profile_id [lindex $tuple 0]
    set first_names [lindex $tuple 1]
    set last_name [lindex $tuple 2]
    set email [lindex $tuple 3]
    set availability [lindex $tuple 4]

    append body "<h2>$first_names $last_name ($skill_profile_id)</h2>\n"

    append body [sencha_project_timeline \
		     -diagram_user_id $skill_profile_id \
		     -diagram_start_date $start_date \
		     -diagram_end_date $end_date \
		     -diagram_project_status_id $project_status_id \
		     -diagram_width 1200 \
		     -diagram_height 300 \
		     -diagram_availability $availability \
		     -diagram_aggregation_level $aggregation_level \
		    ]
}



# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set sub_navbar ""
set main_navbar_label "projects"

set project_menu ""

# Show the same header as the ProjectListPage
set letter ""
set next_page_url ""
set previous_page_url ""
set menu_select_label "skill-profile-use"
set sub_navbar [im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter project_status_id] $menu_select_label]





# ---------------------------------------------------------------
# Filter
# ---------------------------------------------------------------

set form_id "skill_filter"
set action_url "/sencha-reporting-portfolio/skill-profile-occupation"
set form_mode "edit"

set aggregation_options {}
lappend aggregation_options [list [lang::message::lookup "" intranet-core.Day "Day"] "day" ]
lappend aggregation_options [list [lang::message::lookup "" intranet-helpdesk.Week "Week"] "week"]
lappend aggregation_options [list [lang::message::lookup "" intranet-core.Month "Month"] "month"]

set group_options {}
db_foreach groups "
	select	group_id, group_name
	from	groups, im_profiles
	where	group_id = profile_id
	order by group_name
" {
    set group_key $group_name
    lappend group_options [list [lang::message::lookup "" intranet-core.$group_key $group_name] $group_id]
}

set project_status_options []

set cost_center_options [im_department_options 1]

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -form {
    	{group_id:text(select),optional {label "Group/Profile"} {options $group_options}}
    	{cost_center_id:text(select),optional {label "Department"} {options $cost_center_options}}
	{start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {value "$start_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('start_date', 'y-m-d');" >}}}
	{end_date:text(text) {label "[_ intranet-timesheet2.End_Date]"} {value "$end_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('end_date', 'y-m-d');" >}}}
	{project_status_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-core.Project_status {Project Status}]"} {custom {category_type "Intranet Project Status" translate_p 1 package_key "intranet-core"} } }
    	{aggregation_level:text(select),optional {label "Aggregation Level"} {options $aggregation_options}}
    }

template::element::set_value $form_id group_id $group_id
template::element::set_value $form_id cost_center_id $cost_center_id
template::element::set_value $form_id aggregation_level $aggregation_level


# ---------------------------------------------------------------
# Left-Navbar
# ---------------------------------------------------------------


# Compile and execute the formtemplate.
eval [template::adp_compile -string {<formtemplate style=tiny-plain-po id="$form_id"></formtemplate>}]
set filter_html $__adp_output

set left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-core.Filters "Filters"]
		</div>
		$filter_html
	    </div>
	    <hr/>
"

