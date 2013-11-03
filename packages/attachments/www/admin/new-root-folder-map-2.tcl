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

    Creates a new fs root folder and maps it to the passed in packge_id

    @author Arjun Sanyal (arjun@openforce.net)
    @cvs-id $Id$

} -query {
    {package_id:notnull}
    {referer:notnull}
}

# apm sucks
set instance_name [db_string instance_name_select "select instance_name from apm_packages where package_id = :package_id"]

set folder_id [fs::new_root_folder \
    -package_id $package_id \
    -pretty_name "$instance_name's Attachments" \
    -description "[_ attachments.lt_Created_by_the_attach]"
]

attachments::map_root_folder -package_id $package_id -folder_id $folder_id


ad_returnredirect $referer
