ad_page_contract {
    insert a file into the file system
} {
    folder
    {folder_type ""}
    project_id:integer
    return_url
    upload_file
    {file_title:trim ""}
    {description ""}
} 


set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set page_title "Upload into '$folder'"

set context_bar [im_context_bar [list "/intranet/projects/" "Projects"]  [list "/intranet/projects/view?group_id=$project_id" "One Project"]  "Upload File"]


# check the user input first
#
set exception_text ""
set exception_count 0
if {!$user_is_admin_p && ![im_biz_object_member_p $user_id $project_id] } {
    append exception_text "<li>You are not a member of this project.\n"
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

switch $folder_type {
    "project" {
	set project_path [im_filestorage_project_path $project_id]
	set dest_path "$project_path/$folder/$client_filename"
    }

    "company" {
	set path [im_filestorage_company_path $project_id]
	set dest_path "$path/$folder/$client_filename"
    }

    "user" {
	set path [im_filestorage_user_path $project_id]
	set dest_path "$path/$folder/$client_filename"
    }

    default {
	ad_return_complaint 1 "<LI>Unknown folder type \"$folder_type\"."
	return
    }

}

# --------------- Let's copy the file into the FS --------------------

if { [catch {
    ns_log Notice "/bin/cp $tmp_filename $dest_path"
    exec /bin/cp $tmp_filename $dest_path
} err_msg] } {
    # Probably some permission errors
    ad_return_complaint  "Error writing upload file"  $err_msg
    return
}

# --------------- Log the interaction --------------------

db_dml insert_action "
insert into im_fs_actions (
        action_type_id
        user_id
        action_date
        file_name
) values (
        [im_file_action_upload],
        :user_id,
        now(),
        '$dest_path/$client_filename'
)"


set page_content "
<H2>Upload Successful</H2>

You have successfully uploaded $n_bytes bytes of '$client_filename'.<br>
You can now return to the project page.
<P>

<form method=post action=\"$return_url\">
<input type=submit value=\"Return to Previous Page\">
</form>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
