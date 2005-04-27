ad_page_contract {
    Loads an update info XML file from a URL into a temp directory
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Load Update Information"
set context_bar [im_context_bar $page_title]

set update_url [ad_parameter -package_id [im_update_client_package_id] UpdateServerURL -default "&lt;UpdateServerURL&gt;"]


set update_server "http://[lindex [split $update_url "/"] 2]"

set user_email [db_string user_email "select email from parties where party_id = :user_id" -default ""]
