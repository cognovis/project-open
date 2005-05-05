# /packages/intranet-filestorage/www/upload-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    insert a file into the file system

    @author frank.bergmann@project-open.com
} {
    folder_type
    bread_crum_path
    object_id:integer
    return_url
    upload_file
    {file_title:trim ""}
    {description ""}
} 


set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set page_title "Upload into '$bread_crum_path'"
set today [db_string today "select to_char(sysdate,'YYYY-MM-DD') from dual"]

set context_bar [im_context_bar [list "/intranet/projects/" "Projects"]  [list "/intranet/projects/view?group_id=$object_id" "One Project"]  "Upload File"]


# --------------- Get the users permissions on the underlying object ----

# Gets object permissions using commands like: "im_project_permissions" ...
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id" -default ""]

set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"

eval $perm_cmd


# -------------------- Check the user input first ----------------------------
#
set exception_text ""
set exception_count 0
if {!$object_read} {
    append exception_text "<li>You have insufficient privileges to upload this file.\n"
    incr exception_count
}
if {"" == $folder_type} {
    append exception_text "<LI>Internal Error: folder_type not specified"
    incr exception_count
}
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}


# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
ns_log Notice "upload-2: tmp_filename=$tmp_filename"

if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return 0
}

set file_extension [string tolower [file extension $upload_file]]
# remove the first . from the file extension
regsub "\." $file_extension "" file_extension
set guessed_file_type [ns_guesstype $upload_file]
set n_bytes [file size $tmp_filename]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

if {[regexp {\.\.} $client_filename]} {
    set error "<li>Path contains forbidden characters<br>
    Please don't use '.' characters."
    ad_return_complaint "User Error" $error
}

# ---------- Determine the location where to save the file -----------


set base_path [im_filestorage_base_path $folder_type $object_id]
if {"" == $base_path} {
    ad_return_complaint 1 "<LI>Unknown folder type \"$folder_type\"."
    return
}
set dest_path "$base_path/$bread_crum_path/$client_filename"


# --------------- Let's copy the file into the FS --------------------

ns_log Notice "dest_path=$dest_path"

if { [catch {
    ns_log Notice "/bin/mv $tmp_filename $dest_path"
    exec /bin/cp $tmp_filename $dest_path
    ns_log Notice "/bin/chmod ug+w $dest_path"
    exec /bin/chmod ug+w $dest_path
} err_msg] } {
    # Probably some permission errors
    ad_return_complaint  "Error writing upload file"  $err_msg
    return
}


# --------------- Log the interaction --------------------

db_dml insert_action "
insert into im_fs_actions (
        action_type_id,
        user_id,
        action_date,
        file_name
) values (
        [im_file_action_upload],
        :user_id,
        :today,
        '$dest_path/$client_filename'
)"



set page_content "
<H2>Upload Successful</H2>

You have successfully uploaded $n_bytes bytes of '$client_filename'.<br>
You can now return to the project page.
<P>

<A href=\"$return_url\">Return to Previous Page</a>

"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
