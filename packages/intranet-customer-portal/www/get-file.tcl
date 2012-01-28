# /packages/intranet-customer-portal/www/customer-registration-form-action.tcl
#
# Copyright (C) 2011 ]project-open[
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
    { file_id "" }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

#ToDo: Only PM should get access  

set user_id [ad_maybe_redirect_for_registration]

# User should be at least PM to review file, additional permission check might added
# if { ![im_profile::member_p -profile_id [im_pm_group_id] -user_id $user_id] } {
#    ad_return_complaint 1 "You must be a PM to view files" 
# }

if {![im_permission $user_id "view_projects_all"]} {
    ad_return_complaint 1 "<b>You do not have permissions to access this page</b>"
}

set sql "
	select 
		fi.file_path,
		fi.file_name 
	from 
		im_inquiries_customer_portal cp, 
		im_inquiries_files fi
	 where 
		cp.inquiry_id in (
			select inquiry_id from im_inquiries_files where inquiry_files_id=:file_id
		)
" 

db_1row get_file_info $sql


# -------------------------------------------------------------------
# Return file 
# -------------------------------------------------------------------

set file_name "$file_path/$file_name"

if {[catch {
     ns_returnfile 200 "application" $file_name 
} err_msg]} {
    ad_return_complaint 1 "
       <b>Error receiving file</b>"
}

