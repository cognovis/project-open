# /packages/intranet-cost/www/cost-centers/new.tcl
#
# Copyright (C) 2003-2004 Project/Open
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
	ad_return_complaint 1 "We didn't find cost center \#$cost_center_id."
	return
    }
}

set context [im_context_bar $page_title]

if {![info exists cost_center_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set cost_center_parent_options [im_cost_center_options]
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
	{parent_id:text(select) {label "Parent Cost Center"} {options $cost_center_parent_options} }
	{manager_id:text(select) {label Manager} {options $manager_options }}
	{description:text(textarea),optional {label Description} {html {cols 40}}}
	{note:text(hidden),optional}
    }


ad_form -extend -name cost_center -on_request {
    # Populate elements from local variables

} -select_query {

	select	cc.*
	from	im_cost_centers cc
	where	cc.cost_center_id = :cost_center_id

} -new_data {

    db_exec_plsql cost_center_insert {}

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
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

