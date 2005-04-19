# /packages/intranet-update-client/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Main page of the software update service

    @author frank.bergmann@project-open.com
    @creation-date Apr 2005
} {

}

set user_id [auth::require_login]
set return_url "[ad_conn url]?[ad_conn query]"
set page_title "Automatic Software Updates"
set context_bar [im_context_bar $page_title]

