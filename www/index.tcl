ad_page_contract {
    Autenticate the user and issue an auth-token
    that needs to be specified for every xmlrpc-request
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { url "/RPC2/"}
    { user_id ""}
    { timestamp ""}
    { token ""}
}


# ------------------------------------------------------------
# Security & Defaults
# ------------------------------------------------------------

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "XML-RPC"
set context_bar [im_context_bar $page_title]

set vars [export_vars {user_id timestamp token url}]

# ------------------------------------------------------------
# 
# ------------------------------------------------------------


