ad_page_contract {
    page to add a new file to the system
    @author Kevin Scaldeferri (kevin@arsdigita.com)
    @creation-date 6 Nov 2000
    @cvs-id $Id: file-add.tcl,v 1.2 2011/06/06 14:37:19 po34demo Exp $
} {
    folder_id:integer,optional,notnull
    upload_file:trim,optional
    upload_file.tmpfile:tmpfile,optional
    {title ""}
    {description "" }
}

if {![info exists upload_file]} {
    ns_log Notice "file-add: failure"

    ns_return 200 "text/html" "\[
    {
        \"action\":\"Profile\",\"method\":\"updateBasicInfo\",\"type\":\"rpc\",\"tid\":3,
        \"result\":{
            \"success\":true
        }
    }
    \]"
    ad_script_abort

    ns_return 200 "text/html" "{
	\"result\": {
		\"success\":	false,
		\"errors\":	{\"email\": \"already taken\"}
    	}
    }"
    ad_script_abort
}

set user_id [ad_conn user_id]
# Get package. ad_conn package_id doesn't seem to work...
set package_id [db_string package "select min(package_id) from apm_packages where package_key = 'file-storage'"]
set mime_type [cr_filename_to_mime_type -create -- $upload_file]

ns_log Notice "file-add: folder_id=[im_opt_val folder_id], upload_file=[im_opt_val upload_file], title=$title, upload_file.tmpfile=${upload_file.tmpfile}, mime_type=$mime_type, package_id=$package_id"

permission::require_permission \
    -object_id $folder_id \
    -party_id $user_id \
    -privilege "write"


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

db_release_unused_handles
ad_http_cache_control

ns_log Notice "file-add: success"
ns_return 200 "text/html" "{
	\"result\": {
		\"success\":	true,
		\"errors\":	{\"email\": \"already taken\"}
    	}
}"
ad_script_abort

