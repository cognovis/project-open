# /packages/intranet-filestorage/www/intranet/filestorage04/folder_state_update.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Index page of filestorage

    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author santitrenchs@santitrenchs.com
    @author pvilarmau@hotmail.com
    @author frank.bergmann@project-open.com
} {
    folder_id:integer
    object_id:integer
    file
    { status "c" }
    return_url
    { bread_crum_path "" }
}

set user_id [ad_maybe_redirect_for_registration]

ns_log Notice ""
ns_log Notice ""
ns_log Notice ""
ns_log Notice ""
ns_log Notice "////****************** Start Folder status update ****************////"

ns_log Notice "////****************** End Folder status update ****************////"
ns_log Notice ""
ns_log Notice ""
ns_log Notice ""

# change the folder status, if comes from close we set to open and vice versa
if { $status == "o" } {
    set status "c"
} else {
    set status "o"
}

if { [catch {
    db_dml my_update "
update 
	im_fs_folder_status 
set 
	open_p = '$status' 
where 
	folder_id=$folder_id"

} err_msg] } {
    # Didn't exist before?
    db_dml my_insert "
    insert into im_fs_folder_status (
	folder_id, 
	object_id,
	user_id, 
	path, 
	open_p
    ) values (
	im_fs_folder_status_seq.nextval,
	:object_id,
	:user_id,
	:file,
	:status
    )"
}

ad_returnredirect $return_url
