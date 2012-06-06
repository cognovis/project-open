# /packages/intranet-sla-management/www/new.tcl
#
# Copyright (C) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show, create and edit a single SLA parameter
    @author frank.bergmann@project-open.com
} {
    param_id:integer,optional
    {param_sla_id:integer "" }
    {param_name "" }
    { plugin_id:integer "" }
    {return_url ""}
    {form_mode "edit"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-sla-management.SLA_Parameter "SLA Parameter"]
if {[info exists param_id]} { set page_title [lang::message::lookup "" intranet-sla-management.SLA_parameter SLA_parameter] }
set context_bar [im_context_bar $page_title]
set context [list $page_title]
set focus "ticket.var_name"
if {"" == $return_url} { set return_url [im_url_with_query] }

# We can determine the ID of the "container object" from the
# SLA parameter data, if the param_id is there (viewing an existing param).
if {[info exists param_id] && "" == $param_sla_id} {
    set param_sla_id [db_string oid "select param_sla_id from im_sla_parameters where param_id = :param_id" -default ""]
}

set enable_master_p 1

# Show the ADP component plugins?
set show_components_p 1
if {"edit" == $form_mode} { set show_components_p 0 }

set edit_param_status_p [im_permission $current_user_id edit_param_status]




# ---------------------------------------------------------------
# Delete action
# ---------------------------------------------------------------

set button_pressed [template::form get_action form]
if {"delete" == $button_pressed} {
    if {[catch {
	db_transaction {
	    set rel_ids [db_list sla_param_rels "
		select pri.rel_id
		from acs_rels r, im_sla_param_indicator_rels pir
		where r.rel_id = pir.rel_id and object_id_one = :param_id
	    "]
	    foreach rel_id $rel_ids {
		db_dml del_rels "select im_sla_param_indicator_rel__delete(:rel_id)"
	    }
	    db_dml del_param "select im_sla_parameter__delete(:param_id)"
	}
    } err_msg]} {
	ad_return_complaint 1 "<b>Error deleting Parameter</b>:<p>
	<pre>$err_msg</pre>"
	ad_script_abort
    }
    ad_returnredirect $return_url

}

# ---------------------------------------------------------------
# Create the Form
# ---------------------------------------------------------------

set form_id "form"
ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "param_sla_id return_url" \
    -form {
	param_id:key
	{param_name:text(text) {label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Name Name]"}}
	{param_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Type Type]"} {custom {category_type "Intranet SLA Parameter Type" translate_p 1 package_key intranet-sla-management include_empty_p 0}} }
	{param_note:text(textarea),optional {label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Note Note]"} {html {cols 40} {rows 8}} }
    }



# ---------------------------------------------
# Add DynFields to the form
# ---------------------------------------------

set dynfield_param_type_id ""
if {[info exists param_type_id]} { set dynfield_param_type_id $param_type_id}

set dynfield_param_id ""
if {[info exists param_id]} { set dynfield_param_id $param_id }

# Add DynFields to the form
im_dynfield::append_attributes_to_form \
    -form_display_mode $form_mode \
    -object_subtype_id $dynfield_param_type_id \
    -object_type "im_sla_parameter" \
    -form_id $form_id \
    -object_id $dynfield_param_id


# ------------------------------------------------------------------
# Param Action
# ------------------------------------------------------------------

set pid [value_if_exists param_id]
set param_action_html "
<form action=/intranet-sla-management/parameters/action name=param_action>
[export_form_vars return_url pid]
<input type=submit value='[lang::message::lookup "" intranet-sla-management.Action "Action"]'>
[im_category_select \
     -translate_p 1 \
     -package_key "intranet-sla-management" \
     -plain_p 1 \
     -include_empty_p 1 \
     -include_empty_name "" \
     "Intranet Param Action" \
     action_id \
     ]
</form>
"

if {!$edit_param_status_p} { set param_action_html "" }





# ---------------------------------------------------------------
# Define Form Actions
# ---------------------------------------------------------------

ad_form -extend -name $form_id \
    -select_query {

	select	*
	from	im_sla_parameters
	where	param_id = :param_id

    } -new_data {

        set param_note [string trim $param_note]
        set duplicate_param_sql "
                select  count(*)
                from    im_sla_parameters
                where   param_sla_id = :param_sla_id and param_name = :param_name
        "
        if {[db_string dup $duplicate_param_sql]} {
            ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-sla-management.Duplicate_parameter "Duplicate parameter"]</b>:<br>
            [lang::message::lookup "" intranet-sla-management.Duplicate_parameter_msg "
	    	There is already a parameter with the same name for the same SLA.
	    "]"
	    ad_script_abort
        }

	set param_id [db_exec_plsql create_note "
		SELECT im_sla_parameter__new(
			:param_id,
			'im_sla_parameter',
			now(),
			:current_user_id,
			'[ad_conn peeraddr]',
			null,

			:param_name,
			:param_sla_id,
			:param_type_id,
			[im_sla_parameter_status_active],
			:param_note
		)
        "]

        im_dynfield::attribute_store \
            -object_type "im_sla_parameter" \
            -object_id $param_id \
            -form_id $form_id

    } -edit_data {

        set note [string trim $param_note]
	db_dml edit_note "
		update im_sla_parameters set 
			param_name = :param_name,
			param_sla_id = :param_sla_id,
			param_type_id = :param_type_id,
			param_note = :param_note
		where param_id = :param_id
	"
        im_dynfield::attribute_store \
            -object_type "im_sla_parameter" \
            -object_id $param_id \
            -form_id $form_id

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


# ---------------------------------------------------------------
# Param Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
if {[info exists param_id]} { ns_set put $bind_vars param_id $param_id }
if {![info exists param_id]} { set param_id "" }

set param_parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='helpdesk'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet-sla-management/new?param_id=$param_id" \
    -plugin_url "/intranet-sla-management/new" \
    $param_parent_menu_id \
    $bind_vars "" "pagedesriptionbar" "helpdesk_summary" \
]


# ----------------------------------------------------------
# Navbars
# ----------------------------------------------------------

# Compile and execute the formtemplate if advanced filtering is enabled.
# eval [template::adp_compile -string {<formtemplate id="param_filter"></formtemplate>}]
# set form_html $__adp_output

set admin_html ""

if {1} {
    append left_navbar_html "
            <div class='filter-block'>
                <div class='filter-title'>
                    [lang::message::lookup "" intranet-helpdesk.Admin_Params "Admin Params"]
                </div>
                $admin_html
            </div>
            <hr/>
    "
}
