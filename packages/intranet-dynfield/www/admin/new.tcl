# /packages/intranet-core/www/admin/menus/new.tcl
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
    menu_id:integer,optional
    return_url
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

set action_url "/intranet/admin/menus/new"
set focus "menu.var_name"
set page_title "New Menu"
set context $page_title

if {![info exists menu_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set parent_options [im_menu_parent_options]

ad_form \
    -name menu \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	menu_id:key
	{name:text(text) {label Name} {html {size 40}}}
	{package_name:text(text) {label Package} {html {size 30}}}
	{label:text(text) {label Label} {html {size 30}}}
	{url:text(text) {label URL} {html {size 100}}}
	{sort_order:text(text) {label "Sort Order"} {html {size 10}}}
	{parent_menu_id:text(select) {label "Parent Menu"} {options $parent_options} }
	{visible_tcl:text(text),optional {label "Visible TCL"} {html {size 100}}}
    }


ad_form -extend -name menu -on_request {
    # Populate elements from local variables

} -select_query {

	select	m.*
	from	im_menus m
	where	m.menu_id = :menu_id

} -new_data {

    db_exec_plsql menu_insert {}

} -edit_data {

    db_dml menu_update "
	update im_menus set
	        package_name    = :package_name,
	        label           = :label,
	        name            = :name,
	        url             = :url,
	        sort_order      = :sort_order,
	        parent_menu_id  = :parent_menu_id,
	        visible_tcl	= :visible_tcl
	where
		menu_id = :menu_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

