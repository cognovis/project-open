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

# Remove the "dc=" pieces from the domain
regsub -all -nocase {dc\=} $domain "" default_authority_name
# Replace "," with "."
regsub -all -nocase {,} $default_authority_name "." default_authority_name

switch $ldap_type {
    ad { append default_authority_name " (Active Directory)" }
    ol { append default_authority_name " (OpenLDAP)" }
    default { set default_authority_name "Invalid Authority Type" }
}

# ad_return_complaint 1 "$ldap_type, $default_authority_name"


set authority_name $default_authority_name

# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title "Authority Properties"

set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"

