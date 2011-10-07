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
    { source_language "" }
    { target_languages "" }
    { upload_file "" }
    { delivery_date "" }
    { project_id "" }
    { inquiry_id "" }
    { security_token "" }
}


# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

if { ![info exists security_token] } {
    set user_id [ad_maybe_redirect_for_registration]
} 

set temp_path [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "TempPath" -default "/tmp"]
set page_title ""
set context_bar ""

# -------------------------------------------------------------------
# Get the file
# -------------------------------------------------------------------

set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-files-form-action.tcl" -value $tmp_filename
set filesize [file size $tmp_filename]

if { $max_n_bytes && ($filesize > $max_n_bytes) } {
    # set util_commify_number_max_n_bytes [util_commify_number $max_n_bytes]
    # ad_return_complaint 1 "[_ intranet-translation.lt_Your_file_is_larger_t_1]"
    # ad_script_abort
    ns_return 406 text/html "\{\"success\":false\}"
}

if { [db_string get_view_id "select count (*) from im_inquiries_files where file_name='$upload_file' and inquiry_id = :inquiry_id" -default 0] } {
    ns_log NOTICE "KHD: File already exists"
    ns_return 406 text/html "\{\"success\":false\}"
    ad_script_abort
}


# -------------------------------------------------------------------
# Copy the uploaded file into the template filestorage
# -------------------------------------------------------------------

ns_log NOTICE "KHD: Now copying file: $temp_path/$security_token/$upload_file"

if { [catch {
    ns_cp $tmp_filename "$temp_path/$security_token/$upload_file"
} err_msg] } {
    ns_return 406 text/html "\{\"success\":false\}"
}

# -------------------------------------------------------------------
# Write inquiry to db 
# -------------------------------------------------------------------

set inquiry_files_id [db_string nextval "select nextval('im_inquiries_files_seq');"]

db_dml insert_inq "
        insert into im_inquiries_files
                (inquiry_files_id, inquiry_id, file_name, source_language, target_languages, deliver_date, project_id, file_path)
        values
                ($inquiry_files_id, $inquiry_id, '$upload_file', :source_language, :target_languages, :delivery_date, :project_id, '$temp_path/$security_token/')
"

# -------------------------------------------------------------------
# Return
# -------------------------------------------------------------------

ns_return 200 text/html "\{\"success\":true\}"
