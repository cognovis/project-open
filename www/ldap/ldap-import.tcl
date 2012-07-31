#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Provides a form for additional authority fields.
    We can run this script only AFTER the authority has been configured,
    because we need driver procs to actually access the authority data.
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
    group:array,optional
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

set page_title "Import LDAP Users"

set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"


# ---------------------------------------------------------------
# Update the group_map
# ---------------------------------------------------------------

# Take the default group mapping as a starting point for the mapping
array set group_map_hash $group_map

# Store each of the specified mappings in the group_map_hash
set group_map_groups [array names group]
foreach group_name $group_map_groups {
    set group_id $group($group_name)
    if {"" != $group_id} {
	set group_map_hash($group_name) $group_id
    }
}
set group_map [array get group_map_hash]

# ----------------------------------------------------------------
# Store the group_map in the Authority's parameters
#
set param_hash(GroupMap) $group_map

set auth_id [im_sysconfig_create_edit_authority \
		 -authority_name $authority_name \
		 -parameters [array get param_hash] \
		]


# ---------------------------------------------------------------
# Import stuff
# ---------------------------------------------------------------

array set params {}
set params(LdapURI) "ldap://$ip_address:$port"
set params(BaseDN) $domain
set params(BindDN) $binddn
set params(SystemBindDN) $system_binddn
set params(SystemBindPW) $system_bindpw
set params(ServerType) $ldap_type
set params(GroupMap) $group_map

array set result_hash [auth::ldap::batch_import::import_users [array get params] $authority_id]
set result $result_hash(result)
set debug $result_hash(debug)

array set result_hash [auth::ldap::batch_import::import_groups [array get params] $authority_id]
set result $result_hash(result)
append debug $result_hash(debug)





