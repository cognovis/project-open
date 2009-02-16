# /packages/intranet-filestorage/www/erase-folder.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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


# -------------------------------------------------------
# Check Permission
# -------------------------------------------------------

# Get the list of all relevant roles and profiles for permissions
set roles [im_filestorage_roles $user_id $object_id]
set profiles [im_filestorage_profiles $user_id $object_id]

# Get the group membership of the current (viewing) user
set user_memberships [im_filestorage_user_memberships $user_id $object_id]

# Get the list of all (known) permission of all folders of the FS
# of the current object
set perm_hash_array [im_filestorage_get_perm_hash $user_id $object_id $user_memberships]
array set perm_hash $perm_hash_array


# -------------------------------------------------------
#
# -------------------------------------------------------


foreach id [array names file_id] {

    set file_path $id_path($id)
    set file_path_list [split $file_path {/}]
    set len [expr [llength $file_path_list] - 2]
    set path_list [lrange $file_path_list 0 $len]
    set path [join $path_list "/"]

    # Check permissions
    set user_perms [im_filestorage_folder_permissions $user_id $object_id $path $user_memberships $roles $profiles $perm_hash_array]
    set admin_p [lindex $user_perms 3]
    if {!$admin_p} {
	ad_return_complaint 1 "You don't have permission to delete in folder '$path'"
	return
    }

    set erase [im_filestorage_erase_files $object_id $base_path/$id_path($id)]
}


foreach id [array names dir_id] {

    set path $id_path($id)

    # Check permissions
    set user_perms [im_filestorage_folder_permissions $user_id $object_id $path $user_memberships $roles $profiles $perm_hash_array]
    set admin_p [lindex $user_perms 3]
    if {!$admin_p} {
	ad_return_complaint 1 "You don't have permission to delete folder '$path'"
	return
    }

    set folder_id [db_string folder_exists "select folder_id from im_fs_folders where object_id = :object_id and path = :path" -default 0]
    set erase [im_filestorage_delete_folder $object_id $folder_id $base_path/$id_path($id)]

}
ad_returnredirect $return_url









