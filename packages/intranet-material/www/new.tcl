# /packages/intranet-material/www/new.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    material_id:integer,optional
    return_url
    edit_p:optional
    message:optional
    { form_mode "edit" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set action_url "/intranet-material/new"
set focus "material.var_name"
set page_title "New Material"
set context [im_context_bar $page_title]

set user_id [ad_maybe_redirect_for_registration]
if {![info exists material_id]} { set form_mode "edit" }

if {"display" == $form_mode} {
    if {![im_permission $user_id view_materials]} {
	ad_return_complaint 1 "You have insufficient privileges to see materials"
	return
    }
} else {
    if {![im_permission $user_id add_materials]} {
	ad_return_complaint 1 "You have insufficient privileges to add/modify materials"
	return
    }
}


set button_pressed [template::form get_action material]
if {"delete" == $button_pressed} {

    if {[catch {
	db_transaction {
	    db_dml del_prices "delete from im_timesheet_prices where material_id=:material_id"
	    db_exec_plsql material_delete {}
	}
    } err_msg]} {

	set task_names [db_list mat_tasks "select acs_object__name(task_id) from im_timesheet_tasks where material_id = :material_id"]
	set price_names [db_list_of_lists prices "select acs_object__name(company_id), im_category_from_id(task_type_id), * from im_timesheet_prices where material_id = :material_id"]

	ad_return_complaint 1 "<b>Error deleting Material</b>:<p>
	This error is probably due to the fact there there are still 
	'Timesheet Tasks' referencing this material:<p>
	Timesheet Tasks:<br>
	<pre>[join $task_names "\n>"]</pre><p>
	Timesheet Prices:<br>
	<pre>[join $price_names "\n>"]</pre><p>
	Please change these items to remove the material you want to delete\n"
	return
    }
    ad_returnredirect $return_url

}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set type_options [im_material_type_options -include_empty 0]
set status_options [im_material_status_options -include_empty 0]
set uom_options [im_cost_uom_options 0]
set billable_options [list [list [_ intranet-core.Yes] t] [list [_ intranet-core.No] f]]

set actions [list {"Edit" edit} ]
if {[im_permission $user_id add_materials]} {
    lappend actions {"Delete" delete}
}

ad_form \
    -name material \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	material_id:key
	{material_nr:text(text) {label Nr} {html {size 30}}}
	{material_name:text(text) {label Name} {html {size 50}}}
	{material_type_id:text(select) {label "Type"} {options $type_options} }
	{material_status_id:text(select) {label "Status"} {options $status_options} }
	{material_uom_id:text(select) {label "UoM<br>(Unit of Measure)"} {options $uom_options} }
	{material_billable_p:text(radio) {label "Billable?"} {options $billable_options} }
	{description:text(textarea),optional {label Description} {html {cols 40}}}
    }


im_dynfield::append_attributes_to_form \
    -object_type "im_material" \
    -object_subtype_id [im_opt_val material_type_id] \
    -form_id "material" \
    -form_display_mode $form_mode


ad_form -extend -name material -on_request {
    # Populate elements from local variables

} -select_query {

	select	m.*
	from	im_materials m
	where	m.material_id = :material_id

} -new_data {

    db_exec_plsql material_insert {}

    im_dynfield::attribute_store \
        -object_type "im_material" \
        -object_id $material_id \
        -form_id "material"

    # Write Audit Trail
    im_audit -object_type im_material -object_id $material_id -action after_create -status_id $material_status_id -type_id $material_type_id

} -edit_data {

    db_dml material_update {}

    im_dynfield::attribute_store \
        -object_type "im_material" \
        -object_id $material_id \
        -form_id "material"

    # Write Audit Trail
    im_audit -object_type im_material -object_id $material_id -action after_update -status_id $material_status_id -type_id $material_type_id

} -on_submit {

	ns_log Notice "new: on_submit"

} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

