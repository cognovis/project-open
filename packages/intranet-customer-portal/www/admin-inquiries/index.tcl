# /packages/intranet-customer-portal/www/admin-inquiries/index.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {

}

set current_user_id [ad_maybe_redirect_for_registration]

if {![im_permission $current_user_id "view_projects_all"]} {
    ad_return_complaint 1 "<b>You do not have permissions to access this page</b>"
}

set page_title ""

# Load Sencha libs
template::head::add_css -href "/intranet-sencha/resources/css/ext-all.css" -media "screen" -order "1"

# Load SuperSelectBox
template::head::add_javascript -src "/intranet-sencha/ext-all.js" -order 1

# ---------------------------------------------------------------
# Set HTML elements
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Add customer registration
# ---------------------------------------------------------------

template::head::add_javascript -src "/intranet-customer-portal/resources/js/index-admin-inquiries.js" -order "2"
