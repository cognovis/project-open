# /packages/intranet-filestorage/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Shows a certain filestorage:

    By default shows the "Home"-Filestorage.

    @param file_id
	This option is used by the Full-Text Search.
    	The file_id refers to a file matching the search
	criteria. This page then shows the filestorage
	of the matching object.

    @param object_id
	Id of an object. The page shows the filestorage
	of the object if the current_user has the permissions
	to read the object.
	Then further permission restrictions apply to the
	filestorage folders.

    @param bread_crum_path
	Subdirectory where to start "opening" the FS


    Show the list of current task and allow the project
    manager to create new tasks.

    @author frank.bergmann@project-open.com
    @creation-date Nov 2003
} {
    { bread_crum_path "" }
    { object_id 0 }
    { file_id 0 }
}

set user_id [ad_maybe_redirect_for_registration]
set return_url "/intranet-filestorage/"
set current_url_without_vars [ns_conn url]


# Determine the right "Business Object" if file_id was given
if {0 != $file_id} {
    set object_id [db_string biz_oid "
	select	object_id
	from	im_fs_folders ff,
		im_fs_files f
	where	f.file_id = :file_id
		and f.folder_id = ff.folder_id
    "]
}


# Check Permissions
set object_type ""
if {$object_id != 0} {
    set object_type [db_string otype "
	select object_type 
	from acs_objects 
	where object_id = :object_id
    " -default ""]
    
    set object_name [db_string oname "
	select acs_object__name(:object_id)
    " -default ""]

    # expect commands such as: "im_project_permissions" ...
    set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
    eval $perm_cmd

} else {

    # We've been called without an object => Yes, we are allowed to see the home FS
    set object_view 1
    set object_read 1
    set object_write 0
    set object_admin 0
    set object_name [lang::message::lookup "" intranet-filestorage.Home_Filestorage "Home Filestorage"]
}

set page_title $object_name
set navbar [im_context_bar $page_title]

switch $object_type {
    im_project {
	set project_path [im_filestorage_project_path $object_id]
	set folder_type "project"
	set object_name "Project"
	set page_body [im_filestorage_base_component $user_id $object_id $object_name $project_path $folder_type]

	set bind_vars [ns_set create]
	ns_set put $bind_vars project_id $object_id
	set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
	set navbar [im_sub_navbar $parent_menu_id $bind_vars "" "pagedesriptionbar" "project_files"]
    }
    im_company {
	set company_path [im_filestorage_company_path $object_id]
	set folder_type "company"
	set page_body [im_filestorage_base_component $user_id $object_id $object_name $company_path $folder_type]
    }
    user {
	set user_path [im_filestorage_user_path $object_id]
	set folder_type "user"
	set user_name $object_id
	set page_body [im_filestorage_base_component $user_id $object_id $object_name $user_path $folder_type]
    }
    default {
	set page_body [im_filestorage_home_component $user_id]
    }
}

