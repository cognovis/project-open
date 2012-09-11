# /packages/intranet-cust-champ/www/assign-group-to-project.tcl

# Copyright (c) 2012 ]project-open[
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
# @author klaus.hofeditz@project-open.com

ad_page_contract {
    Creates member_relationship btw. group members and project 

    @param user_id group to which to add
    @param object_id group to which to add
    @param return_url Return URL

    @author klaus.hofeditz@project-open.com
} {
    { user_id:integer }
    { object_id:integer }
    { group_profiles:integer,multiple }
    { return_url "" }
}

# Security 
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd
if {!$write} {
    ad_return_complaint 1 "You have no rights to add members to this object."
    return
}

# Default Settings 
set role_id 1300 

# Assignment
foreach profile $group_profiles {
    set member_list [group::get_members -group_id $profile]
    foreach member $member_list {
	im_biz_object_add_role $member $object_id $role_id
    }
}


# return 
if { "" == $return_url } {
    ad_returnredirect "/intranet/projects/view?project_id=$object_id"
} else {
    ad_returnredirect $return_url
}

