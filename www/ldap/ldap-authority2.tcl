#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Adds a new authority
} {
    { ip_address "" }
    { port "" }
    { ldap_type "" }
    { domain "" }
    { binddn "" }
    { bindpw "" }
    { authority_name "" }
    { authority_id "" }
    { group_map "" }
}

# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title "Authority Configured"

set bg "/intranet/images/girlongrass.600x400.jpg"
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"


# ---------------------------------------------------------------
# Add the new authority
# ---------------------------------------------------------------

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
# ---------------------------------------------------------------

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


# Which LDAP attributes holds the "username" of ]po[?
switch $ldap_type {
    ad { set username_attribute "sAMAccountName" }
    default { set username_attribute "uid" }
}


set param_hash(Attributes) ""
set param_hash(BaseDN) $domain
set param_hash(BindDN) $binddn
set param_hash(BindPW) $bindpw
set param_hash(DNPattern) ""
set param_hash(InfoAttributeMap) ""
set param_hash(LdapURI) "ldap://$ip_address:$port"
set param_hash(PasswordHash) ""
set param_hash(ServerType) $ldap_type
set param_hash(UsernameAttribute) $username_attribute

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


# ---------------------------------------------------------------
# Set System parameters in order to enable 3-field login
# ---------------------------------------------------------------

# Disable the use of Email for login - so the system will use Username now.
parameter::set_value \
    -package_id [ad_acs_kernel_id] \
    -parameter "UseEmailForLoginP" \
    -value 0

# Show the Username in the user view/edit screen
parameter::set_value \
    -package_id [im_package_core_id] \
    -parameter "EnableUsersUsernameP" \
    -value 1

# Show the authority field in the user view/edit screen
parameter::set_value \
    -package_id [im_package_core_id] \
    -parameter "EnableUsersAuthorityP" \
    -value 1

