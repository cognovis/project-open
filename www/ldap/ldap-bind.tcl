#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Connect to the LDAP server and check if the port is open
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

set default_binddn_ad "cn=Administrator,cn=Users,$domain"
set default_binddn_ol "cn=Manager,$domain"

if {"" == $system_binddn} {
    switch $ldap_type {
	ad { set system_binddn $default_binddn_ad }
	ol { set system_binddn $default_binddn_ol }
    }
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

set page_title "Select LDAP Server Type"

set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"


# ---------------------------------------------------------------
# Try to "bind" (=authenticate) to LDAP server
# ---------------------------------------------------------------

array set hash [im_sysconfig_ldap_check_bind \
		    -ldap_ip_address $ip_address \
		    -ldap_port $port \
		    -ldap_type $ldap_type \
		    -ldap_domain $domain \
		    -ldap_binddn $binddn \
		    -ldap_bindpw $bindpw \
		    -ldap_system_binddn $system_binddn \
		    -ldap_system_bindpw $system_bindpw]

set success_p $hash(success_p)
set debug $hash(debug)



# ---------------------------------------------------------------
# Select enabled Prev - Test - Next buttons
# ---------------------------------------------------------------

set enable_prev_p 1
set enable_test_p 1
set enable_next_p $success_p

