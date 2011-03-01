# /packages/intranet-helpdesk/www/admin/index.tcl
#
# Copyright (c) 1998-2008 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@ticket-open.com
} {

}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Admin_Helpdesk "Helpdesk Administration"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

