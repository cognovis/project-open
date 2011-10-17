ad_library {
    Drivers for authentication, account management, and password management over LDAP.
    Special version for authentication agains MS Active Directory using the "ldapsearch"
    tool.

    @author Lars Pind (lars@collaobraid.biz)
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2008-01-13
}

package require base64 2.3.1

namespace eval auth {}
namespace eval auth::ldap {}
namespace eval auth::ldap::authentication {}
namespace eval auth::ldap::password {}
namespace eval auth::ldap::registration {}
namespace eval auth::ldap::user_info {}


ad_proc -private auth::ldap::after_install {} {} {
    set spec {
        contract_name "auth_authentication"
        owner "auth-ldap-adldapsearch"
        name "LDAP"
        pretty_name "LDAP"
        aliases {
            Authenticate auth::ldap::authentication::Authenticate
            GetParameters auth::ldap::authentication::GetParameters
        }
    }

    set auth_impl_id [acs_sc::impl::new_from_spec -spec $spec]

    set spec {
        contract_name "auth_password"
        owner "auth-ldap-adldapsearch"
        name "LDAP"
        pretty_name "LDAP"
        aliases {
            CanChangePassword auth::ldap::password::CanChangePassword
            ChangePassword auth::ldap::password::ChangePassword
            CanRetrievePassword auth::ldap::password::CanRetrievePassword
            RetrievePassword auth::ldap::password::RetrievePassword
            CanResetPassword auth::ldap::password::CanResetPassword
            ResetPassword auth::ldap::password::ResetPassword
            GetParameters auth::ldap::password::GetParameters
        }
    }

    set pwd_impl_id [acs_sc::impl::new_from_spec -spec $spec]

    set spec {
        contract_name "auth_registration"
        owner "auth-ldap-adldapsearch"
        name "LDAP"
        pretty_name "LDAP"
        aliases {
            GetElements auth::ldap::registration::GetElements
            Register auth::ldap::registration::Register
            GetParameters auth::ldap::registration::GetParameters
        }
    }

    set registration_impl_id [acs_sc::impl::new_from_spec -spec $spec]

    set spec {
        contract_name "auth_user_info"
        owner "auth-ldap-adldapsearch"
        name "LDAP"
        pretty_name "LDAP"
        aliases {
            GetUserInfo auth::ldap::user_info::GetUserInfo
            GetParameters auth::ldap::user_info::GetParameters
        }
    }

    set user_info_impl_id [acs_sc::impl::new_from_spec -spec $spec]
}

ad_proc -private auth::ldap::before_uninstall {} {} {

    acs_sc::impl::delete -contract_name "auth_authentication" -impl_name "LDAP"

    acs_sc::impl::delete -contract_name "auth_password" -impl_name "LDAP"

    acs_sc::impl::delete -contract_name "auth_registration" -impl_name "LDAP"

    acs_sc::impl::delete -contract_name "auth_user_info" -impl_name "LDAP"
}

ad_proc -private auth::ldap::get_user {
    {-element ""}
    {-username:required}
    {-parameters:required}
} {
    Find a user in LDAP by username, and return a list 
    of { attribute value attribute value ... } or a specific attribute value,
    if the -element switch is set.
} { 
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::get_user -element $element -username $username -parameters $parameters"

    # Parameters
    array set params $parameters

    # Default result
    array set result {
        info_status "ok"
        info_message {}
        user_info {}
    }

    return [list [array get result]]


    set uri $params(LdapURI)
    set base_dn $params(BaseDN)
    set bind_dn $params(BaseDN)

    foreach var { username } {
        regsub -all "{$var}" $base_dn [set $var] base_dn
        regsub -all "{$var}" $bind_dn [set $var] bind_dn
    }

    set return_code [catch {
        exec ldapsearch -x -H $uri -b $base_dn (&(objectcategory=person)(objectclass=user)(sAMAccountName=$username))
        ns_log Notice "auth::ldap::get_user: ldapsearch -x -H $uri -b $base_dn (&(objectcategory=person)(objectclass=user)(sAMAccountName=$username))"
    } msg]

    set search_result [auth::ldap::parse_ldap_reply $msg]

    if { [llength $search_result] != 1 } { return [list] }
    if { [empty_string_p $element] } { return $search_result }

    foreach { attribute value } [lindex $search_result 0] {
        if { [string equal $attribute $element] } {
            # Values are always wrapped in an additional list
	    # not for dn (roc)
            if [string equal $element "dn"] {
		return $value
	    } else {
		return [lindex $value 0]
	    }
        }
    }
    
    return {}
}



ad_proc -private auth::ldap::parse_ldap_reply { 
    ldap_reply 
} {
	Returns a list of elements for each ldap reply
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::parse_ldap_reply $ldap_reply"
    return [list]
}


ad_proc -private auth::ldap::check_password {
    password_from_ldap
    password_from_user
} {
    Checks a password from LDAP and returns 1 for match, 0 for no match or problem verifying.
    Supports MD5, SMD5, SHA, SSHA, and CRYPT.
    @param password_from_ldap The value of the userPassword attribute in LDAP, typically something like 
                              {SSHA}H1W8YiEXl5lwzc7odaU73pNDun9uHRSH.
    @param password_from_user The password entered by the user.
    @return 1 if passwords match, 0 otherwise.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::check_password $password_from_ldap $password_from_user"

    set result 0

    if { [regexp "{(.*)}(.*)" $password_from_ldap match cypher digest_base64] } {
        switch [string toupper $cypher] {
            MD5 - SMD5 {
                set digest_from_ldap [base64::decode $digest_base64]
                set hash_from_ldap [string range $digest_from_ldap 0 15]
                set salt_from_ldap [string range $digest_from_ldap 16 end]
                set hash_from_user [binary format H* [md5::md5 "${password_from_user}${salt_from_ldap}"]]
                if { [string equal $hash_from_ldap $hash_from_user] } {
                    set result 1
                }
            }
            SHA - SSHA {
                set digest_from_ldap [base64::decode $digest_base64]
                set hash_from_ldap [string range $digest_from_ldap 0 19]
                set salt_from_ldap [string range $digest_from_ldap 20 end]
                set hash_from_user [binary format H* [ns_sha1 "${password_from_user}${salt_from_ldap}"]]
                if { [string equal $hash_from_ldap $hash_from_user] } {
                    set result 1
                }
            }
            CRYPT {
                set hash_from_ldap $digest_base64
                set salt_from_ldap [string range $digest_base64 0 1]
                set hash_from_user [ns_crypt $password_from_user $salt_from_ldap]
                if { [string equal $hash_from_ldap $hash_from_user] } {
                    set result 1
                }
            }
        }
    }
    return $result
}

ad_proc -private auth::ldap::set_password {
    {-dn:required}
    {-new_password:required}
    {-parameters:required}
} {
    Update an LDAP user's password.
} {
    ns_log Notice "auth-ldap-adldapsearch: set_password -dn $dn -new_password $new_password -parameters $parameters"

    # Parameters
    array set params $parameters

    set password_hash [string toupper $params(PasswordHash)]
    set new_password_hashed {}
    
    switch $password_hash {
        MD5 {
            set new_password_hashed [binary format H* [md5::md5 $new_password]]
        }
        SMD5 {
            set salt [ad_generate_random_string 4]
            set new_password_hashed [binary format H* [md5::md5 "${new_password}${salt}"]]
            append new_password_hashed $salt
        }
        SHA {
            set new_password_hashed [binary format H* [ns_sha1 $new_password]]
        }
        SSHA {
            set salt [ad_generate_random_string 4]
            set new_password_hashed [binary format H* [ns_sha1 "${new_password}${salt}"]]
            append new_password_hashed $salt
        }
        CRYPT {
            set salt [ad_generate_random_string 2]
            set new_password_hashed [ns_crypt $new_password $salt]
        }
        default {
            error "Unknown hash method, $password_hash"
        }
    }
        
    set lh [ns_ldap gethandle ldap]
    ns_ldap modify $lh $dn mod: userPassword [list "{$password_hash}[base64::encode $new_password_hashed]"]
    ns_ldap releasehandle $lh
}


#####
#
# LDAP Authentication Driver
#
#####


ad_proc -private auth::ldap::authentication::Authenticate {
    {-disable_password_check_p 0}
    username
    password
    {parameters {}}
    {authority_id {}}
} {
    Implements the Authenticate operation of the auth_authentication 
    service contract for LDAP Active Directory and OpenLDAP.
    <ul>
    <li>Active Directory<br>
	AD doesn't return password information, so we have to try to "bind" to AD
	using the current user.
    <li>OpenLDAP<br>
	OL requires a specific user+password (BindDN+BindPW) for connecting.
	BindDN is typically something like "cn=Manager,dc=project-open,dc=com".
	OL returns a "userPassword" value when searching for the uid=username.
    </ul>

} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::authentication::Authenticate: username=$username, pwd=$password, auth_id=$authority_id, params='$parameters'"

    # Default setting for auth_info return hash: Bad Password
    set auth_info(auth_status) "bad_password"
    set auth_info(user_id) 0
    set auth_info(info_status) "ok"
    set auth_info(auth_message) "Generic Error"
    set auth_info(account_status) "ok"
    set auth_info(account_message) ""


    if {"" == [string trim $password]} {
	set auth_info(auth_message) "Empty password"
	return [array get auth_info]
    }

    # Parameters
    array set params $parameters

    # Default to failure
    set result(auth_status) bad_password

    # -----------------------------------------------------------------
    # Pull out the LDAP parameter values. "Catch" errors for compatibility
    
    # The LDAP server like: "ldap://localhost"
    set uri $params(LdapURI)
    # The "domain name", ex: "dc=project-open,dc=com"
    set base_dn $params(BaseDN)
    # The LDAP-user to connect to the LDAP database. 
    # This is a fixed account for OpenLDAP ("cn=Manager,dc=project-open,dc=com"),
    # while Active Directory needs the DN of the user ("{username}@project-open.com")
    set bind_dn $params(BindDN)
    # "ad" = Active Directory, "ol" = OpenLDAP
    set server_type "ad"
    catch { set server_type $params(ServerType) }
    set search_filter ""
    catch { set search_filter $params(SearchFilter) }
    # One of {uid|sAMAccountName}
    set username_attribute ""
    catch { set username_attribute $params(UsernameAttribute) }

    # Substitute username in both BindDN and BaseDN
    foreach var { username } {
        regsub -all "{$var}" $base_dn [set $var] base_dn
        regsub -all "{$var}" $bind_dn [set $var] bind_dn
    }

    switch $server_type {
	ad {

	    # ------------------------------------------------------------------------------
	    # For AD auth, we just try to bind as the user and check if that is OK.
	    ns_log Notice "auth::ldap::authentication::Authenticate: Active Directory"
	    ns_log Notice "ldapsearch -n -x -H $uri -D $bind_dn -w xxxxxxxxx"
	    set return_code [catch {
		exec ldapsearch -n -x -H $uri -D $bind_dn -w $password
	    } err_msg]
	    ns_log Notice "auth::ldap::authentication::Authenticate: return_code=$return_code, msg=$err_msg"

	    if {$disable_password_check_p} {
		set return_code 0
		set err_msg ""
	    }

	    # Extract the first line - it contains the error message if there is an issue.
	    set err_msg_first_line ""
	    if {"" == $err_msg_first_line} { regexp {^(.*)\n} $err_msg match err_msg_first_line }
	    if {"" == $err_msg_first_line} { regexp {^(.*\))} $err_msg match err_msg_first_line }
	    
	    # ----------------------------------------------------
	    # Successfully verified the username/password
	    if {0 == $return_code} {
		set uid [db_string uid "select party_id from cc_users where lower(email) = lower(:base_dn) OR lower(username) = lower(:username) " -default 0]
		set auth_info(auth_status) "ok"
		set auth_info(user_id) $uid
		set auth_info(auth_message) "Login Successful"

		# Sync the user with the LDAP information, with username as primary key
		set auth_info_array [auth::ldap::authentication::Sync $username $parameters $authority_id]
		array set auth_info $auth_info_array
		return [array get auth_info]
	    }
	    
	    # ----------------------------------------------------
	    # We had an issue with the LDAP
	    if {[regexp {Invalid credentials \(49\)} $err_msg]} {
		set auth_info(auth_status) "bad_password"
		set auth_info(user_id) 0
		set auth_info(auth_message) "Bad user or password:<br>$err_msg_first_line"
		set auth_info(account_status) "ok"
		set auth_info(account_message) ""
		return [array get auth_info]
	    }
	    
	    set auth_info(auth_status) "auth_error"
	    set auth_info(user_id) 0
	    set auth_info(auth_message) "LDAP error:<br>$err_msg_first_line"
	    set auth_info(account_status) "ok"
	    set auth_info(account_message) ""
	    return [array get auth_info]
	    
	}
	ol {

	    # ------------------------------------------------------------------------------
	    # For OpenLDAP auth, we retreive the "userPassword" field of the user and
	    # check if we can construct the same hash
	    ns_log Notice "auth::ldap::authentication::Authenticate: OpenLDAP"
	    ns_log Notice "ldapsearch -x -H $uri -D $bind_dn -w $password -b $base_dn '$username_attribute=$username' userPassword"
	    set return_code [catch {
		# Bind as "Manager" and retreive the userPassword field for
		exec ldapsearch -x -H $uri -D $bind_dn -w $password -b $base_dn "$username_attribute=$username" userPassword
	    } err_msg]
	    ns_log Notice "auth::ldap::authentication::Authenticate: return_code=$return_code, msg=$err_msg"

	    if {1 == $return_code} {
		# ldapsearch didn't retrieve any result. So there is probably something wrong with
		# the BindDN or the password
		set auth_info(auth_status) "auth_error"
		set auth_info(auth_message) "LDAP error:<br>$err_msg"
		return [array get auth_info]
	    }
	    
	    # Extract the password from the "err_msg"
	    if {[regexp {userPassword:: ([a-zA-Z0-9\+\/]*)} $err_msg match ldap_password_encoded]} {

		# Successfully extacted password
		set ldap_password_encoded [string trim $ldap_password_encoded]
		ns_log Notice "auth::ldap::authentication::Authenticate: found encoded password=$ldap_password_encoded]"
		set password_ok_p [CheckOpenLDAPPassword $password $ldap_password_encoded]

		if {$password_ok_p} {

		    # Determine the user_id from username
		    set uid [db_string uid "
			select	party_id from cc_users 
			where	lower(email) = lower(:base_dn) OR lower(username) = lower(:username)
		    " -default 0]
		    set auth_info(auth_status) "ok"
		    set auth_info(user_id) $uid
		    set auth_info(auth_message) "Login Successful"
		    
#		    # Sync the user with the LDAP information, with username as primary key
#		    set auth_info_array [auth::ldap::authentication::Sync $username $parameters $authority_id]
#		    array set auth_info $auth_info_array
		    return [array get auth_info]

		} else {
		    # Wrong password
		    ns_log Notice "auth::ldap::authentication::Authenticate: Wrong password: password='$password', ldap_password='$ldap_password'"
		    set auth_info(auth_message) "Bad user or password"
		    return [array get auth_info]
		}

	    } else {

		ns_log Notice "auth::ldap::authentication::Authenticate: didn't find 'userPassword' in err_msg=$err_msg"
		set auth_info(auth_status) "auth_error"
		set auth_info(auth_message) "LDAP error:<br>Didn't find 'userPassword' in LDAP response"
		return [array get auth_info]

	    }
	 
	    # End of OpenLDAP switch {} statement
	}
    }

}


ad_proc -private auth::ldap::authentication::CheckOpenLDAPPassword {
    password_from_user
    ldap_password_encoded
} {
    Check if the OpenLDAP password has matches the user provided password_from_user.
    Currently supports CRYPT (13 and 34 digit) and MD5 hashes
    Returns 1 on a successfull match, or 0 otherwise.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::authentication::CheckOpenLDAPPassword: pwd=$password_from_user, ldap_pwd_enc=$ldap_password_encoded"
    set ldap_password [::base64::decode [string trim $ldap_password_encoded]]
    ns_log Notice "auth::ldap::authentication::CheckOpenLDAPPassword: pwd=$password_from_user, ldap_pwd=$ldap_password"

    # 1. Check for plain text passwords stored in OpenLDAP? That's an easy one...
    if {$password_from_user == $ldap_password} { return 1 }

    # 2. Check for 13 digit CRYPT digest.
    # The first two letters are the "salt".
    # Example: {CRYPT}aUihad99hmev6: "aU" is the salt
    set salt [string range $ldap_password 0 1]
    set my_digest "{CRYPT}[ns_crypt $password_from_user $salt]"
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::authentication::CheckOpenLDAPPassword: my_digest=$my_digest, ldap_pwd=$ldap_password"
    if {$my_digest == $ldap_password} { return 1 }

    # 3. Check for 34 digit MD5 hash delivered by some glibc2 systems
    # Example: {CRYPT}$1$czBJdDqS$TmkzUAb836oMxg/BmIwN.1
    set hash_from_ldap [string range $ldap_password_encoded 0 15]
    set salt_from_ldap [string range $ldap_password_encoded 16 end]
    set hash_from_user [binary format H* [md5::md5 "${password_from_user}${salt_from_ldap}"]]
    if {$hash_from_ldap == $hash_from_user} { return 1 }

    # 4. Last resort: Try running the old OpenACS auth::ldap::check_password routine
    return [auth::ldap::check_password $ldap_password_encoded password]
}





ad_proc -private auth::ldap::authentication::GetParameters {} {
    Implements the GetParameters operation of the auth_authentication 
    service contract for LDAP.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::authentication::GetParameters"

    return {
        LdapURI "URI of the host to access. Something like ldap://ldap.project-open.com:389"
        BaseDN "Base DN when searching for users. Typically something like 'dc=project-open,dc=com'"
        BindDN "How to form the user DN? Active Directory accepts emails like {username}@project-open.com"
        SystemBindDN "DN of an LDAP system user that allows PO to access the LDAP for batch synchronization. Example: 'cn=Administrator,cn=Users,dc=project-open,dc=com'. Leave empty if your LDAP allows anonymous access."
        SystemBindPW "Password for the SystemBindDN."
	ServerType "'ad' for Microsoft Active Directory of 'ol' for OpenLDAP (without the single quotes)."
        GroupMap "A TCL list represnting a map form LDAP groups to PO groups. Example: 'Users 463 Administrators 459' maps Windows 'Users' to Employees and Windows 'Administrators' to PO Admins."
	SearchFilter "An optional LDAP expression to limit the users to be imported. Example: '(memberOf=cn=PO-Users,cn=Users,dc=project-open,dc=com)' would only import users who are member of the LDAP group 'PO-Users'."
    }
}



#####
#
# On-Demand synchronization
#
#####


ad_proc -public auth::ldap::authentication::Sync {
    username 
    parameters 
    authority_id
} {
    Creates a new ]po[ user from LDAP information.
    Returns 0 if the user can't be created
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::authentication::Sync username=$username, auth=$authority_id, params='$parameters'"

    array set hash [auth::ldap::batch_import::import_users -debug_p 0 -extra_filter "(sAMAccountName=$username)" $parameters $authority_id ]

    set result $hash(result)
    set debug $hash(debug)
    ns_log Notice "auth::ldap::authentication::Sync: result=$result"

    if {1 == $result} {
	set uid [db_string uid "select user_id from users where lower(username) = :username" -default 0]
	set auth_info(auth_status) "ok"
	set auth_info(info_status) "ok"
	set auth_info(user_id) $uid
	set auth_info(auth_message) "Login Successful"
	set auth_info(account_status) "ok"
	set auth_info(account_message) ""
	return [array get auth_info]
    } else {
	set auth_info(auth_status) "sync_error"
	set auth_info(user_id) 0
	set auth_info(auth_message) "LDAP error during sync with user '$system_bind_dn':<br><pre>$debug</pre>"
	set auth_info(account_status) "ok"
	set auth_info(account_message) ""
	return [array get auth_info]
    }
}

ad_proc -public auth::ldap::authentication::Sync_disabled {
    username 
    parameters 
    authority_id
} {
    Creates a new ]po[ user from LDAP information.
    Returns 0 if the user can't be created
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::authentication::Sync username=$username, auth=$authority_id, params='$parameters'"

    # Parameters
    array set params $parameters

    # Default to failure
    set result(auth_status) auth_error

    set uri $params(LdapURI)
    set base_dn $params(BaseDN)
    set system_bind_dn $params(SystemBindDN)
    set system_bind_pw $params(SystemBindPW)
    set server_type $params(ServerType)
    set search_filter $params(SearchFilter)
    set group_map $params(GroupMap)
    # Write the group map into a Hash and normalize group names
    array set group_map_hash $group_map

    # -------------------------------------------------------------------
    # Get the LDAP user information
    set cmd "ldapsearch -x -H $uri -D $system_bind_dn -w $system_bind_pw -b $base_dn (&(objectcategory=person)(objectclass=user)(sAMAccountName=$username))"
    set return_code [catch {
        ns_log Notice "auth::ldap::authentication::Sync: cmd='$cmd'"
	eval "exec $cmd"
    } msg]

    # Extract the first line - it contains the error message if there is an issue.
    set msg_first_line ""
    if {"" == $msg_first_line} { regexp {^(.*)\n} $msg match msg_first_line }
    if {"" == $msg_first_line} { regexp {^(.*\))} $msg match msg_first_line }


    ns_log Notice "auth::ldap::authentication::Sync: return_code=$return_code, msg_first_line=$msg_first_line"
    if {0 != $return_code} {
	set auth_info(auth_status) "bad_password"
	set auth_info(user_id) 0
	set auth_info(auth_message) "LDAP error during sync with user '$system_bind_dn':<br>$msg_first_line"
	set auth_info(account_status) "ok"
	set auth_info(account_message) ""
	return [array get auth_info]
    }

    # ------------------------------------------------------------------------
    # Successfully retreived user information.
    # Now extract variables from AD output

    set email ""
    set name ""
    set first_names ""
    set last_name ""
    set manager ""
    set manager_name ""
    set disabled ""
    set department ""
    set member_groups [list]

    # Extract fields from lines
    foreach line [split $msg "\n"] {
	ns_log Notice "$line"
	if {[regexp {^mail\: (.*)} $line match value]} { set email $value }
	if {[regexp {^name\: (.*)} $line match value]} { set name $value }
	if {[regexp {^manager\: (.*)} $line match value]} { set manager $value }
	if {[regexp {^department\: (.*)} $line match value]} { set department $value }
	if {[regexp {^userAccountControl\: (.*)} $line match value]} { set disabled $value }
	if {[regexp {^memberOf\: (.*)} $line match value]} { lappend member_groups $value }
    }
    
    set name_pieces [split $name " "]
    set len [llength $name_pieces]
    set last_name [lrange $name_pieces [expr $len-1] $len]
    set first_names [lrange $name_pieces 0 [expr $len-1]]

    ns_log Notice "auth::ldap::authentication::Sync: first_name=$first_names"
    ns_log Notice "auth::ldap::authentication::Sync: last_name=$last_name"

    if {[regexp {^(.*)\ ([^\ ]*)$} $name match fn ln]} {
	set first_names $fn
	set last_name $ln
    }

    if {[regexp {^CN=(.*?)\,} $manager match mn]} { set manager_name $mn }

    if {514 == [string trim $disabled]} {
	# Windows hardcoded status "disabled"
	set member_state "banned"
    } else {
	set member_state "approved"
    }

    set manager_id [db_string manager_id "
	select	person_id
	from	persons
	where	first_names || ' ' || last_name = :manager_name
    " -default 0]

    if {"" == $first_names || "" == $last_name || "" == $email} {
	set auth_info(auth_status) "auth_error"
	set auth_info(user_id) 0
	set auth_info(auth_message) "
		User and password OK, but there were problems with the values retreived from the LDAP server.<br>
		email=$email, first_names=$first_names, last_name=$last_name"
	set auth_info(account_status) "ok"
	set auth_info(account_message) ""
	return [array get auth_info]
    } 

    ns_log Notice "auth::ldap::authentication::Sync: Synchronizing user: username=$username, email=$email, first_names=$first_names, last_name=$last_name, manager_name=$manager_name"


    # ---------------------------------------------------------------
    # Check if the user already exists

    set uid [db_string uid "select user_id from users where username=:username" -default 0]
    set url ""
    set screen_name "$first_names $last_name"

    if {0 == $uid} {

	ns_log Notice "auth::ldap::authentication::Sync: Creating a new user"
	array set creation_info [auth::create_user \
				     -username $username \
				     -email $email \
				     -first_names $first_names \
				     -last_name $last_name \
				     -screen_name $screen_name \
				     -password "" \
				     -password_confirm "" \
				     -url $url \
				     -secret_question "" \
				     -secret_answer "" \
	]
	set uid [db_string uid "select user_id from users where username=:username" -default 0]

	# Set the autority to the current LDAP
	if {0 != $uid} {
	    db_dml auth_id "update users set authority_id = :authority_id where user_id = :uid"
	}
    }

    if {0 == $uid} {
	set auth_info(auth_status) "auth_error"
	set auth_info(user_id) 0
	set auth_info(auth_message) "
		User and password OK, but there were problems to identify the user.<br>
		email=$email, first_names=$first_names, last_name=$last_name"
	set auth_info(account_status) "ok"
	set auth_info(account_message) ""
	return [array get auth_info]
    } 
   
    set user_id $uid

    # Existing user: Update variables
    set auth [auth::get_register_authority]
    set user_data [list]

    # ---------------------------------------------------------------------
    # Make sure the "person" exists.
    # This may be not the case when creating a user from a party.
    set person_exists_p [db_string person_exists "select count(*) from persons where person_id = :user_id"]
    if {!$person_exists_p} {
	db_dml insert_person "
		    insert into persons (
			person_id, first_names, last_name
		    ) values (
			:user_id, :first_names, :last_name
		    )
	"	
    }

    set user_exists_p [db_string user_exists "select count(*) from users where user_id = :user_id"]
    if {!$user_exists_p} {
	if {"" == $username} { set username $email} 
	db_dml insert_user "
		    insert into users (
			user_id, username
		    ) values (
			:user_id, :username
		    )
	"
    }

    set employee_exists_p [db_string employee_exists "select count(*) from im_employees where employee_id = :user_id"]
    if {!$employee_exists_p} {
	db_dml insert_emps "insert into im_employees (employee_id) values (:user_id)"
    }

    # Convert the person into a user
    db_dml party2user "
		    update acs_objects
		    set object_type = 'user'
		    where object_id = :user_id
    "


    # ---------------------------------------------------------------------
    ns_log Notice "/users/new: person::update -person_id=$user_id -first_names=$first_names -last_name=$last_name"
    person::update \
	-person_id $user_id \
	-first_names $first_names \
	-last_name $last_name
    
    ns_log Notice "/users/new: party::update -party_id=$user_id -url=$url -email=$email"
    party::update \
	-party_id $user_id \
	-url $url \
	-email $email
    
    ns_log Notice "/users/new: acs_user::update -user_id=$user_id -screen_name=$screen_name"
    acs_user::update \
	-user_id $user_id \
	-screen_name $screen_name \
	-username $username


    # Add to users_contact
    set users_contact_exists_p [db_string user_exists "select count(*) from users_contact where user_id = :user_id"]
    if {!$users_contact_exists_p} { 
	db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)" 
    }

    # ---------------------------------------------------------------------
    # Add the user to the "Registered Users" group, because he would get strange problems otherwise
    set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
    set reg_users_rel_exists_p [db_string member_of_reg_users "
		select	count(*) 
		from	group_member_map m, membership_rels mr
		where	m.member_id = :user_id
			and m.group_id = :registered_users
			and m.rel_id = mr.rel_id 
			and m.container_id = m.group_id 
			and m.rel_type::text = 'membership_rel'::text
    "]
    if {!$reg_users_rel_exists_p} {
	relation_add -member_state $member_state "membership_rel" $registered_users $user_id
    }

    set rel_id [db_string auth "
	select	rel_id
	from	acs_rels
	where	object_id_one = :registered_users and object_id_two = :user_id
    " -default 0]
    db_dml update_relation "update membership_rels set member_state= :member_state where rel_id=:rel_id"




    # ---------------------------------------------------------------------
    # Make the user a member of the mapped groups.
    # ToDo: Implement removing groups from a user as well.
    foreach member_group $member_groups {
	
	# Try to remove lengthy group specs.
	# Check for "CN=GroupName,..."
	if {[regexp {^CN=([^,]+),} $member_group match gname]} { 
	    ns_log Notice "auth::ldap::authentication::Sync: Reducing '$member_group' to '$gname'"
	    set member_group $gname 
	}

	ns_log Notice "auth::ldap::authentication::Sync: Checking for group: $member_group"
	if {[info exists group_map_hash($member_group)]} {
	    set gid $group_map_hash($member_group)
	    ns_log Notice "auth::ldap::authentication::Sync: Found group: $member_group: $gid"

	    # Add the user to the group.
	    ns_log Notice "auth::ldap::authentication::Sync: Adding user=$user_id to group_id=$gid"
	    set member_state "approved"
	    catch {
		im_profile::add_member -profile_id $gid -user_id $user_id
	    } err
	}	
    }

    # ---------------------------------------------------------------------
    # Set the manager if exists
    if {0 != $manager_id} {
	db_dml set_manager "update im_employees set supervisor_id = :manager_id where employee_id = :user_id"
    }

    # Department
    if {"" != [string trim $department]} {

	# Check if we find the department in the cost centers
	set department_id [db_string dept "select cost_center_id from im_cost_centers where lower(cost_center_code) = lower(:department)" -default 0]
	if {0 == $department_id} { set department_id [db_string dept "select cost_center_id from im_cost_centers where lower(cost_center_label) = lower(:department)" -default 0] }
	if {0 == $department_id} { set department_id [db_string dept "select cost_center_id from im_cost_centers where lower(cost_center_name) = lower(:department)" -default 0] }
	if {0 != $department_id} { 
	    db_dml dept "update im_employees set department_id = :department_id where employee_id = :user_id" 
	}

	# Check if we can find the "department" in one of the im_companies
	if {0 == $department_id} { 
	    set company_id [db_string dept "
		select	company_id
		from	im_companies
		where	(lower(company_path) = lower(:department)
			OR lower(company_name) = lower(:department))
	    " -default 0] 

	    if {0 != $company_id} {
		# Make the dude a full member of this company
		im_biz_object_add_role $user_id $company_id [im_biz_object_role_full_member]
	    }
	}
    }

    # ---------------------------------------------------------------------
    # TSearch2: We need to update "persons" in order to trigger the TSearch2 triggers
    db_dml update_persons "
		update persons
		set first_names = first_names
		where person_id = :user_id
    "

    set auth_info(auth_status) "ok"
    set auth_info(info_status) "ok"
    set auth_info(user_id) $uid
    set auth_info(auth_message) "Login Successful"
    set auth_info(account_status) "ok"
    set auth_info(account_message) ""
    return [array get auth_info]

}


#####
#
# Password Driver
#
#####

ad_proc -private auth::ldap::password::CanChangePassword {
    {parameters ""}
} {
    Implements the CanChangePassword operation of the auth_password 
    service contract for LDAP.
} {
    return 0
}

ad_proc -private auth::ldap::password::CanRetrievePassword {
    {parameters ""}
} {
    Implements the CanRetrievePassword operation of the auth_password 
    service contract for LDAP.
} {
    return 0
}

ad_proc -private auth::ldap::password::CanResetPassword {
    {parameters ""}
} {
    Implements the CanResetPassword operation of the auth_password 
    service contract for LDAP.
} {
    return 0
}

ad_proc -private auth::ldap::password::ChangePassword {
    username
    old_password
    new_password
    {parameters {}}
    {authority_id {}}
} {
    Implements the ChangePassword operation of the auth_password 
    service contract for LDAP.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::password::ChangePassword $username $old_password $new_password $parameters $authority_id"

    # Parameters
    array set params $parameters

    set result(password_status) change_error

    # Find the user
    set search_result [auth::ldap::get_user -username $username -parameters $parameters]

    # More than one, or not found
    if { [llength $search_result] != 1 } {
        return [array get result]
    }

    set userPassword {}
    set dn {}
    foreach { attribute value } [lindex $search_result 0] {
        switch $attribute {
            userPassword {
                set userPassword [lindex $value 0]
            }
            dn {
                set dn $value
            }
        }
    }

    if { ![empty_string_p $dn] && ![empty_string_p $userPassword] } {
        if { ![auth::ldap::check_password $userPassword $old_password] } {
            set result(password_status) old_password_bad
        } else {
            auth::ldap::set_password -dn $dn -new_password $new_password -parameters $parameters
            set result(password_status) ok
        }
    }
    
    return [array get result]
}

ad_proc -private auth::ldap::password::RetrievePassword {
    username
    parameters
} {
    Implements the RetrievePassword operation of the auth_password 
    service contract for LDAP.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::password::RetrievePassword $username $parameters"
    return { password_status not_supported }
}

ad_proc -private auth::ldap::password::ResetPassword {
    username
    parameters
    {authority_id {}}
} {
    Implements the ResetPassword operation of the auth_password 
    service contract for LDAP.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::password::ResetPassword $username $parameters $authority_id"

    # Parameters
    array set params $parameters

    set result(password_status) change_error

    # Find the user
    set dn [auth::ldap::get_user -username $username -parameters $parameters -element dn]

    if { ![empty_string_p $dn] } {
        set new_password [ad_generate_random_string]

        auth::ldap::set_password -dn $dn -new_password $new_password -parameters $parameters
        
        set result(password_status) ok
        set result(password) $new_password
    }
    
    return [array get result]
}

ad_proc -private auth::ldap::password::GetParameters {} {
    Implements the GetParameters operation of the auth_password
    service contract for LDAP.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::password::GetParameters"
    return {
        LdapURI "URI of the host to access. Something like ldap://ldap.project-open.com/"
        BaseDN "Base DN when searching for users. Typically something like 'o=Your Org Name', or 'dc=yourdomain,dc=com'"
        BindDN "How to form the user DN? Active Directory accepts emails like {username}@project-open.com"
        UsernameAttribute "LDAP attribute to match username against, typically uid"
        PasswordHash "The hash to use when storing passwords. Supported values are MD5, SMD5, SHA, SSHA, and CRYPT."
    }
}



#####
#
# Registration Driver
#
#####

ad_proc -private auth::ldap::registration::GetElements {
    {parameters ""}
} {
    Implements the GetElements operation of the auth_registration
    service contract.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::registration::GetElements $parameters"

    set result(required) { username email first_names last_name }
    set result(optional) { password }

    return [array get result]
}

ad_proc -private auth::ldap::registration::Register {
    parameters
    username
    authority_id
    first_names
    last_name
    screen_name
    email
    url
    password
    secret_question
    secret_answer
} {
    Implements the Register operation of the auth_registration
    service contract.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::registration::Register $parameters $username $authority_id $first_names $last_name $screen_name $email $url $password $secret_question $secret_answer"

    # Parameters
    array set params $parameters

    array set result {
        creation_status "reg_error"
        creation_message {}
        element_messages {}
        account_status "ok"
        account_message {}
    }

    set dn $params(DNPattern)
    foreach var { username first_names last_name email screen_name url } {
        regsub -all "{$var}" $dn [set $var] dn
    }
    append dn ",$params(BaseDN)"

    set attributes [list]
    foreach elm [split $params(Attributes) ";"] {
        set elmv [split $elm "="]
        set attribute [string trim [lindex $elmv 0]]
        set value [string trim [lindex $elmv 1]]

        foreach var { username first_names last_name email screen_name url } {
            regsub -all "{$var}" $value [set $var] value
        }
        # Note that this makes a list out of 'value' if it isn't already
        lappend attributes $attribute $value
    }

    # Create the account
    set lh [ns_ldap gethandle ldap]
    with_catch errmsg {
        ns_log Notice "LDAP: Adding user: [concat ns_ldap add [list $lh] [list $dn] $attributes]"
        eval [concat ns_ldap add [list $lh] [list $dn] $attributes]
        ns_ldap releasehandle $lh
    } {
        ns_ldap releasehandle $lh
        global errorInfo
        error $errmsg $errorInfo
    }

    auth::ldap::set_password -dn $dn -new_password $password -parameters $parameters
    
    set result(creation_status) "ok"

    return [array get result]
}

ad_proc -private auth::ldap::registration::GetParameters {} {
    Implements the GetParameters operation of the auth_registration
    service contract.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::registration::GetParameters"
    return {
        LdapURI "URI of the host to access. Something like ldap://ldap.project-open.com/"
        BaseDN "Base DN when searching for users. Typically something like 'o=Your Org Name', or 'dc=yourdomain,dc=com'"
        BindDN "How to form the user DN? Active Directory accepts emails like {username}@project-open.com"
        UsernameAttribute "LDAP attribute to match username against, typically uid"
        PasswordHash "The hash to use when storing passwords. Supported values are MD5, SMD5, SHA, SSHA, and CRYPT."
        DNPattern "Pattern for contructing the first part of the DN for new accounts. Will automatically get ',BaseDN' appended. {username}, {first_names}, {last_name}, {email}, {screen_name}, {url} will be expanded with their respective values. Example: 'uid={username}'."
        Attributes "Attributes to assign in the new LDAP entry. The value should be a semicolon-separated list of the form 'attribute=value; attribute=value; ...'. {username}, {first_names}, {last_name}, {email}, {screen_name}, {url} will be expanded with their respective values. Example: 'objectClass=person organizationalPerson inetOrgPerson;uid={username};cn={{first_names} {last_name}};sn={last_name};givenName={first_names};mail={email}'."
    }
}



#####
#
# On-Demand Sync Driver
#
#####

ad_proc -private auth::ldap::user_info::GetUserInfo {
    username
    parameters
} {
    Returns basic information per user
    info_status - string
    info_message - string
    user_info - string []
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::user_info::GetUserInfo $username $parameters"

    # Parameters
    array set params $parameters

    # Default result
    array set result {
        info_status "ok"
        info_message {}
        user_info {}
    }

    set search_result [auth::ldap::get_user \
                           -username $username \
                           -parameters $parameters]

    # More than one, or not found
    if { [llength $search_result] != 1 } {
        set result(info_status) no_account
        return [array get result]
    }

    # Set up mapping data structure
    array set map [list]
    foreach elm [split $params(InfoAttributeMap) ";"] {
        set elmv [split $elm "="]
        set oacs_elm [string trim [lindex $elmv 0]]
        set ldap_attr [string trim [lindex $elmv 1]]

        lappend map($ldap_attr) $oacs_elm
    }
    
    # Map LDAP attributes to OpenACS elements
    array set user [list]
    foreach { attribute value } [lindex $search_result 0] {
        if { [info exists map($attribute)] } {
            foreach oacs_elm $map($attribute) {
                if { [lsearch { username authority_id } $oacs_elm] == -1 } { 
                    set user($oacs_elm) [lindex $value 0]
                }
            }
        }
    }
    
    set result(user_info) [array get user]
    
    return [array get result]
}


ad_proc -private auth::ldap::user_info::GetParameters {} {
    Delete service contract for account registration.
} {
    ns_log Notice "auth-ldap-adldapsearch: auth::ldap::user_info::GetParameters"

    return {
        LdapURI "URI of the host to access. Something like ldap://ldap.project-open.com/"
        BaseDN "Base DN when searching for users. Typically something like 'o=Your Org Name', or 'dc=yourdomain,dc=com'"
        BindDN "How to form the user DN? Active Directory accepts emails like {username}@project-open.com"
        UsernameAttribute "LDAP attribute to match username against, typically uid"
        InfoAttributeMap "Mapping attributes from the LDAP entry to OpenACS user information in the format 'element=attrkbute;element=attribute'. Example: first_names=givenName;last_name=sn;email=mail"
    }
}

