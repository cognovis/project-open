#
#  Copyright (C) 2002 MIT
#
#  this is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  this is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

ad_page_contract {
    Tries to find an appropriate fs root folder for the passed in package_id. 
    If it can't find one, it prompts to make new one.

    @author Arjun Sanyal (arjun@openforce.net)
    @cvs-id $Id$

} -query {
    {package_id:notnull}
    {referer:notnull}
}

# can't use the get_root_folder proc since it creates 
# a new one if one doesn't exist. A BUG.
set root_folder_id [db_string has_fs_root_folder_p_select \
     "select folder_id from fs_root_folders where package_id = :package_id" \
     -default 0 ]

if {$root_folder_id == 0} {
    # look for a fs root folder candidate, by looking for an file-storage
    # sibling of our parent (uncle? or aunt? node). Should generalize sibling 
    # stuff, search by parent etc.
    set parent_id [site_node::get_parent \
        -node_id [site_node::get_node_id_from_object_id -object_id $package_id] ]

    #
    # todo
    # 

    # if we found one, get that node's info and present it
    # set root_folder_id xxx

    # else ask to create a new root folder
    ad_return_template

} else {
    if {[attachments::root_folder_p -package_id $package_id]} {
        # sanity check that the attachments_root_folder and fs_root_folder match
        set attachments_root_folder [attachments::get_root_folder \
             -package_id $package_id ]

        if {$attachments_root_folder != $root_folder_id} {
            ad_return_complaint 1 "[_ attachments.lt_Error_Attachment_root]"
        } else {
            # since this pkg already has a root folder do the mapping and return
            attachments::map_root_folder \
                -package_id $package_id \
                -folder_id $root_folder_id
            
            ad_returnredirect $referer
            ad_script_abort
        }
    }
}
