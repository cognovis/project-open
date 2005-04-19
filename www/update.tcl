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
switch $auth_info(auth_status) {
    ok {
	# Continue below
    }
    bad_password {
	ad_return_complaint 1 "Bad Password: <br>Your password doesn't match your user name."
	break
    }
    default {
	ad_return_complaint 1 "Login Error: <br>There was an error during your authentification. 
        <br>Possibly your email or password are wrong."
	break
    }
}


set package_root_dir [acs_package_root_dir "intranet-update-client"]
set file "$package_root_dir/update.xml"
set guessed_file_type "text/xml"

if {[file readable $file]} {
    rp_serve_concrete_file $file
} else {
    doc_return 500 text/html "[_ intranet-filestorage.lt_Did_not_find_the_spec]"
}
