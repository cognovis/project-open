# -------------------------------------------------------------
# /packages/intranet-confdb/www/conf-item-list-component.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	object_id:integer:	For specifying an associated object
#	owner_id:integer:	For specifying the owner
#	return_url

if {![info exists object_id]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	object_id
    }
}

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p 1
set project_id $object_id


set new_conf_item_url [export_vars -base "/intranet-confdb/new" {object_id return_url}]

# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd

# ----------------------------------------------------
# Create a Form for new elements
# ----------------------------------------------------

# Options - get the value range for input fields
set conf_item_parent_options [im_conf_item_options -include_empty_p 1]
set cost_center_options [util_memoize "im_cost_center_options -include_empty 0" 3600]

set form_id "conf_item"
set action_url "/intranet-confdb/new"

#	{conf_item_code:text(text) {label "[lang::message::lookup {} intranet-core.Conf_Item_Code {Conf Item Code}]"} {html {size 10}}}
#    	{conf_item_cost_center_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Cost_Center {Department}]"} {options $cost_center_options }}
#	{conf_item_name:text(text) {label "[lang::message::lookup {} intranet-core.Conf_Item_Name {Conf Item Name}]"} {html {size 20}}}


ad_form \
    -name $form_id \
    -mode "edit" \
    -action $action_url \
    -export return_url \
    -form {
	conf_item_id:key
	{conf_item_nr:text(text) {label "[lang::message::lookup {} intranet-core.Conf_Item_Nr {Conf Item Nr.}]"} {html {size 10}}}
	{conf_item_parent_id:text(select),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Parent {Parent}]"} {options $conf_item_parent_options} }
	{conf_item_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-core.Conf_Item_Type {Type}]"} {custom {category_type "Intranet Conf Item Type" translate_p 1 package_key "intranet-confdb" include_empty_p 0} } }
	{conf_item_status_id:text(hidden) }
    	{conf_item_project_id:text(hidden) }
    	{conf_item_owner_id:text(hidden) }
    }

ad_form -extend -name $form_id \
    -new_request {

	    set conf_item_status_id [im_conf_item_status_active]
	    set conf_item_project_id $project_id
	    set conf_item_owner_id $current_user_id

    }


# ----------------------------------------------------
# Create a "multirow" to show the results
# ----------------------------------------------------

multirow create conf_items conf_item_type conf_item conf_item_formatted


if {$object_read} {

    if {![info exists project_id]} { set project_id "" }
    if {![info exists owner_id]} { set owner_id "" }
    if {![info exists member_id]} { set member_id "" }

set owner_id ""

    set conf_items_sql [im_conf_item_select_sql \
			    -member_id $member_id \
			    -owner_id $owner_id \
			    -project_id $project_id \
			   ]

    db_multirow -extend { conf_item_formatted } conf_items conf_items_query $conf_items_sql { }
}

