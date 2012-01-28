# /packages/intranet-customer-portal/www/complete_inquiry.tcl
#
# Copyright (C) 2011 ]project-open[
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

ad_page_contract {
    @param 
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    {security_token ""}
    {inquiry_id ""}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set page_title "Project Wizard"
set show_navbar_p 0
set show_left_navbar_p 0
set anonymous_p 1

if { "" != $security_token } {
    # set inquiry_id [db_string inq_id "select inquiry_id from im_inquiries_customer_portal where security_token = :security_token" -default 0]
    if { $inquiry_id == 0} {
	ad_return_complaint 1 "You have to register first in order to upload files. Please refer to our <a href='/intranet-customer-portal/'>Customer Portal</a>"
    }
    set master_file "../../intranet-customer-portal/www/master"
} else {
    set user_id [ad_maybe_redirect_for_registration]
    set anonymous_p 0
    set master_file "../../intranet-core/www/master"
}

# Load Sencha libs 
if {[im_openacs54_p]} {
    template::head::add_css -href "/intranet-sencha/resources/css/ext-all.css" -media "screen" -order "1"
    template::head::add_javascript -src "/intranet-sencha/ext-all.js" -order "1"
}

# ---------------------------------------------------------------
# Set HTML elements
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Add customer registration
# ---------------------------------------------------------------

# template::head::add_javascript -src "/intranet-customer-portal/resources/js/upload-files-form.js?inquiry_id=$inquiry_id" -order "2"

