ad_page_contract { 
    Bug-Tracker versions admin page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]

set context_bar [ad_context_bar "Versions"]

set version_add_url "version-ae?[export_vars -url { { return_url "versions" } }]"

set return_url "versions"

db_multirow -extend { maintainer_url edit_url delete_url release_url } current_version current_version {
} { 
    set edit_url "version-ae?[export_vars -url { version_id return_url }]"
    if { $num_bugs == 0 } {
        set delete_url "version-delete?[export_vars -url { version_id }]"
    } else {
        set delete_url {}
    }
    set release_url "version-release?[export_vars { version_id }]"
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

db_multirow -extend { maintainer_url edit_url delete_url set_active_url } future_version future_versions {
} { 
    set edit_url "version-ae?[export_vars -url { version_id return_url }]"
    if { $num_bugs == 0 } {
        set delete_url "version-delete?[export_vars -url { version_id }]"
    } else {
        set delete_url {}
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
    set set_active_url "version-set-active?[export_vars -url { version_id return_url }]"
}

db_multirow -extend { maintainer_url edit_url delete_url } past_version past_versions {
} { 
    set edit_url "version-ae?[export_vars -url { version_id return_url }]"
    if { $num_bugs == 0 } {
        set delete_url "version-delete?[export_vars -url { version_id }]"
    } else {
        set delete_url {}
    }
    set maintainer_url [acs_community_member_url -user_id $maintainer]
}

ad_return_template



