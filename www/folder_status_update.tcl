# /www/intranet/filestorage04/folder_state_update.tcl

ad_page_contract {
    Index page of filestorage

    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author santitrenchs@santitrenchs.com

} {
    folder_id:integer
    object_id:integer
    file
    { status "c" }
    return_url
    { bread_crum_path "" }
}

set user_id [ad_maybe_redirect_for_registration]

# change the folder status, if comes from close we set to open and vice versa
if { $status == "o" } {
    set status "c"
} else {
    set status "o"
}


set exists_p [db_string exists_folder "select count(*) from im_fs_folder_status where folder_id=:folder_id"]

if {$exists_p} {

   db_dml update_folder_status "
update
        im_fs_folder_status
set
        open_p = :status
where
        folder_id = :folder_id"

} else {

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
        '$file',
        :status
    )"
}
append return_url bread_crum_path=$bread_crum_path
ad_returnredirect $return_url
