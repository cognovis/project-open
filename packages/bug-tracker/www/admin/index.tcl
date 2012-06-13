ad_page_contract { 
    Bug-Tracker project admin page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]
set page_title "Administration"

set bugs_exist_p [bug_tracker::bugs_exist_p]

bug_tracker::get_pretty_names -array pretty_names

set versions_p [bug_tracker::versions_p]

set context_bar [ad_context_bar]

db_1row project_info { } -column_array project

set project(maintainer_url) [acs_community_member_url -user_id $project(maintainer)]

set project_edit_url "project-edit"
set project_maintainer_edit_url "project-edit"
set versions_edit_url "versions"
set categories_edit_url "categories"
set permissions_edit_url "permissions"
set parameters_edit_url "/shared/parameters?[export_vars { { return_url [ad_return_url] } { package_id {[ad_conn package_id]} } }]"
set severity_codes_edit_url "severity-codes"
set priority_codes_edit_url "priority-codes"

db_multirow -extend { edit_url delete_url maintainer_url view_bugs_url } components components {} {
    set edit_url "component-ae?[export_vars { component_id }]"
    if { $num_bugs == 0 } {
        set delete_url "component-delete?[export_vars { component_id }]"
        set view_bugs_url {}
    } else {
        set view_bugs_url "../?[export_vars { { filter.component_id $component_id } { filter.status any } }]"
        set delete_url {}
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

set component_add_url "component-ae"
