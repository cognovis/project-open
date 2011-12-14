# /packages/intranet-customer-portal/www/index.tcl
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

}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set page_title "Project Wizard"
set show_navbar_p 0
set show_left_navbar_p 0

# Load Sencha libs 
template::head::add_css -href "/intranet-sencha/resources/css/ext-all.css" -media "screen" -order 1
template::head::add_javascript -src "/intranet-sencha/resources/js/ext-all.js" -order 1

# CSS Adjustemnts to ExtJS 
template::head::add_css -href "/intranet-customer-portal/intranet-customer-portal.css" -media "screen" -order 10

# ---------------------------------------------------------------
# Set OpenACS login form
# ---------------------------------------------------------------

# set subsite_id [ad_conn subsite_id]
#  set login_template [parameter::get -parameter "LoginTemplate" -package_id $subsite_id]

set authority_id "" 
set username "" 
set email ""

set login_template "/packages/acs-subsite/lib/login"
set return_url "/intranet-customer-portal/upload-files"

# ---------------------------------------------------------------
# Add customer registration
# ---------------------------------------------------------------

if {[im_openacs54_p]} {
    template::head::add_javascript -src "/intranet-customer-portal/resources/js/customer-registration-form.js" -order 2
}
