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
    { system_binddn "" }
    { system_bindpw "" }
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

set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"


# ---------------------------------------------------------------
# Add/Update the new authority
# ---------------------------------------------------------------

set param_hash(Attributes) ""
set param_hash(BaseDN) $domain
set param_hash(BindDN) $binddn
set param_hash(SystemBindDN) $system_binddn
set param_hash(SystemBindPW) $system_bindpw
set param_hash(DNPattern) ""
set param_hash(InfoAttributeMap) ""
set param_hash(LdapURI) "ldap://$ip_address:$port"
set param_hash(PasswordHash) ""
set param_hash(ServerType) $ldap_type
set param_hash(GroupMap) $group_map

#ad_return_complaint 1 "im_sysconfig_create_edit_authority -authority_name $authority_name -parameters [array get param_hash]"

array set result_hash [im_sysconfig_create_edit_authority \
		 -authority_name $authority_name \
		 -parameters [array get param_hash] \
		]

set auth_id $result_hash(auth_id)
set create_p $result_hash(create_p)

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

