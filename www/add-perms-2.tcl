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

ns_logg Notice "add-perms-2: object_id=$object_id"
ns_log Notice "add-perms-2: folder_type=$folder_typee"
ns_log Notice "add-perms-2: dir_id=$dir_id"


# -------------------------------------------------------
# Page Code
# -------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]

foreach id [array names dir_id] {
    set path $id_path($id)
    ns_log Notice "add-perms-2: path=$path"

    foreach profile_id [array names view_profile] {
	ns_log Notice "add-perms-2: perm=view, path=$path, profile_id=$profile_id"
	im_filestorage_add_profile_perm "view" $path $object_id $profile_id 1
    }
}
ad_returnredirect $return_url






# -------------------------------------------------------
# Common permission-adding procedure
# -------------------------------------------------------

ad_proc im_filestorage_add_profile_perm { perm path object_id profile_id p} {

    # Make sure the folder exists...
    set folder_exists_p [db_string folder_exists "select count(*) from im_fs_folders where object_id=:object_id and path=:path"]
    ns_log Notice "add-perms-2: exists=$folder_exists_p for $path"
    if {!$folder_exists_p} {
	db_dml insert_folder_sql "
insert into im_fs_folders
(folder_id, object_id, path) 
values ($folder_id, object_id, path)"
    }

    # !!! Here To Continue
    set sql "
insert into im_fs_folder_perms 
(folder_id, profile_id, ${perm}_p)
values ($folder_id, $profile_id, $p)"

     if { [catch {
         db_dml add_profile $sql
     } err_msg] } { 
	# nothing... 
     }
}






