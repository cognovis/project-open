# /packages/intranet-filestorage/www/create-folder-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Create a new directory

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @author frank.bergmann@project-open.com
} {
    folder_type
    folder_name
    bread_crum_path
    object_id:notnull
    return_url:notnull
}

set user_id [ad_maybe_redirect_for_registration]
set base_path [im_filestorage_base_path $folder_type $object_id]

if {"" != $bread_crum_path} { append base_path "/" }
append base_path $bread_crum_path

set err_msg [im_filestorage_create_folder $base_path $folder_name]

db_release_unused_handles
ad_returnredirect $return_url
















