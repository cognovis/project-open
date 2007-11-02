# /packages/intranet-freelance-invoices/www/project-select.tcl
#
# Copyright (C) 2003-2005 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Allows the user to select a project and returns to return_url
    with &project_id=$project_id appended

    @author frank.bergmann@project-open.com
} {
    return_url
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

set page_title "[_ intranet-invoices.Select_Customer]"
set context_bar [im_context_bar [list /intranet/invoices/ "[_ intranet-invoices.Finance]"] $page_title]


# ---------------------------------------------------------------
#
# ---------------------------------------------------------------


set customer_select [im_company_select company_id 0 "" "Customer"]
set provider_select [im_company_select company_id 0 "" "Provider"]

set sub_navbar [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list]] 


db_release_unused_handles
