# /packages/intranet-filestorage/www/erase-folder.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the content a specific subdirectory

    @param folder 
    @param group_id
    @param return_url
    @start_path the original path who demands the page

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @frank.bergmann@project-open.com
} {
   
    folder:notnull
    group_id:notnull
    return_url:notnull
    start_path:notnull
}

# User id already verified by filters
set user_id [ad_get_user_id]
set page_title "File Tree Competitiveness"
set context_bar [ad_context_bar_ws $page_title]
set page_focus ""


set current_user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]


set erase [im_filestorage_delete_folder $group_id $folder]

db_release_unused_handles

ns_returnredirect ../..$start_path

doc_return  200 text/html [im_return_template]









