# /intranet/intranet-hr/www/upload-vacationdata.tcl
#
# Copyright (C) 2013 ]project-open[
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
    Serve the user a form to upload a new file or URL

    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Vacation Data CSV"
# set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]
set context_bar ""

# Check if user is ADMIN or HR Manager
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p && ![im_profile::member_p -profile_id [im_hr_group_id] -user_id $user_id]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_body "
<form enctype=multipart/form-data method=POST action=upload-vacationdata-2.tcl>
[export_form_vars return_url]
                    <table border=0>
                      <tr> 
                        <td align=right>Filename: </td>
                        <td> 
                          <input type=file name=upload_file size=30>
                          [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."]
                        </td>
                      </tr>
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=Submit and Upload>
                        </td>
                      </tr>
                    </table>
</form>
"

