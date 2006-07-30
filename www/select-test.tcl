ad_page_contract {
    Autenticate the user and issue an auth-token
    that needs to be specified for every xmlrpc-request
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    user_id
    timestamp
    token
    {url "/RPC2/" }
}


# ------------------------------------------------------------
# Security & Defaults
# ------------------------------------------------------------

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Select-Test"
set context_bar [im_context_bar $page_title]

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

# ------------------------------------------------------------
# Get the list of object types from the target system
# ------------------------------------------------------------

set error ""
set query_results [list]
if {[catch {

    set query_results [xmlrpc::remote_call http://172.26.0.3:30038/RPC2 sqlapi.select \
                  -string $user_id \
                  -string $timestamp \
                  -string $token \
                  -string "object_type"
    ]

} err_msg]} {
    append error $err_msg
}

set status [lindex $query_results 0]
if {"ok" != $status} {

    set error "$status "
    append error [lindex $query_results 1]

} else {

    set object_fields [lindex $query_results 1]
    array set ovars $object_fields
    set keys [array names ovars]

    set result "<table>\n"
    foreach key $keys {
	append result "<tr><td>$key</td><td>$ovars($key)</td></tr>\n"
    }
    append result "</table>\n"
}


