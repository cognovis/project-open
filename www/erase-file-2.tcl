# /packages/intranet-filestorage/www/erase-ile.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the content a specific subdirectory

    @param folder_type 
    @param project_id
    @param file_name
    @param return_url
    @param start_path

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @author frank.bergmann@project-open.com
} {
    file_name:notnull
    {folder_type ""}
    { id_file:array}

    group_id:notnull
    return_url:notnull
    start_path:notnull
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set page_title "File Tree Competitiveness"
set context_bar [ad_context_bar_ws $page_title]
set page_focus ""


set current_user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]


   	foreach {clau valor} [array get id_file] {
   		if { [catch {
	    	set file_type [file type $id_file($clau)]
			} err_msg] } { }
			if { [string compare $file_type "directory"] == 0 } {    	
				set erase [im_filestorage_delete_folder_04 $group_id $valor]
    	} else {
    		set erase [im_filestorage_erase_file04 $group_id $valor $folder_type] 	
    	}
		 
		}



ns_returnredirect ../..$start_path

db_release_unused_handles



doc_return  200 text/html [im_return_template]









