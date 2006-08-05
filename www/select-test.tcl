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

    set authinfo [list \
	   [list -string token] \
	   [list -int $user_id] \
	   [list -string $timestamp] \
	   [list -string $token] \
    ]

    set query_results [xmlrpc::remote_call \
			   http://172.26.0.3:30038/RPC2 \
			   sqlapi.object_types \
			   -array $authinfo
		      ]

} err_msg]} {
    append error $err_msg
}

set object_type_options ""
set status [lindex $query_results 0]
set object_types_list [lindex $query_results 1]

if {"ok" != $status} {

    set error "$status "
    append error [lindex $query_results 1]

} else {

    foreach object_type_record $object_types_list {
	set object_type [lindex $object_type_record 0]
	set pretty_name [lindex $object_type_record 1]
	append object_type_options "<option value=\"$object_type\">$pretty_name</option>\n"
    }
}





