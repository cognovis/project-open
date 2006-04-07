# /packages/intranet-filestorage/www/del-perms-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the content a specific subdirectory

    @param id_path
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
    dir_id:array,optional
    view_profile:array,optional
    view_role:array,optional
    read_profile:array,optional
    read_role:array,optional
    write_profile:array,optional
    write_role:array,optional
    admin_profile:array,optional
    admin_role:array,optional
    object_id:notnull
    bread_crum_path
    folder_type
    return_url:notnull
}

ns_log Notice "del-perms-2: object_id=$object_id"
ns_log Notice "del-perms-2: folder_type=$folder_type"
ns_log Notice "del-perms-2: dir_id=[array get dir_id]"


# -------------------------------------------------------
# Common permission-deling procedure
# -------------------------------------------------------

ad_proc im_filestorage_perm_del_profile { folder_id perm profile_id p} {
    ns_log Notice "del-perms-2: im_filestorage_perm_del_profile: profile_id=$profile_id, folder_id=$folder_id, perm=$perm, p=$p"

    # Don't delete a set permissions...
    if {!$p} { return }

    # Make sure the perm entry exists
    set exists_p [db_string perms_exists "select count(*) from im_fs_folder_perms where folder_id = :folder_id and profile_id = :profile_id" -default 0]
    if {!$exists_p} {
	return
    }

    # Update the perm column
    db_dml update_perms "
update 
	im_fs_folder_perms
set 
	${perm}_p = 0
where 
	folder_id = :folder_id
	and profile_id = :profile_id"
}


ad_proc im_filestorage_perm_del_role { folder_id perm role_id p} {
    ns_log Notice "del-perms-2: im_filestorage_perm_del_role: role_id=$role_id, folder_id=$folder_id, perm=$perm, p=$p"

    # Don't delete a set permissions...
    if {!$p} { return }

    # Make sure the perm entry exists
    set exists_p [db_string perms_exists "select count(*) from im_fs_folder_perms where folder_id = :folder_id and profile_id = :role_id" -default 0]
    if {!$exists_p} {
	return
    }

    # Update the perm column
    db_dml update_perms "
update 
	im_fs_folder_perms
set 
	${perm}_p = 0
where 
	folder_id = :folder_id
	and profile_id = :role_id"
}


# -------------------------------------------------------
# Page Code
# -------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]

# Get the list of all relevant roles and profiles for permissions
set roles [im_filestorage_roles $user_id $object_id]
set profiles [im_filestorage_profiles $user_id $object_id]

# Get the group membership of the current (viewing) user
set user_memberships [im_filestorage_user_memberships $user_id $object_id]

# Get the list of all (known) permission of all folders of the FS
# of the current object
set perm_hash_array [im_filestorage_get_perm_hash $user_id $object_id $user_memberships]
array set perm_hash $perm_hash_array





foreach id [array names dir_id] {
    set path $id_path($id)
    ns_log Notice "del-perms-2: object_id=$object_id, path=$path"


    # Check permissions and skip
    set user_perms [im_filestorage_folder_permissions $user_id $object_id $path $user_memberships $roles $profiles $perm_hash_array]
    set admin_p [lindex $user_perms 3]
    if {!$admin_p} {
        ad_return_complaint 1 "You don't have permissions to administer $path"
        return
    }



    # -----------------------------------------------
    # Make sure the folder exists...
    # and skip any actions if the folder doesn't exist.
    set folder_id [db_string folder_exists "select folder_id from im_fs_folders where object_id = :object_id and path = :path" -default 0]
    if {!$folder_id} { break }


    # -----------------------------------------------
    # Del profile perms
    #
    foreach profile_id [array names view_profile] {
	im_filestorage_perm_del_profile $folder_id "view" $profile_id 1
	im_filestorage_perm_del_profile $folder_id "read" $profile_id 1
	im_filestorage_perm_del_profile $folder_id "write" $profile_id 1
	im_filestorage_perm_del_profile $folder_id "admin" $profile_id 1
    }
    foreach profile_id [array names read_profile] {
	im_filestorage_perm_del_profile $folder_id "read" $profile_id 1
	im_filestorage_perm_del_profile $folder_id "write" $profile_id 1
	im_filestorage_perm_del_profile $folder_id "admin" $profile_id 1
    }
    foreach profile_id [array names write_profile] {
	im_filestorage_perm_del_profile $folder_id "write" $profile_id 1
	im_filestorage_perm_del_profile $folder_id "admin" $profile_id 1
    }
    foreach profile_id [array names admin_profile] {
	im_filestorage_perm_del_profile $folder_id "admin" $profile_id 1
    }


    # -----------------------------------------------
    # Del role perms
    #
    foreach role_id [array names view_role] {
	im_filestorage_perm_del_role $folder_id "view" $role_id 1
	im_filestorage_perm_del_role $folder_id "read" $role_id 1
	im_filestorage_perm_del_role $folder_id "write" $role_id 1
	im_filestorage_perm_del_role $folder_id "admin" $role_id 1
    }
    foreach role_id [array names read_role] {
	im_filestorage_perm_del_role $folder_id "read" $role_id 1
	im_filestorage_perm_del_role $folder_id "write" $role_id 1
	im_filestorage_perm_del_role $folder_id "admin" $role_id 1
    }
    foreach role_id [array names write_role] {
	im_filestorage_perm_del_role $folder_id "write" $role_id 1
	im_filestorage_perm_del_role $folder_id "admin" $role_id 1
    }
    foreach role_id [array names admin_role] {
	im_filestorage_perm_del_role $folder_id "admin" $role_id 1
    }

}

# Cleanup empty folder-perm entries
# ToDo: May get slow with many entries
db_dml cleanup "
delete from im_fs_folder_perms
where 
	view_p = 0
	and read_p = 0
	and write_p = 0
	and admin_p = 0
"


ad_returnredirect $return_url

