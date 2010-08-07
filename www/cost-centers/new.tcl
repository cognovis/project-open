# /packages/intranet-cost/www/cost-centers/new.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new dynamic value or edit an existing one.

    @param form_mode edit or display

    @author frank.bergmann@project-open.com
} {
    cost_center_id:integer,optional
    {return_url "/intranet-cost/cost-centers/index"}
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-cost/cost-centers/new"
set focus "cost_center.var_name"
set page_title "New Cost Center"
if {[info exists cost_center_id]} {
    set cc_name [db_string cc_name "select cost_center_name from im_cost_centers where cost_center_id = :cost_center_id" -default ""]
    set page_title "Cost Center '$cc_name'"

    if {"" == $cc_name} {
#	ad_return_complaint 1 "We didn't find cost center \#$cost_center_id."
#	return

	set cc_name "New Cost Center"
    }
}

set context [im_context_bar $page_title]

if {![info exists cost_center_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set cost_center_parent_options [im_cost_center_options -include_empty 1]
set cost_center_type_options [im_cost_center_type_options]
set cost_center_status_options [im_cost_center_status_options]
set manager_options [im_employee_options]

ad_form \
    -name cost_center \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	cost_center_id:key
	{cost_center_name:text(text) {label Name} {html {size 40}}}
	{cost_center_label:text(text) {label Label} {html {size 30}}}
	{cost_center_code:text(text) {label Code} {html {size 10}}}
	{cost_center_type_id:text(select) {label "Type"} {options $cost_center_type_options} }
	{cost_center_status_id:text(select) {label "Status"} {options $cost_center_status_options} }
	{department_p:text(radio) {label Department} {options {{True t} {False f}}} }
	{parent_id:text(select),optional {label "Parent Cost Center"} {options $cost_center_parent_options} }
	{manager_id:text(select),optional {label Manager} {options $manager_options }}
	{description:text(textarea),optional {label Description} {html {cols 40}}}
	{note:text(hidden),optional}
    }

# Fix for problem changing to "edit" form_mode
set form_action [template::form::get_action "cost_center"]
if {"" != $form_action} { set form_mode "edit" }

# Add DynFields to the form
set my_cost_center_id 0
if {[info exists cost_center_id]} { set my_cost_center_id $cost_center_id }
im_dynfield::append_attributes_to_form \
    -object_type "im_cost_center" \
    -form_id cost_center \
    -object_id $my_cost_center_id \
    -form_display_mode $form_mode



ad_form -extend -name cost_center -on_request {
    # Populate elements from local variables

} -select_query {

	select	cc.*
	from	im_cost_centers cc
	where	cc.cost_center_id = :cost_center_id

} -new_data {

    set cost_center_id [db_string cost_center_insert {}]
    db_dml cost_center_context_update {}

    im_dynfield::attribute_store \
	-object_type "im_cost_center" \
	-object_id $cost_center_id \
	-form_id cost_center
    
    # Write Audit Trail
    im_audit -object_id $cost_center_id -action create

} -edit_data {

    db_dml cost_center_update "
	update im_cost_centers set
		cost_center_name	= :cost_center_name,
		cost_center_label	= :cost_center_label,
		cost_center_code 	= :cost_center_code,
		cost_center_type_id	= :cost_center_type_id,
		cost_center_status_id	= :cost_center_status_id,
		department_p		= :department_p,
		parent_id		= :parent_id,
		manager_id		= :manager_id,
		description		= :description
	where
		cost_center_id = :cost_center_id
    "

    db_dml cost_center_context_update {}

    im_dynfield::attribute_store \
	-object_type "im_cost_center" \
	-object_id $cost_center_id \
	-form_id cost_center
    
    # Write Audit Trail
    im_audit -object_id $cost_center_id -action update

} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

