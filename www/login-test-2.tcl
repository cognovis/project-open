ad_page_contract {
    Autenticate the user and issue an auth-token
    that needs to be specified for every xmlrpc-request
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    email
    pass
    {url "/RPC2/" }
    {method "sqlapi.login"}
}


# ------------------------------------------------------------
# Security & Defaults
# ------------------------------------------------------------

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Login-Test-2"
set context_bar [im_context_bar $page_title]
set current_user_id [im_xmlrpc_get_user_id]

# ------------------------------------------------------------
# Call the Login XML-RPC procedure
# ------------------------------------------------------------

set error ""
set result ""
set token ""
set info ""
if {[catch {
    set login_result [xmlrpc::remote_call http://172.26.0.3:30038/RPC2 sqlapi.login -string $email -string $pass]
    set status [lindex $login_result 0]
    set user_id [lindex $login_result 1]
    set timestamp [lindex $login_result 2]
    set token [lindex $login_result 3]
} err_msg]} {
    append error $err_msg
}

# ad_return_complaint 1 "$error - $status - token=$token - $login_result"

if {"ok" == $status} {
    ad_returnredirect [export_vars -base "index" {user_id timestamp token}]
}

# ad_return_complaint 1 "<pre>token=$token\ninfo=$info\nerror=$error</pre>"

