# Nav bar, to be included on all pages

global bt_nav_bar_count
if { ![info exists bt_nav_bar_count] } {
    set bt_nav_bar_count 1
} else {
    incr bt_nav_bar_count
}

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set component_id [bug_tracker::conn component_id]

set admin_p [permission::permission_p \
                 -party_id [ad_conn untrusted_user_id] \
                 -object_id $package_id \
                 -privilege admin]

if { [ad_conn untrusted_user_id] == 0 } { 
    set create_p 1
} else {
    set create_p [permission::permission_p \
                      -party_id [ad_conn untrusted_user_id] \
                      -object_id [ad_conn package_id] \
                      -privilege create]
}

bug_tracker::get_pretty_names -array pretty_names

set notification_url [lindex $notification_link 0]
set notification_label [lindex $notification_link 1]
set notification_title [lindex $notification_link 2]

# Paches enabled for this project?
set patches_p [bug_tracker::patches_p]

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

regexp {/([^/]+)/[^/]*$} [ad_conn url] match last_dir

if { [string equal $last_dir "admin"] } {
    set url_prefix [ad_conn package_url]
} else {
    set url_prefix ""
}


multirow create links name url

array set filter [bug_tracker::conn filter]

set workflow_id [bug_tracker::bug::get_instance_workflow_id]
set initial_state_id [workflow::fsm::get_initial_state -workflow_id $workflow_id]

multirow append links "[bug_tracker::conn Bugs]" [export_vars -base "${url_prefix}." { { f_fix_for_version {[bug_tracker::conn current_version_id]} } }]

if { $create_p } {
    multirow append links "New [bug_tracker::conn Bug]" "${url_prefix}bug-add"
}

if { [ad_conn untrusted_user_id] != 0 } {
    # Lars: Taken out
    # Could mean one of
    # - I submitted
    # - I'm supposed to resolve
    # - I'm supposed to verify and close
    #multirow append links "My [bug_tracker::conn Bugs]" "${url_prefix}.?[export_vars -url { { filter.assignee {[ad_conn user_id]} } }]"
}

if { $patches_p } {
    multirow append links "Patches" [export_vars -no_empty -base "[ad_conn package_url]patch-list" { { status open } { apply_to_version {[bug_tracker::conn current_version_id]} } }]

    if { $create_p } {
        multirow append links "New Patch" "[ad_conn package_url]patch-add"
    }
}

multirow append links "Notifications" "[ad_conn package_url]notifications"

if { $versions_p } {
    multirow append links "Prefs" "[ad_conn package_url]prefs"
}

if { $admin_p } {
    multirow append links "Admin" "[ad_conn package_url]admin/"
}

set form_action_url "[ad_conn package_url]bug"

ad_return_template
