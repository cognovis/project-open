# /www/intranet/filestorage04/folder_state_update.tcl

ad_page_contract {
    Index page of filestorage

    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author santitrenchs@santitrenchs.com

} {
    object_id:integer
    rel_path
    { status "c" }
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
ns_log Notice "folder_status_update: return_url=$return_url"


# change the folder status from open to close and vice versa
if { $status == "o" } {
    set status "c"
} else {
    set status "o"
}


set exists_p [db_string exists_folder "select count(*) from im_fs_folder_status where object_id = :object_id and path = :rel_path and user_id = :user_id"]

if {$exists_p} {

   db_dml update_folder_status "
update
        im_fs_folder_status s
set
        open_p = :status
where
	object_id = :object_id 
	and path = :rel_path 
	and user_id = :user_id
"

} else {

    db_dml my_insert "
    insert into im_fs_folder_status (
        object_id,
        user_id,
        path,
        open_p,
	folder_id
    ) values (
        :object_id,
        :user_id,
        :rel_path,
        :status,
	im_fs_folder_status_seq.nextval
    )"
}
ad_returnredirect $return_url
