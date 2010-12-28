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
set connect_perl "[acs_root_dir]/packages/intranet-sysconfig/perl/connect.perl"
set cmd "perl $connect_perl"
set fp [open "|[im_bash_command] -c \"$cmd\"" "r"]


set perl_lines ""
while {[gets $fp line] >= 0} {
    append perl_lines $line
    append perl_lines "<br>\n"
}
close $fp

