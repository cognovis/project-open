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

}


# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

set page_title "[lang::message::lookup "" intranet-sysconfig.System_Configuration_Wizard "System Configuration Wizard"]"
set context_bar [im_context_bar $page_title]


set bg "/intranet/images/girlongrass.600x400.jpg"
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"


