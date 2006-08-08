ad_page_contract {
    Autenticate the user and issue an auth-token
    that needs to be specified for every xmlrpc-request
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    user_id
    timestamp
    token
    object_id
    url
    {method "sqlapi.select"}
}


# ------------------------------------------------------------
# Security & Defaults
# ------------------------------------------------------------

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Select-Test-2"
set context_bar [im_context_bar $page_title]
set current_user_id [im_xmlrpc_get_user_id]

# ------------------------------------------------------------
# Call the Login XML-RPC procedure
# ------------------------------------------------------------

set error ""
set result ""
set info ""

set query_results [list]

if {[catch {

    set authinfo [list \
           [list -string token] \
           [list -int $user_id] \
           [list -string $timestamp] \
           [list -string $token] \
    ]

    # sqlapi.select(user_id timestamp token object_type object_id)
    set query_results [xmlrpc::remote_call \
	$url \
	sqlapi.object_info \
	-array $authinfo \
	-int $object_id \
    ]

} err_msg]} {
    append error $err_msg
}

# ad_return_complaint 1 $error


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


