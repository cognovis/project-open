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
    ns_log Notice "del-perms-2: profile_id=$profile_id, folder_id=$folder_id, perm=$perm, p=$p"

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
    ns_log Notice "del-perms-2: role_id=$role_id, folder_id=$folder_id, perm=$perm, p=$p"

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

foreach id [array names dir_id] {
    set path $id_path($id)
    ns_log Notice "del-perms-2: object_id=$object_id, path=$path"


    # -----------------------------------------------
    # Make sure the folder exists...
    # and skip any actions if the folder doesn't exist.
    set folder_id [db_string folder_exists "select folder_id from im_fs_folders where object_id = :object_id and path = :path" -default 0]
    if {!$folder_id} { return }


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
ad_returnredirect $return_url

