# /packages/intranet-filestorage/www/add-perms-2.tcl
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

ns_log Notice "add-perms-2: object_id=$object_id"
ns_log Notice "add-perms-2: folder_type=$folder_type"
ns_log Notice "add-perms-2: dir_id=[array get dir_id]"


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
    set rel_path $id_path($id)
    ns_log Notice "add-perms-2: object_id=$object_id, rel_path=$rel_path"

    
    # Check permissions and skip
    set user_perms [im_filestorage_folder_permissions $user_id $object_id $rel_path $user_memberships $roles $profiles $perm_hash_array]
    set admin_p [lindex $user_perms 3]
    if {!$admin_p} {
	ad_return_complaint 1 "You don't have permissions to administer $rel_path"
	return
    }

    # -----------------------------------------------
    # Make sure the folder exists...
    set folder_id [db_string folder_exists "select folder_id from im_fs_folders where object_id = :object_id and path = :rel_path" -default 0]
    ns_log Notice "add-perms-2: folder_id=$folder_id"

    # Create the folder if it doesn't exist yet
    if {!$folder_id} {
	set folder_id [db_nextval im_fs_folder_seq]

	# There is a strange bug with preinstalled P/O systems
	# where the im_fs_folder_seq doesn't get updated.
	# So let's workaround with updating new folder_seq_ids...
	set folder_id_exists [db_string folder_id_exists "select count(*) from im_fs_folders where folder_id=:folder_id" -default 0]
	while {$folder_id_exists} {
	    set folder_id [db_nextval im_fs_folder_seq]
	    set folder_id_exists [db_string folder_id_exists "select count(*) from im_fs_folders where folder_id=:folder_id" -default 0]
	}

	ns_log Notice "add-perms-2: folder_id=$folder_id"
	db_dml insert_folder_sql "
insert into im_fs_folders
(folder_id, object_id, path) 
values (:folder_id, :object_id, :rel_path)
"
    }


    # -----------------------------------------------
    # Add profile perms
    #
    foreach profile_id [array names view_profile] {
	im_filestorage_perm_add_profile $folder_id "view" $profile_id 1
    }
    foreach profile_id [array names read_profile] {
	im_filestorage_perm_add_profile $folder_id "view" $profile_id 1
	im_filestorage_perm_add_profile $folder_id "read" $profile_id 1
    }
    foreach profile_id [array names write_profile] {
	im_filestorage_perm_add_profile $folder_id "view" $profile_id 1
	im_filestorage_perm_add_profile $folder_id "read" $profile_id 1
	im_filestorage_perm_add_profile $folder_id "write" $profile_id 1
    }
    foreach profile_id [array names admin_profile] {
	im_filestorage_perm_add_profile $folder_id "view" $profile_id 1
	im_filestorage_perm_add_profile $folder_id "read" $profile_id 1
	im_filestorage_perm_add_profile $folder_id "write" $profile_id 1
	im_filestorage_perm_add_profile $folder_id "admin" $profile_id 1
    }


    # -----------------------------------------------
    # Add role perms
    #
    foreach role_id [array names view_role] {
	im_filestorage_perm_add_role $folder_id "view" $role_id 1
    }
    foreach role_id [array names read_role] {
	im_filestorage_perm_add_role $folder_id "view" $role_id 1
	im_filestorage_perm_add_role $folder_id "read" $role_id 1
    }
    foreach role_id [array names write_role] {
	im_filestorage_perm_add_role $folder_id "view" $role_id 1
	im_filestorage_perm_add_role $folder_id "read" $role_id 1
	im_filestorage_perm_add_role $folder_id "write" $role_id 1
    }
    foreach role_id [array names admin_role] {
	im_filestorage_perm_add_role $folder_id "view" $role_id 1
	im_filestorage_perm_add_role $folder_id "read" $role_id 1
	im_filestorage_perm_add_role $folder_id "write" $role_id 1
	im_filestorage_perm_add_role $folder_id "admin" $role_id 1
    }

}
ad_returnredirect $return_url

