ad_page_contract {
    page to add a new file to the system
    @author Kevin Scaldeferri (kevin@arsdigita.com)
    @creation-date 6 Nov 2000
    @cvs-id $Id: file-add.tcl,v 1.3 2011/06/07 15:51:42 po34demo Exp $
} {
    { ticket_id:integer ""}
    upload_file:trim,optional
    upload_file.tmpfile:tmpfile,optional
    {title ""}
    {description "" }
}

if {![info exists upload_file]} {
    ns_log Notice "file-add: failure"
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

set user_id [ad_conn user_id]
# Get package. ad_conn package_id doesn't seem to work...
set package_id [db_string package "select min(package_id) from apm_packages where package_key = 'file-storage'"]
set mime_type [cr_filename_to_mime_type -create -- $upload_file]
set folder_id [im_fs_content_folder_for_object -object_id $ticket_id]

ns_log Notice "file-add: upload_file=[im_opt_val upload_file], title=$title, upload_file.tmpfile=${upload_file.tmpfile}, mime_type=$mime_type, package_id=$package_id, folder_id=$folder_id"

set permission_p [permission::permission_p \
    -object_id $folder_id \
    -party_id $user_id \
    -privilege "write" \
]
ns_log Notice "file-add: permission_p=$permission_p"

# set permission_p "1"


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

ns_log Notice "file-add: success"
doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	true,
		\"errors\":	{\"email\": \"already taken\"}
    	}
}"
ad_script_abort

