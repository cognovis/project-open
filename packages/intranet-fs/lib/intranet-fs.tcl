#
#  Copyright (C) 2001, 2002 MIT
#
#  This file is part of dotLRN.
#
#  dotLRN is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

# fs-portlet/www/fs-portlet.tcl

ad_page_contract {
    The display logic for the fs portlet

    @author yon (yon@openforce.net)
    @author Arjun Sanyal (arjun@openforce.net)
    @cvs_id $Id: fs-portlet.tcl,v 1.24 2008/11/09 23:29:27 donb Exp $
} -query {
    {n_past_days "99999"}
    {page_num ""}
} -properties {
    user_id:onevalue
    user_root_folder:onevalue
    user_root_folder_present_p:onevalue
    write_p:onevalue
    admin_p:onevalue
    delete_p:onevalue
    url:onevalue
    folders:multirow
    n_folders:onevalue
}

set user_id [ad_conn user_id]

# Check and grant permissions for the project folder

im_project_permissions $user_id $project_id project_view_p project_read_p project_write_p project_admin_p

set read_p [permission::permission_p -party_id $user_id -object_id $folder_id -privilege "read"]
set admin_p [permission::permission_p -party_id $user_id -object_id $folder_id -privilege "admin"]
set write_p [permission::permission_p -party_id $user_id -object_id $folder_id -privilege "write"]
set delete_p [permission::permission_p -party_id $user_id -object_id $folder_id -privilege "delete"]

if {!$read_p && $project_read_p} {
    ns_log Notice "GRANT READ PERMISSION"
    permission::grant -party_id $user_id -object_id $folder_id -privilege read
}

if {!$write_p && $project_write_p} {
    ns_log Notice "GRANT WRITE RELATED PERMISSIONS"
    permission::grant -party_id $user_id -object_id $folder_id -privilege create
    permission::grant -party_id $user_id -object_id $folder_id -privilege write
    permission::grant -party_id $user_id -object_id $folder_id -privilege delete
}

if {!$admin_p && $project_admin_p} {
    ns_log Notice "GRANT ADMIN PERMISSION"
    permission::grant -party_id $user_id -object_id $folder_id -privilege admin
}

permission::require_permission -party_id $user_id -object_id $folder_id -privilege "read"

set list_of_folder_ids $folder_id
set n_folders [llength $list_of_folder_ids]

set user_root_folder [fs::get_root_folder -package_id [intranet_fs::get_fs_package_id]]

set user_root_folder_present_p 0

set folder_name [fs_get_folder_name $user_root_folder]
if {![empty_string_p $user_root_folder] && [lsearch -exact $list_of_folder_ids $user_root_folder] != -1} {
    set folder_id $user_root_folder
    set user_root_folder_present_p 1
    set use_ajaxfs_p 0
} else {
    set folder_id [lindex $list_of_folder_ids 0]
    set file_storage_package_id [intranet_fs::get_fs_package_id]
    set use_ajaxfs_p [parameter::get -package_id $file_storage_package_id -parameter UseAjaxFs -default 0]
}

set url [site_node_object_map::get_url -object_id $folder_id]

set recurse_p 1
set contents_url "${url}folder-contents?[export_vars {folder_id recurse_p}]&"
set scope_fs_url "/packages/intranet-fs/lib/folder-chunk"

# Enable Notifications

set folder_name [fs_get_folder_name $folder_id]
set fs_url [site_node::get_package_url -package_key "file-storage"]

set notification_chunk [notification::display::request_widget \
    -type fs_fs_notif \
    -object_id $folder_id \
    -pretty_name $folder_name \
    -url [ad_conn url]?[ad_conn query]&folder_id=$folder_id \
    ]

if [exists_and_not_null file_storage_package_id] {
    set use_webdav_p  [parameter::get -package_id $file_storage_package_id -parameter "UseWebDavP"]
    
    if { $use_webdav_p == 1} { 
	set webdav_url [fs::webdav_url -item_id $folder_id -package_id $file_storage_package_id]
        regsub -all {/\$} $webdav_url {/\\$} webdav_url
    }
}

ad_return_template 
