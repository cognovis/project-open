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
    {start_date ""}
    {end_date ""}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-reporting-portfolio.Skill_Profile_Occupation "Skill Profile Occupation"]
set context [im_context_bar $page_title]

# set start_date [db_string start_date "select to_char(now()::date - 180, 'YYYY-MM') || '-01' from dual"]
# set end_date [db_string start_date "select (to_char(now()::date + 360, 'YYYY-MM') || '-01')::date from dual"]

set start_date [db_string start_date "select now()::date - 90 from dual"]
set end_date [db_string start_date "select now()::date + 360 from dual"]

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
		pe.person_id in (select member_id from group_distinct_member_map where group_id = (
			select group_id from groups where group_name = 'Skill Profile'
		))
-- and pe.person_id = 8999
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
#    set  [lindex $tuple ]

    append body "<h2>$first_names $last_name ($skill_profile_id)</h2>\n"

    append body [sencha_project_timeline \
		     -diagram_user_id $skill_profile_id \
		     -diagram_start_date $start_date \
		     -diagram_end_date $end_date \
		     -diagram_width 1200 \
		     -diagram_height 300 \
		     -diagram_availability $availability \
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

