ad_page_contract {
    Loads an update info XML file from a URL into a temp directory
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { return_url "" }
    email
    password
    { persistent_p "t" }
}

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Load Update Information"
set context_bar [im_context_bar $page_title]


set authority_options [auth::authority::get_authority_options]

if { ![exists_and_not_null authority_id] } {
    set authority_id [lindex [lindex $authority_options 0] 1]
}


array set auth_info [auth::authenticate \
	-return_url $return_url \
        -authority_id $authority_id \
	-email [string trim $email] \
	-password $password 
]

# Handle authentication problems
set successful_login 0
set login_message ""
set login_status ""
switch $auth_info(auth_status) {
    ok {
	set successful_login 1
	set login_status "Successful Login"
    }
    bad_password {
	set login_status "Bad Password"
	set login_message "Your password doesn't match your user name."
    }
    default {
	set login_status "Login Error"
	set login_message "There was an error during your authentification. Possibly your email or password are wrong."
    }
}

set package_root_dir [acs_package_root_dir "intranet-update-client"]
set file "$package_root_dir/update.xml"


if {$successful_login} {

    if {[file readable $file]} {
	rp_serve_concrete_file $file
    } else {
	set error_xml "
<update_list>
  <login_status>Internal Server Error</login_status>
  <login_message>There was an internal server error. Please notify support@project-open.com.</login_message>
</update_list>
"
	doc_return 500 text/xml $error_xml
    }


} else {

    set error_xml "
<update_list>
  <login_status>$login_status</login_status>
  <login_message>$login_message</login_message>
</update_list>
"
    doc_return 500 text/xml $error_xml
}


