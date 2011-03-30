# /packages/intranet-cust-koernigweber/www/notify-logged-hours.tcl
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

ad_page_contract {
    Purpose: Confirms adding of person to group


    @param project_id 
    @param user_id 
    @param report_year_month
    @param return_url Return URL

    @author mbryzek@arsdigita.com    
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    project_id:integer
    user_id:integer
    report_year_month
    { return_url "" }
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_name [db_string cur_user "select im_name_from_user_id(:current_user_id) from dual"]

# set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
# eval $perm_cmd

# --------------------------------------------------------
# Prepare to send out an email alert
# --------------------------------------------------------

set system_name [ad_system_name]
set page_title "Notify user"
set context [list $page_title]

set export_vars [export_form_vars return_url user_id]

# Get the SystemUrl without trailing "/"
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set sysurl_len [string length $system_url]
set last_char [string range $system_url [expr $sysurl_len-1] $sysurl_len]
if {[string equal "/" $last_char]} {
    set system_url "[string range $system_url 0 [expr $sysurl_len-2]]"
}

# set object_url< "$system_url$object_rel_url$object_id"

set name_recipient [im_name_from_user_id $user_id]

# Show a textarea to edit the alert at member-add-2.tcl
ad_return_template

