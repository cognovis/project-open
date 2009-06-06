# /packages/intranet-confdb/www/index.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { project_id ""}
    { cost_center_id ""}
    { status_id ""}
    { type_id ""}
    { owner_id ""}
    { treelevel "0" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]
set page_focus "im_header_form.keywords"
set page_title [lang::message::lookup "" intranet-confdb.Configuration_Items "Configuration Items"]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]

set date_format "YYYY-MM-DD"

# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set add_conf_item_p [im_permission $current_user_id "add_conf_items"]
set add_conf_item_p 1

set delete_conf_item_p $add_conf_item_p


set admin_links ""

if {$add_conf_item_p} {
    append admin_links " <li><a href=\"[export_vars -base /intranet-confdb/new {return_url {form_mode "edit"}}]\">[lang::message::lookup "" intranet-confdb.Add_a_new_Conf_Item "Add a new Configuration Item"]</a></li>\n"
}

append admin_links [im_menu_ul_list -no_uls 1 "conf_items" {}]

if {"" != $admin_links} {
    set admin_links "<ul>\n$admin_links\n</ul>\n"
}


# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

# set project_options [im_project_options -project_status_id [im_project_status_open]]
#     	{project_id:text(select),optional { label "[lang::message::lookup {} intranet-confdb.Project {Project}]" } {options $project_options }}


set owner_options [util_memoize "im_employee_options" 3600]
set cost_center_options [im_cost_center_options -include_empty 1]
set treelevel_options [list \
	[list [lang::message::lookup "" intranet-confdb.Top_Items "Only Top Items"] 0] \
	[list [lang::message::lookup "" intranet-confdb.2nd_Level_Items "2nd Level Items"] 1] \
	[list [lang::message::lookup "" intranet-confdb.All_Items "All Items"] ""] \
]

set form_id "conf_item_filter"
set object_type "im_conf_item"
set action_url "/intranet-confdb/index"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name} \
    -form {
	{treelevel:text(select),optional {label "[lang::message::lookup {} intranet-core.Treelevel {Treelevel}]"} {options $treelevel_options } }
	{type_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Type {Type}]"} {custom {category_type "Intranet Conf Item Type" translate_p 1 package_key "intranet-confdb"} } }
	{status_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Status {Status}]"} {custom {category_type "Intranet Conf Item Status" translate_p 1 package_key "intranet-confdb"}} }
    	{cost_center_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Cost_Center {Cost Center}]"} {options $cost_center_options }}
    	{owner_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Owner {Owner}]"} {options $owner_options }}
    }

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


# ---------------------------------------------------------------
# Conf_Items info
# ---------------------------------------------------------------

# Variables of this page to pass through the conf_items_page

set export_var_list [list]

# define list object
set list_id "conf_items_list"

# Don't show project name, because of duplicates
#	project_name {
#	    label "[lang::message::lookup {} intranet-confdb.Project {Project}]"
#	    link_url_eval {[export_vars -base "/intranet/projects/view" {project_id}]}
#	}

set bulk_actions_list "[list]"
if {$delete_conf_item_p} {
    lappend bulk_actions_list "[lang::message::lookup "" intranet-confdb.Delete "Delete"]" "conf-item-del" "[lang::message::lookup "" intranet-confdb.Remove_checked_items "Remove Checked Items"]"
}

template::list::create \
    -name $list_id \
    -multirow conf_item_lines \
    -key conf_item_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { return_url} \
    -row_pretty_plural "[lang::message::lookup "" intranet-confdb.Conf_Items_Items {Conf Items}]" \
    -elements {
	conf_item_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('conf_items_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@conf_item_lines.conf_item_chk;noquote@
	    }
	}
	conf_item_name {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Name Name]"
	    display_template {
		@conf_item_lines.indent;noquote@<a href=@conf_item_lines.conf_item_url;noquote@>@conf_item_lines.conf_item_name;noquote@</a>
	    }
	}
        ip_address {
	    label "[lang::message::lookup {} intranet-confdb.IP_Address IP-Address]"
	}
        conf_item_type {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Type Type]"
	}
        conf_item_status {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Status Status]"
	}
        processor_speed {
	    label "[lang::message::lookup {} intranet-confdb.Processor Processor]"
	    display_template {
		@conf_item_lines.processor;noquote@
	    }
	}
        sys_memory {
	    label "[lang::message::lookup {} intranet-confdb.Memory Memory]"
	}
        os_name {
	    label "[lang::message::lookup {} intranet-confdb.OS OS]"
	}
        os_version {
	    label "[lang::message::lookup {} intranet-confdb.OS_Version Version]"
	}
    }

set ttt {
        win_workgroup {
	    label "[lang::message::lookup {} intranet-confdb.Workgroup Workgroup]"
	}
        win_userdomain {
	    label "[lang::message::lookup {} intranet-confdb.Domain Domain]"
	}
	conf_item_code {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Code Code]"
	}
	conf_item_nr {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Nr {Nr.}]"
	}
        conf_item_owner {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Cost_Owner Owner]"
	    link_url_eval {[export_vars -base "/intranet/users/view" {{user_id $conf_item_owner_id}}]}
	}
        conf_item_cost_center {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Cost_Center {Cost Center}]"
	}
}


# ---------------------------------------------------------------
# Compose SQL
# ---------------------------------------------------------------

set conf_item_sql [im_conf_item_select_sql \
	-project_id $project_id \
	-type_id $type_id \
	-status_id $status_id \
	-owner_id $owner_id \
	-cost_center_id $cost_center_id \
	-treelevel $treelevel \
]

set sql "
	select	i.*,
		tree_level(i.tree_sortkey)-1 as indent_level,
		p.project_id,
		project_name
	from	($conf_item_sql) i
		LEFT OUTER JOIN acs_rels r ON (i.conf_item_id = r.object_id_two)
		LEFT OUTER JOIN im_projects p ON (p.project_id = r.object_id_one)
	order by
		i.tree_sortkey
"



db_multirow -extend {conf_item_chk conf_item_url indent return_url processor} conf_item_lines conf_items_lines $sql {
    set conf_item_chk "<input type=\"checkbox\" 
				name=\"conf_item_id\" 
				value=\"$conf_item_id\" 
				id=\"conf_items_list,$conf_item_id\">"
    set processor "${processor_num}x$processor_speed"
    set return_url [im_url_with_query]
    set conf_item_url [export_vars -base new {conf_item_id {form_mode "display"}}]

    set indent ""
    for {set i 0} {$i < $indent_level} {incr i} {
	append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    }
}




eval [template::adp_compile -string {<formtemplate id="conf_item_filter"></formtemplate>}]
set filter_html $__adp_output

set left_navbar_html "
    <div class='filter-block'>
      <div class='filter-title'>
	[lang::message::lookup "" intranet-confdb.Filter_Items "Filter Items"]
      </div>
      $filter_html
    </div>
    <hr>

    <div class='filter-block'>
      <div class='filter-title'>
        #intranet-core.Admin_Links#
      </div>
      $admin_links
    </div>
"