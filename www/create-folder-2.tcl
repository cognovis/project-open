# /www/intranet/filestorage/eraseFile.tcl

ad_page_contract {
    Show the content a specific subdirectory

    @param folder
    @param project_id
    @param folder_type
    @param return_url
    @param folder_name
    @param start_path

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @cvs-id erase-file.tcl
} {

    {folder ""}
    {folder_type ""}
    project_id:notnull
    return_url:notnull
    folder_name:notnull
    start_path:notnull
}

# User id already verified by filters
set user_id [ad_get_user_id]
set page_title "File Tree Competitiveness"
set context_bar [ad_context_bar_ws $page_title]
set page_focus ""

set current_user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]

set erase [im_filestorage_create_folder $folder $folder_name ]

set group_id $project_id

db_release_unused_handles

ns_returnredirect ../..$start_path

doc_return  200 text/html [im_return_template]
















