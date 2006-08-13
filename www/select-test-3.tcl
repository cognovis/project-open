ad_page_contract {
    Autenticate the user and issue an auth-token
    that needs to be specified for every xmlrpc-request
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    user_id
    timestamp
    token
    object_type
    column_name
    column_operator
    column_value
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
# 
# ------------------------------------------------------------

set error ""
set result ""
set info ""

set query_results [list]


# Get the list of all objects of that type
if {[catch {

    set authinfo [list \
	   [list -string token] \
	   [list -int $user_id] \
	   [list -string $timestamp] \
	   [list -string $token] \
    ]

    set where_condition1  [list \
	[list -string $column_name] \
	[list -string $column_operator] \
	[list -string $column_value] \
    ]

    set query_results [xmlrpc::remote_call \
	$url \
	"sqlapi.select" \
	-array $authinfo \
	-string $object_type \
	-array [list [list -array $where_condition1] [list -array $where_condition1]] \
    ]

} err_msg]} {
    append error $err_msg
}

set status [lindex $query_results 0]
set object_id_options [list]

if {"ok" != $status} {

    set error "$status "
    set error_msg [lindex $query_results 1]


} else {

    set object_ids [lindex $query_results 1]
    foreach id $object_ids {
	set object_id [lindex $id 0]
	set object_name [lindex $id 1]
	append object_id_options "<option value=\"$object_id\">$object_name</option>\n"
    }
}


