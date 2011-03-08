# Version bar, to be included on all pages

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

if { !$versions_p } {
    return
}

# Project info

set current_version_id [bug_tracker::conn current_version_id]
set current_version_name [bug_tracker::conn current_version_name]

# User info (user may not be logged in)

set user_id [ad_conn user_id]

set return_url "[ad_conn url][ad_decode [ad_conn query] "" "" "?[ad_conn query]"]"
set login_url "/register/?[export_vars -url { return_url }]"

set user_version_id [bug_tracker::conn user_version_id]
set user_version_name [bug_tracker::conn user_version_name]

set package_url [ad_conn package_url]

set user_version_url "[ad_conn package_url]prefs?[export_vars -url { return_url }]"

ad_return_template
