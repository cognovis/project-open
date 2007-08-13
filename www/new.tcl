# /packages/intranet-confdb/www/new.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# all@devcon.project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show or create a new configuration item
    @author frank.bergmann@project-open.com
} {
    conf_item_id:integer,optional
    {return_url ""}
    {form_mode "edit"}
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p 1

if {"display" == $form_mode} {
    set page_title [lang::message::lookup "" intranet-confdb.Conf_Item "Configuration Item"]
} else {
    set page_title [lang::message::lookup "" intranet-confdb.New_Conf_Item "New Configuration Item"]
}
set context_bar [im_context_bar $page_title]

if {"" == $return_url} {
    switch $form_mode {
	display { set return_url [im_url_with_query] }
	edit { set return_url "/intranet-confdb/index" }
    }
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

# Options - get the value range for input fields
set conf_item_parent_options [im_conf_item_options -include_empty_p 1]
set project_options [util_memoize "im_project_options -include_empty 1 -project_status_id [im_project_status_open]" 3600]
set owner_options [util_memoize "im_employee_options 1" 3600]
set cost_center_options [util_memoize "im_cost_center_options -include_empty 0" 3600]

set action_url "/intranet-confdb/new"


set form_id "form"

ad_form \
    -name $form_id \
    -mode $form_mode \
    -action $action_url \
    -export return_url \
    -form {
	conf_item_id:key
	{conf_item_name:text(text),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Name {Conf Item Name}]"} {html {size 60}}}
	{conf_item_nr:text(text) {label "[lang::message::lookup {} intranet-core.Conf_Item_Nr {Conf Item Nr.}]"} {html {size 40}}}
	{conf_item_code:text(text),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Code {Conf Item Code}]"} {html {size 40}}}
	{conf_item_parent_id:text(select),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Parent {Parent}]"} {options $conf_item_parent_options} }
	{conf_item_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-core.Conf_Item_Type {Type}]"} {custom {category_type "Intranet Conf Item Type" translate_p 1 include_empty_p 0} } }
	{conf_item_status_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-core.Conf_Item_Status {Status}]"} {custom {category_type "Intranet Conf Item Status" translate_p 1 include_empty_p 0}} }
    	{conf_item_project_id:text(select),optional {
		label "[lang::message::lookup {} intranet-confdb.Project {Project}]"
	} {options $project_options }}
    	{conf_item_owner_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Owner {Owner}]"} {options $owner_options }}
    	{conf_item_cost_center_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Cost_Center {Department}]"} {options $cost_center_options }}
	{description:text(textarea),optional {label Description} {html {cols 40} {rows 8} }}
	{note:text(textarea),optional {label Note} {html {cols 40} {rows 8} }}
    }


if {![info exists conf_item_type_id]} { set conf_item_type_id ""}
set field_cnt [im_dynfield::append_attributes_to_form \
    -form_display_mode $form_mode \
    -object_subtype_id $conf_item_type_id \
    -object_type "im_conf_item" \
    -form_id $form_id \
    -object_id $conf_item_id \
]


ad_form -extend -name $form_id \
    -select_query {
	select	*
	from	im_conf_items
	where	conf_item_id = :conf_item_id
    } -new_data {
	if {![info exists conf_item_name] || "" == $conf_item_name} {
	    set conf_item_name $conf_item_nr
	}
	set conf_item_new_sql "
		select im_conf_item__new(
			:conf_item_id,
			'im_conf_item',
			now(),
			:current_user_id,
			'[ad_conn peeraddr]',
			null,
			:conf_item_name,
			:conf_item_nr,
			:conf_item_parent_id,
			:conf_item_type_id,
			:conf_item_status_id
		)
	"
	set exists_p [db_string exists "select count(*) from im_conf_items where conf_item_id = :conf_item_id"]
	if {!$exists_p} { db_string new $conf_item_new_sql }
	db_dml update [im_conf_item_update_sql -include_dynfields_p 1]
	if {"" != $conf_item_project_id} {
	    im_conf_item_new_project_rel -project_id $conf_item_project_id -conf_item_id $conf_item_id
	}

    } -edit_data {

	if {![info exists conf_item_name] || "" == $conf_item_name} {
	    set conf_item_name $conf_item_nr
	}
	db_dml update [im_conf_item_update_sql -include_dynfields_p 1]
	if {"" != $conf_item_project_id} {
	    im_conf_item_new_project_rel -project_id $conf_item_project_id -conf_item_id $conf_item_id
	}

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }



# ---------------------------------------------------------------
# Associated Projects
# ---------------------------------------------------------------
#	"[lang::message::lookup {} intranet-confdb.Assoc_a_new_project "Associate a project with this Configuration Item"]"

set bulk_action_list ""
lappend bulk_actions_list "[lang::message::lookup "" intranet-confdb.Delete "Delete"]" "conf-item-del" "[lang::message::lookup "" intranet-confdb.Remove_checked_items "Remove Checked Items"]"
if {![info exists conf_item_id]} { set conf_item_id 0}

set assoc_action [lang::message::lookup {} intranet-confdb.Assoc_a_new_project {Associate a new project}]

list::create \
    -name assoc_projects \
    -multirow assoc_projects_lines \
    -key project_id \
    -row_pretty_plural "[lang::message::lookup {} intranet-confdb.Assoc_Projects "Associated Projects"]" \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { object_id } \
    -actions [list \
	"Associate with new project" \
	"/intranet-confdb/new?conf_item_id=$conf_item_id" \
	"" \
    ] \
    -elements {
	conf_item_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('conf_items_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@assoc_projects_lines.conf_item_chk;noquote@
	    }
	}
	project_name {
	    label "[lang::message::lookup {} intranet-confdb.Project_Name {Project Name}]"
	    link_url_eval {[export_vars -base "/intranet/projects/view" {project_id}]}
	}
    }


set assoc_projects_sql "
	select	p.*
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id
		and r.object_id_two = :conf_item_id
"

db_multirow -extend { conf_item_chk project_url } assoc_projects_lines assoc_projects $assoc_projects_sql {
    set project_url ""
    set conf_item_chk "<input type=\"checkbox\" 
				name=\"conf_item_id\" 
				value=\"$conf_item_id\" 
				id=\"conf_items_list,$conf_item_id\">"
}


# ---------------------------------------------------------------
# Show dumb tables
# ---------------------------------------------------------------

set hardware_id [db_string hardware_id "select ocs_id from im_conf_items where conf_item_id = :conf_item_id" -default 0]
set result ""

if {[db_table_exists "ocs_hardware"]} {
append result [im_generic_table_component -table_name "ocs_drives" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_monitors" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_inputs" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_memories" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_modems" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_printers" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_sounds" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_storages" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_videos" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_bios" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_slots" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id pshare}]
append result [im_generic_table_component -table_name "ocs_ports" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_controllers" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
append result [im_generic_table_component -table_name "ocs_softwares" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]

# append result [im_generic_table_component -table_name "ocs_registry" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
# append result [im_generic_table_component -table_name "ocs_devices" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
# append result [im_generic_table_component -table_name "ocs_locks" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]
# append result [im_generic_table_component -table_name "ocs_network_devices" -select_column "hardware_id" -select_value $hardware_id -exclude_columns {id hardware_id}]

}


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

ad_return_template


