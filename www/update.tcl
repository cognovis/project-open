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
	set login_status "ok"
	set login_message "Successful Login"
    }
    bad_password {
	set login_status "fail"
	set login_message "Bad password. Your password doesn't match your user name."
    }
    default {
	set login_status "fail"
	set login_message "Authentication error. There was an error during authentification. Please check your email and password."
    }
}

set package_root_dir [acs_package_root_dir "intranet-update-client"]
set file "$package_root_dir/update.xml"


if {$successful_login} {

    if {[file readable $file]} {
	rp_serve_concrete_file $file
    } else {
	set error_xml "
<po_software_update>
  <login>
    <login_status>fail</login_status>
    <login_message>Internal Server Error: 'file not readable'. Please notify support@project-open.com.</login_message>
  </login>

  <account>
  </account>

  <update_list>
  </update_list>
</po_software_update>
"
	doc_return 500 text/xml $error_xml
    }


} else {

    set error_xml "
<po_software_update>
  <login>
    <login_status>$login_status</login_status>
    <login_message>$login_message</login_message>
  </login>

  <account>
  </account>

  <update_list>
  </update_list>
</po_software_update>
"
    doc_return 500 text/xml $error_xml
}


