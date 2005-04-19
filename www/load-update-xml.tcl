ad_page_contract {
    Loads an update info XML file from a URL into a temp directory
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
}

set user_id [auth::require_login]
set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Load Update Information"
set context_bar [im_context_bar $page_title]

set update_url [ad_parameter -package_id [im_update_client_package_id] UpdateServerURL -default "&lt;UpdateServerURL&gt;"]

set update_server "http://[lindex [split $update_url "/"] 2]"

#if {[string range $update_url 0 6] == "http://"} {
#    set update_url [string range $update_url 7 end]
#}


set user_email [db_string user_email "select email from parties where party_id = :user_id" -default ""]
