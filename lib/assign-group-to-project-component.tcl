# /packages/intranet-cust-champ/lib/assign-group-to-project-component.tcl
#
# Copyright (c) 2003-2012 ]project-open[
# All rights reserved.
#
# Author: klaus.hofeditz@project-open.com


# Get permissions
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd

# Check for write permissions
if {!$write} { return "" }

# ###
# Create form
# ###

# Get the list of profiles managable for current_user_id
set managable_profiles [im_profile::profile_options_managable_for_user $user_id]
ns_log Notice "intranet-cust-champ::assign_group_to_project_component: managable_profiles=$managable_profiles"

# Extract only the profile_ids from the managable profiles
set managable_profile_ids [list]
foreach i $managable_profiles {
    lappend managable_profile_ids [lindex $i 1]
}

ns_log Notice "intranet-cust-champ::assign_group_to_project_component: managable_profile_ids=$managable_profile_ids"

set field_label [lang::message::lookup "" intranet-cust-champ.ChooseGroup "Choose group" ]

ad_form -name register -action "/intranet-cust-champ/assign-group-to-project" -export {object_id user_id return_url} -form {
    {group_profiles:text(multiselect),multiple,optional
	{label  $field_label }
	{options $managable_profiles }
	{html {size 12}}
    }
}
