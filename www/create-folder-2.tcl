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


# Get the list of all relevant roles and profiles for permissions
set roles [im_filestorage_roles $user_id $object_id]
set profiles [im_filestorage_profiles $user_id $object_id]

# Get the group membership of the current (viewing) user
set user_memberships [im_filestorage_user_memberships $user_id $object_id]

# Get the list of all (known) permission of all folders of the FS
# of the current object
set perm_hash_array [im_filestorage_get_perm_hash $user_id $object_id $user_memberships]
array set perm_hash $perm_hash_array


# Check permissions and skip
set user_perms [im_filestorage_folder_permissions $user_id $object_id $bread_crum_path $user_memberships $roles $profiles $perm_hash_array]
set admin_p [lindex $user_perms 3]
if {!$admin_p} {
    ad_return_complaint 1 "You don't have permission to create a subdirectory in folder '$bread_crum_path'"
    return
}

if {"" != $bread_crum_path} { append base_path "/" }
append base_path $bread_crum_path

set err_msg [im_filestorage_create_folder $base_path $folder_name]

db_release_unused_handles
ad_returnredirect $return_url
















