# /packages/intranet-confdb/www/new.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show or create a new configuration item
    @author frank.bergmann@project-open.com
    @parameter view_name Set to "component" in order to show a specific component
} {
    conf_item_id:integer,optional
    {return_url ""}
    {form_mode "display"}
    {view_name ""}
}

set current_user_id [ad_maybe_redirect_for_registration]
if {[im_permission $current_user_id "add_conf_items"]} {
    ad_return_complaint 1 "You don't have sufficient permissions to create or modify tickets"
    ad_script_abort
}


set user_admin_p 1
set enable_master_p 1
set focus ""
set sub_navbar ""

if {"display" == $form_mode} {
    set page_title [lang::message::lookup "" intranet-confdb.Conf_Item "Configuration Item"]
    set show_components_p 1
} else {
    set page_title [lang::message::lookup "" intranet-confdb.New_Conf_Item "New Configuration Item"]
    set show_components_p 0
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


set form_id "conf_item"

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
	{conf_item_version:text(text),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Version {Version}]"} {html {size 40}}}

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
if {[info exists conf_item_id]} { 
    set field_cnt [im_dynfield::append_attributes_to_form \
		       -form_display_mode $form_mode \
		       -object_subtype_id $conf_item_type_id \
		       -object_type "im_conf_item" \
		       -form_id $form_id \
		       -object_id $conf_item_id \
    ]
}


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
	if {!$exists_p} { set conf_item_id [db_string new $conf_item_new_sql] }
	db_dml update [im_conf_item_update_sql -include_dynfields_p 1]
	if {"" != $conf_item_project_id} {
	    im_conf_item_new_project_rel -project_id $conf_item_project_id -conf_item_id $conf_item_id
	}

	im_dynfield::attribute_store \
	    -object_type "im_conf_item" \
	    -object_id $conf_item_id \
	    -form_id $form_id


    } -edit_data {

	if {![info exists conf_item_name] || "" == $conf_item_name} {
	    set conf_item_name $conf_item_nr
	}
	db_dml update [im_conf_item_update_sql -include_dynfields_p 1]
	if {"" != $conf_item_project_id} {
	    im_conf_item_new_project_rel -project_id $conf_item_project_id -conf_item_id $conf_item_id
	}

	im_dynfield::attribute_store \
	    -object_type "im_conf_item" \
	    -object_id $conf_item_id \
	    -form_id $form_id

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


# ---------------------------------------------------------------
# List of Sub-Items
# ---------------------------------------------------------------

set export_var_list [list]
set list_id "conf_items_list"
set bulk_actions_list [list]
set delete_conf_item_p 0
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
	conf_item_status {
	    label "[lang::message::lookup {} intranet-confdb.Conf_Item_Status Status]"
	}
    }

set conf_item_sql [im_conf_item_select_sql \
	-project_id "" \
	-type_id "" \
	-status_id "" \
	-owner_id "" \
	-cost_center_id "" \
	-treelevel "" \
	-parent_id [im_opt_val conf_item_id] \
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

set sub_item_count 0
db_multirow -extend {conf_item_chk conf_item_url indent return_url processor} conf_item_lines conf_items_lines $sql {
    incr sub_item_count
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
# Associated Tickets
# ---------------------------------------------------------------

set bulk_action_list ""
# lappend bulk_actions_list "[lang::message::lookup "" intranet-confdb.Delete "Delete"]" "conf-item-del" "[lang::message::lookup "" intranet-confdb.Remove_checked_items "Remove Checked Items"]"

list::create \
    -name assoc_tickets \
    -multirow assoc_tickets_lines \
    -key ticket_id \
    -row_pretty_plural "[lang::message::lookup {} intranet-confdb.Assoc_Tickets "Associated Tickets"]" \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { object_id } \
    -actions [list] \
    -elements {
	ticket_name {
	    label "[lang::message::lookup {} intranet-confdb.Ticket_Name {Ticket Name}]"
	    link_url_eval {[export_vars -base "/intranet/tickets/view" {ticket_id}]}
	}
    }


set assoc_tickets_sql "
	select
		t.*,
		p.*,
		p.project_name as ticket_name,
		p.project_nr as ticket_nr
	from
		im_tickets t,
		im_projects p
	where
		t.ticket_id = p.project_id and
		t.ticket_conf_item_id = :conf_item_id
"

db_multirow -extend { conf_item_chk ticket_url } assoc_tickets_lines assoc_tickets $assoc_tickets_sql {
    set ticket_url ""
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

if {[im_table_exists "ocs_hardware"]} {

	if {"" == $conf_item_type_id} { set conf_item_type_id [db_string type "select conf_item_type_id from im_conf_items where conf_item_id = :conf_item_id" -default 0]}

    if {[im_category_is_a $conf_item_type_id 11850]} {

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
}


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

ad_return_template


