# /packages/intranet-filestorage/www/create-folder-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


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
    @author frank.bergmann@project-open.com
} {

    {folder ""}
    {folder_type ""}
    project_id:notnull
    return_url:notnull
    folder_name:notnull
    start_path:notnull
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
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
















