# /packages/intranet-sysconfig/www/ldap/ldap-group-map.tcl
#
# Copyright (c) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    
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


switch $ldap_type {
    ad {
	# Set a simple mapping of Active Directory groups to 
	# ]po[ groups
	set default_group_map [list \
				   Administrators [im_admin_group_id] \
				   Users [im_employee_group_id] \
				   Guests [im_freelance_group_id] \
				   ]
    }
    default {
	set default_group_map [list \
				   dell [im_employee_group_id] \
				   ]
    }
}

if {"" == $group_map} { set group_map $default_group_map }

# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title [lang::message::lookup "" intranet-sysconfig.Map_LDAP_Groups_to_PO "Map LDAP Groups to \]po\["]
set context_bar [im_context_bar $page_title]

set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"


# ---------------------------------------------------------------
# Get the list of LDAP groups
# ---------------------------------------------------------------

array set params {}
set params(LdapURI) "ldap://$ip_address:$port"
set params(BaseDN) $domain
set params(BindDN) $binddn
set params(SystemBindDN) $system_binddn
set params(SystemBindPW) $system_bindpw
set params(ServerType) $ldap_type

array set result_hash [auth::ldap::batch_import::read_ldif_groups [array get params] $authority_id]
set result $result_hash(result)
set debug $result_hash(debug)
array set groups_hash $result_hash(objects)

# Get the list of LDAP groups
set ldap_group_names [array names groups_hash]

# Define the list of ]po[ "profiles" (=high-level user groups)
set profile_options [im_profile::profile_options_all -translate_p 0]    
set profile_options [linsert $profile_options 0 [list "-- Don't map --" ""]]

set groups_select_html ""
array set group_map_hash $group_map
foreach ldap_group_name [lsort $ldap_group_names] {

    # Check the group mapping if we have a default group
    set default_group ""
    if {[info exists group_map_hash($ldap_group_name)]} { set default_group $group_map_hash($ldap_group_name) }
    append groups_select_html "
	<tr>
	<td>$ldap_group_name</td>
	<td>[im_select -ad_form_option_list_style_p 1 -translate_p 0 group.$ldap_group_name $profile_options $default_group]</td>
	</tr>
    "

}
