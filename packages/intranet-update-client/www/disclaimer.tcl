# /packages/intranet-update-client/www/disclaimer.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Main page of the software update service

    @author frank.bergmann@project-open.com
} {

}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Automatic Software Update Service"
set context_bar [im_context_bar $page_title]

set po "<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>"



