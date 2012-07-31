# /packages/intranet-sysconfig/www/sector/index.tcl
#
# Copyright (c) 2003-2006 ]project-open[
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


set default_ip_address ""
set default_port 389

if {"" == $ip_address} { set ip_address $default_ip_address }
if {"" == $port} { set port $default_port }

# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title "[lang::message::lookup "" intranet-sysconfig.LDAP_Wizard "LDAP Wizard"]"
set context_bar [im_context_bar $page_title]


set bg ""
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"



# ---------------------------------------------------------------
# Control the display for prev - test - next buttons
# ---------------------------------------------------------------

set enable_next_p 1
set enable_prev_p 1
set enable_test_p 0



