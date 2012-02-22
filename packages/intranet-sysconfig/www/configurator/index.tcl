# /packages/intranet-sysconfig/www/configurator/index.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved

ad_page_contract {
    Process Configurator
    @author frank.bergmann@project-open.com
} {
    
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}
set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}


set page_title "[lang::message::lookup "" intranet-sysconfig.Process_Configurator "Process Configurator"]"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"
