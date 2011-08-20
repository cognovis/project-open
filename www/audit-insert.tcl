ad_page_contract {
    page to insert a new audit to im_audit
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 19/08/2011
    @cvs-id $Id$
} {
    { object_id:integer}
    { user_id "" }
	{ object_type "" }
	{ status_id "" }
	{ type_id "" }
	{ action }
}

if {[info exists upload_file]} {
    if {"" == $title} { set title $upload_file }
} else {
    ns_log Notice "file-add: failure: upload_file does not exist"
    ns_return 200 "text/html" "{
	\"result\": {
		\"success\":	false,
		\"errors\":	{\"upload_file\": \"You have to specify a file to upload\"}
    	}
    }"
    ad_script_abort
}

# -------------------------------------------------------------
# Security
# -------------------------------------------------------------

set user_id [im_rest_cookie_auth_user_id]
# Get package. ad_conn package_id doesn't seem to work...
set package_id [db_string package "select min(package_id) from apm_packages where package_key = 'file-storage'"]
set mime_type [cr_filename_to_mime_type -create -- $upload_file]
set folder_id [im_fs_content_folder_for_object -object_id $ticket_id]
ns_log Notice "file-add: user_id=$user_id, ticket_id=$ticket_id, mime_type=$mime_type, folder_id=$folder_id, upload_file=[im_opt_val upload_file], title=$title, upload_file.tmpfile=${upload_file.tmpfile}"

set permission_p [permission::permission_p \
    -object_id $folder_id \
    -party_id $user_id \
    -privilege "write" \
]
ns_log Notice "file-add: permission_p=$permission_p"

if {1 != $permission_p} {
    ns_log Notice "file-add: failure: User \#$user_id doesn't have write permissions to folder \#$folder_id"
    doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	false,
		\"errors\":	{\"permission\": \"You do not have permission to write to folder \#$folder_id\"}
    	}
    }"
    ad_script_abort
}

# -------------------------------------------------------------
# Create the new file in the FS
# -------------------------------------------------------------

if {"" != $upload_file} {
    set this_file_id ""

    fs::add_file \
	-name $upload_file \
	-parent_id $folder_id \
	-tmp_filename ${upload_file.tmpfile}\
	-creation_user $user_id \
	-creation_ip [ad_conn peeraddr] \
	-title $title \
	-description $description \
	-package_id $package_id \
	-mime_type $mime_type
    
}

set folder_path [db_string folder_path "select fs_folder_path from im_biz_objects where object_id = :ticket_id"]

ns_log Notice "file-add: success"
doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	true,
		\"message\":	\"File successfully created\",
		\"data\":	\[{
			\"fs_folder_id\":	$folder_id,
			\"fs_folder_path\":	\"$folder_path\"
		}\]
    	}
}"
ad_script_abort

