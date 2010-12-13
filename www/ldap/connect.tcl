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

set page_title "Test LDAP Connection"

set bg "/intranet/images/girlongrass.600x400.jpg"
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"
set po_short "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"


# ---------------------------------------------------------------
# Connect to LDAP server
# ---------------------------------------------------------------

ns_log Notice "connect: before ns_sockopen"
set fds [ns_sockopen -timeout 3 192.168.21.128 389]
ns_log Notice "connect: after ns_sockopen"

set rid [lindex $fds 0]
set wid [lindex $fds 1]
puts $wid "GET /index.htm HTTP/1.0\r\n\r"
flush $wid
while {[set line [string trim [gets $rid]]] != ""} {
    lappend headers $line
}
set page [read $rid]
close $rid
close $wid