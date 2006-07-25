ad_page_contract {
    Autenticate the user and issue an auth-token
    that needs to be specified for every xmlrpc-request
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    user_id 
    password
    
}


# ------------------------------------------------------------
# Security & Defaults
# ------------------------------------------------------------

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Load Update Information"
set context_bar [im_context_bar $page_title]

set package_root_dir [acs_package_root_dir "intranet-update-server"]
set file "$package_root_dir/update.xml"

ns_log Notice "update: before authority_options"

set authority_options [auth::authority::get_authority_options]
if { ![exists_and_not_null authority_id] } {
    set authority_id [lindex [lindex $authority_options 0] 1]
}

# Register the interaction if intranet-crm-tracking is installed
if {[db_table_exists crm_online_interactions]} {

    catch {crm_basic_interaction -interaction_type_id [crm_asus_login] -email $email -password $password} errmsg

}

array set auth_info [auth::authenticate \
	-return_url $return_url \
        -authority_id $authority_id \
	-email [string trim $email] \
	-password $password 
]

ns_log Notice "update: after authenticate: status=$auth_info(auth_status)"


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

# Not a successul login...
if {!$successful_login} {
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
	</po_software_update>\n"
    doc_return 500 text/xml $error_xml
    return
}

# ------------------------------------------------------------
# Successful Login
# ------------------------------------------------------------

# Check the users's cvs_user and cvs_password fields
set cvs_user "anonymous"
set cvs_password ""
set auth_user_id $auth_info(user_id)

if {[db_column_exists persons cvs_user]} {
    db_0or1row cvs_info "
	select
		cvs_user,
		cvs_password
	from
		persons
	where
		person_id = :auth_user_id
    "
}

# Currently: No check if cvs_user was "" (no account):
# We allow everybody to check the server as "anonymous"


# update.xml file for some reason unavailable
if {![file readable $file]} {
    set error_xml "
	<po_software_update>
	  <login>
	    <login_status>fail</login_status>
	    <login_message>Internal Server Error: File not readable. 
	    Please notify support@project-open.com.</login_message>
	  </login>
	  <account>
	  </account>
	  <update_list>
	  </update_list>
	</po_software_update>\n"
    doc_return 500 text/xml $error_xml
    return
}


# Everything OK so far, so let's get the update.xml file
if {[catch {

    ns_log Notice "update: Opening $file"
    set fileChan [open $file]
    ns_log Notice "update: fileChan=$fileChan"
    ns_log Notice "update: before gets"
    while {[gets $fileChan line] >= 0} {
#	ns_log Notice "update: getting line..."
	append update_xml "$line\n"
    }
    ns_log Debug "update: Done copying data."
    close $fileChan
    
} errmsg]} {

    # Try to close the channel anyway
    catch { [close $fileChan]} errmsg1
    
    # update.xml file for some reason unavailable
    set error_xml "
		<po_software_update>
		  <login>
		    <login_status>fail</login_status>
		    <login_message>Internal Server Error: Error accessing data. 
		    Please notify support@project-open.com.</login_message>
		  </login>
		  <account>
		  </account>
		  <update_list>
		  </update_list>
		</po_software_update>\n"
    doc_return 500 text/xml $error_xml
    return
}
	

# Add the CVS login information and return the result
set tree ""
if { [catch {

    ns_log Notice "update: before parsing the XML file"
    set tree [xml_parse -persist $update_xml]
    set root_node [$tree documentElement]
    set login_node [$root_node selectNodes {//login}]
    
    ns_log Notice "update: before adding cvs login information"
    $login_node appendXML "<cvs_user>$cvs_user</cvs_user>"
    $login_node appendXML "<cvs_password>$cvs_password</cvs_password>"
    
    ns_log Notice "update: before asXML return"
    doc_return 200 text/xml [$tree asXML]
    xml_doc_free $tree
    return
	    
} errmsg] } {

    # update.xml file for some reason unavailable
    set error_xml "
		<po_software_update>
		  <login>
		    <login_status>fail</login_status>
		    <login_message>
	              Internal Server Error: Error parsing the server-side XML file. 
		      Please notify support@project-open.com.
	              $errmsg
                    </login_message>
		  </login>
		  <account>
		  </account>
		  <update_list>
		  </update_list>
		</po_software_update>\n"
    if {"" != $tree} { xml_doc_free $tree }
    doc_return 500 text/xml $error_xml
    return
}

