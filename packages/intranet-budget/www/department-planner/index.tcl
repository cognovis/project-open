# /packages/intranet-budget/www/department-planner/index.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows a portfolio of projects ordered by priority.
    The assigned work days to the project's tasks are deduced from the
    resources available per cost_center.

    Note: There is only a single portfolio here, as the cost center's 
    resources are not separated per portfolio.

    @author frank.bergmann@project-open.com
} {
    { view_name "" }
    { project_id "" }
    { ajax_p "0" }
}

# ---------------------------------------------------------------
# Title
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-budget.Department_Planner "Department Planner"]
set context_bar [im_context_bar $page_title]

# ---------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set current_user_id [im_require_login]
set menu_label "reporting-department-planner"
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']
set read_p "t"
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

set project_base_url "/intranet/projects/view"
set this_base_url "/intranet-budget/department-planner/index"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "




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
    set menu_select_label "department_planner"
    set sub_navbar [im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter project_status_id] $menu_select_label]

}

# ---------------------------------------------------------------
# Start and End Date
# ---------------------------------------------------------------

db_1row todays_date "
        select
                to_char(sysdate::date, 'YYYY') as todays_year
        from dual
"
set year $todays_year
set year_list [list]
while {$year < [expr $todays_year + 5]} {
    lappend year_list [list $year $year]
    incr year
}


# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

ad_form -name department_planner_filter -form {
    {filter_year:text(select),optional
	{label "[_ intranet-budget.filter_year]"}
	{options "$year_list"}
    }
    {include_remaining_p:text(checkbox),optional
	{label "[_ intranet-budget.include_remaining_effort]"}
	{options {{"" 1}}}
    }
    {view_name:text(hidden) {value $view_name}}
    {ajax_p:text(hidden) {value $ajax_p}}
} -on_request {   
    set filter_year $todays_year
    set include_remaining_p 0
} 
