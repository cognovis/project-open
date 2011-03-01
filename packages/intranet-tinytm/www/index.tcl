# /packages/intranet-tinytm/www/index.tcl
#
# Copyright (C) 2008 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    TinyTM main page.
    Offers action links and possibly some statistics about
    the TM.

    @author frank.bergmann@project-open.com
} {
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-tinytm.TinyTM_Homepage "TinyTM Homepage"]
set context_bar [im_context_bar $page_title]
set context $context_bar

# ToDo: permissions
#if {![im_permission $current_user_id view_costs]} {
#    ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
#    return
#}


# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set dynamic_fields_p 1
set form_id "project_filter"
set object_type "im_project"
set action_url "/intranet/projects/index"
set form_mode "edit"
set mine_p_options [list \
	[list [lang::message::lookup "" intranet-core.All "All"] "f" ] \
	[list [lang::message::lookup "" intranet-core.With_members_of_my_dept "With member of my department"] "dept"] \
	[list [lang::message::lookup "" intranet-core.Mine "Mine"] "t"] \
]


ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name include_subprojects_p letter filter_advanced_p}\
    -form {
    	{mine_p:text(select),optional {label "Mine/All"} {options $mine_p_options }}
    }
    
if {[im_permission $current_user_id "view_projects_all"]} {  
    ad_form -extend -name $form_id -form {
	{project_status_id:text(im_category_tree),optional {label #intranet-core.Project_Status#} {custom {category_type "Intranet Project Status" translate_p 1}} }
	{project_type_id:text(im_category_tree),optional {label #intranet-core.Project_Type#} {custom {category_type "Intranet Project Type" translate_p 1} } }
    }

    template::element::set_value $form_id project_status_id $project_status_id
    template::element::set_value $form_id project_type_id $project_type_id
}

if {$filter_advanced_p && [db_table_exists im_dynfield_attributes]} {

    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
        -form_id $form_id \
        -object_id 0 \
	-advanced_filter_p 1

    # Set the form values from the HTTP form variable frame
    im_dynfield::set_form_values_from_http -form_id $form_id

    im_dynfield::set_local_form_vars_from_http -form_id $form_id

    array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
	-form_id $form_id \
	-object_type $object_type
    ]
}




# ---------------------------------------------------------------
# select the "TinyTM" Menu
# ---------------------------------------------------------------

set parent_menu_id [db_string mid "select menu_id from im_menus where label='tinytm'" -default 0]

set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
		and enabled_p = 't'
                and im_object_permission_p(m.menu_id, :current_user_id, 'read') = 't'
        order by sort_order"

# Start formatting the menu bar
set new_list_html ""
set ctr 0

db_foreach menu_select $menu_select_sql {

    ns_log Notice "im_sub_navbar: menu_name='$name'"
    if {$company_id} { append url "&company_id=$company_id" }
    if {$project_id} { append url "&project_id=$project_id" }
    regsub -all " " $name "_" name_key
    append new_list_html "<li><a href=\"$url\">[lang::message::lookup $package_name.$name_key $name]</a></li>\n"
}

set admin_html "
	<ul>
	<li><a href=import-tmx><%= [lang::message::lookup "" intranet-tinytm.Import_TMX "Import TMX"]%></a></li>
	</ul>
"


set sub_navbar [im_sub_navbar $parent_menu_id "" "" "tabnotsel" "nothing"]

