# /www/intranet/filestorage04/folder_state_update.tcl

ad_page_contract {
    Index page of filestorage

    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author santitrenchs@santitrenchs.com

} {
    folder_id:integer
    { status "c" }
    return_url
    { bread_crum_path "" }
}


# change the folder status, if comes from close we set to open and vice versa
if { $status == "o" } {
    set status "c"
} else {
    set status "o"
}

db_transaction {
    db_dml my_update "
update 
	im_fs_folder_status 
set 
	open_p = '$status' 
where 
	folder_id=$folder_id"
}

ad_returnredirect $return_url


