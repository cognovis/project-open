# /packages/intranet-filestorage/www/erase-folder.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the content a specific subdirectory

    @param id_path
    @param file_id 
    @param dir_id
    @param object_id
    @param bread_crum_path
    @param folder_type
    @param return_url

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @frank.bergmann@project-open.com
} {
   
    id_path:array,optional
    file_id:array,optional
    dir_id:array,optional
    object_id:notnull
    bread_crum_path
    folder_type
    return_url:notnull
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]

set base_path [im_filestorage_base_path $folder_type $object_id]

foreach id [array names file_id] {
    set erase [im_filestorage_erase_files $object_id $base_path/$id_path($id)]
}


foreach id [array names dir_id] {

    set path $id_path($id)
    set folder_id [db_string folder_exists "select folder_id from im_fs_folders where object_id = :object_id and path = :path" -default 0]
    set erase [im_filestorage_delete_folder $object_id $folder_id $base_path/$id_path($id)]

}
ad_returnredirect $return_url









