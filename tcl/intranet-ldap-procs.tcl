# /packages/intranet-sysconfig/tcl/intranet-ldap-procs.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    SysConfig LDAP Wizard Library
    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------
# Connect to LDAP server
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_ldap_check_port_open { 
    -ldap_ip_address:required
    -ldap_port:required
} {
    Returns a list of key-value pairs suitable for an "array set" operation.
    The key "open" contains "1" if the port @ ip is open of "0" otherwise.
    The key "debug" contains additional text lines from the Perl script
    suitable to be displayed using a "pre" HTML tag.
} {
    array set hash {}
    
    set port_open_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/ldap-check-port.perl"
    set cmd "perl $port_open_perl $ldap_ip_address $ldap_port"
    ns_log Notice "im_sysconfig_ldap_check_port_open: $cmd"

    set debug ""
    if {[catch {
	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	set debug ""
	while {[gets $fp line] >= 0} {
	    append debug "$line\n"
	}
	close $fp
    } err_msg]} {
	set open_p 0
	append debug $err_msg
    } else {
	set open_p 1
    }

    set hash(open_p) $open_p
    set hash(debug) $debug

    return [array get hash]
}



# ---------------------------------------------------------------
# Connect to LDAP server
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_ldap_check_bind { 
    -ldap_ip_address:required
    -ldap_port:required
    -ldap_type:required
    -ldap_domain:required
    -ldap_binddn:required
    { -ldap_bindpw "" }
    -ldap_system_binddn:required
    -ldap_system_bindpw:required
} {
    Tries to bind to the LDAP server using the selected system_binddn/system_bindpw (username/password).
    Returns a list of key-value pairs suitable for an "array set" operation.
    The key "success" contains "1" if the bind was successfull and "0" otherwise.
    The key "debug" contains additional text lines from the Perl script
    suitable to be displayed using a "pre" HTML tag.
} {
    array set hash {}
    
    set bind_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/ldap-check-bind.perl"
    set cmd "perl $bind_perl $ldap_ip_address $ldap_port $ldap_type $ldap_domain $ldap_system_binddn $ldap_system_bindpw"
    ns_log Notice "im_sysconfig_ldap_check_bind: $cmd"

    set debug ""
    if {[catch {
	set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]
	set debug ""
	while {[gets $fp line] >= 0} {
	    append debug "$line\n"
	}
	close $fp
    } err_msg]} {
	# We get here after the Perl script performs an "exit 1"
	set success_p 0
	append debug $err_msg
    } else {
	set success_p 1
    }

    set hash(success_p) $success_p
    set hash(debug) $debug

    return [array get hash]
}



# ---------------------------------------------------------------
# Get information about LDAP objects
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_ldap_get_info { 
    -ldap_ip_address:required
    -ldap_port:required
} {
    Returns a list of key-value pairs suitable for an "array set" operation.
    The key "result" contains "1" for a successful LDAP connect or "0" for a 
    failed one.
} {
    array set hash {}
    
    set connect_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/connect.perl"
    set cmd "perl $connect_perl"
    set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]

    set debug ""
    while {[gets $fp line] >= 0} {
	append debug $line
	append debug "<br>\n"
    }
    close $fp

    set hash(result) 1
    set hash(debug) $debug

    return [array get hash]
}




# ---------------------------------------------------------------
# Create/Update an Authority
# ---------------------------------------------------------------

ad_proc -public im_sysconfig_create_edit_authority {
    -authority_name:required
    -parameters:required
} {
    Creates or updates an authority with the specified variables and parameters.
} {
    array set param_hash $parameters

    # Basic Information
    set auth_hash(pretty_name) $authority_name
    set auth_hash(short_name) ""
    set auth_hash(enabled_p) "t"
    
    # Implementation of authentication Service Contracts
    set auth_impl_id [acs_sc::impl::get_id -owner "auth-ldap-adldapsearch" -name "LDAP" -contract "auth_authentication"]
    set pwd_impl_id  [acs_sc::impl::get_id -owner "auth-ldap-adldapsearch" -name "LDAP" -contract "auth_password"]
    # set register_impl_id  [acs_sc::impl::get_id -owner "auth-ldap-adldapsearch" -name "LDAP" -contract "auth_registration"]
    # set user_info_impl_id  [acs_sc::impl::get_id -owner "auth-ldap-adldapsearch" -name "LDAP" -contract "auth_user_info"]
    # set get_doc_impl_id  [acs_sc::impl::get_id -owner "auth-ldap-adldapsearch" -name "LDAP" -contract "auth_sync_retreive"]
    # set process_doc_impl_id  [acs_sc::impl::get_id -owner "auth-ldap-adldapsearch" -name "LDAP" -contract "auth_sync_process"]
    
    set register_impl_id ""
    set user_info_impl_id ""
    set get_doc_impl_id ""
    set process_doc_impl_id ""
    set search_impl_id ""
    
    set auth_hash(auth_impl_id) $auth_impl_id
    set auth_hash(pwd_impl_id) $pwd_impl_id
    set auth_hash(register_impl_id) $register_impl_id
    set auth_hash(user_info_impl_id) $user_info_impl_id
    set auth_hash(get_doc_impl_id) $get_doc_impl_id
    set auth_hash(process_doc_impl_id) $process_doc_impl_id
    set auth_hash(search_impl_id) $search_impl_id
   
    # Update or create the authority
    set authority_id [db_string authority_exists "
	select	min(authority_id)
	from	auth_authorities
	where	pretty_name = :authority_name
    " -default 0]
    if {"" == $authority_id} { set authority_id 0 }


    if {0 != $authority_id} {
	# Authority already exists with this name
	auth::authority::edit -authority_id $authority_id -array auth_hash
	set create_p 0
    } else {
	# Create a new authority
	set authority_id [db_nextval "acs_object_id_seq"]
	set auth_hash(authority_id) $authority_id
	auth::authority::create -authority_id $authority_id -array auth_hash
	set create_p 1
    }


    # ---------------------------------------------------------------
    # Set parameter for the new Authority
    # Each element is a list of impl_ids which have this parameter
    array set param_impls [list]
    foreach element_name [auth::authority::get_sc_impl_columns] {
	set name_column $element_name
	regsub {^.*(_id)$} $element_name {_name} name_column
	set impl_params [auth::driver::get_parameters -impl_id $auth_hash($element_name)]
	foreach { param_name dummy } $impl_params {
	    lappend param_impls($param_name) $auth_hash($element_name)
	}
    }

    # ---------------------------------------------------------------
    # Calculate the user BindDN
    # The user will authentication in Active Directory with {username}@<domain>.
    #
    if {[info exists param_hash(BaseDN)]} {
	set base_dn [string tolower $param_hash(BaseDN)]
	set domain_pieces [split $base_dn ","]
	set domain_list {}
	foreach d $domain_pieces {
	    if {[regexp {dc=(.+)} $d match piece]} {
		lappend domain_list $piece
	    }
	}
	set domain [join $domain_list "."]
	set param_hash(BindDN) "{username}@$domain"
    }

    # Store the parameter values into the various "implementations"
    # for authority parameters. No idea why this is like this, I
    # just copied the code from acs-authentication...
    #
    foreach element_name [array names param_hash] {
	
	# Make sure we have a parameter element
	if {![info exists param_impls($element_name)] } { continue }
	
	foreach impl_id $param_impls($element_name) {
	    auth::driver::set_parameter_value \
		-authority_id $authority_id \
		-impl_id $impl_id \
		-parameter $element_name \
		-value $param_hash($element_name)
	}
    }
    return [list result 1 auth_id $authority_id create_p $create_p]
}