# /packages/intranet-cost/www/new.tcl
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
    { item_id:integer 0 }
    { return_url "/intranet-costs/index"}
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

if {![im_permission $user_id view_cost_items]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-cost/new"
set focus "cost.var_name"


# ------------------------------------------------------------------
# Get everything about the cost
# ------------------------------------------------------------------

if {0 == $item_id} {
    # New variable: setup some reasonable defaults

    set page_title "New Cost Item"
    set context [ad_context_bar $page_title]


} else {
    # Existing Item: Get everything

    set page_title "Edit Cost"
    set context [ad_context_bar $page_title]

    set sql "
select
	    ci.*
from
	    im_cost_items ci
where
	    ci.item_id = :item_id
"
    db_1row get_cost $sql
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set project_options [db_list_of_lists project_options "
select project_name, project_id 
from im_projects
"]

set customer_options [db_list_of_lists customer_options "
select customer_name, customer_id 
from im_customers
"]

set provider_options [db_list_of_lists provider_options "
select customer_name, customer_id 
from im_customers
"]

set item_type_options [db_list_of_lists item_type_options "
select item_type, item_type_id 
from im_cost_item_type
"]

set item_status_options [db_list_of_lists item_status_options "
select item_status, item_status_id from im_cost_item_status
"]

set template_options [db_list_of_lists template_options "
select category, category_id
from im_categories
where category_type = 'Intranet Invoice Template'
"]

set investment_options [db_list_of_lists investment_options "
select name, investment_id
from im_investments
"]

set currency_options [db_list_of_lists currency_options "
select iso, iso
from currency_codes
"]




ad_form \
    -name cost \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	item_id:key
	{item_name:text(text) {label Name} {html {size 40}}}
	{project_id:text(select) {label Project} {options $project_options} }
	{customer_id:text(select) {label Customer} {options $customer_options} }
	{provider_id:text(select) {label Provider} {options $provider_options} }

	{item_type_id:text(select) {label Type} {options $item_type_options} }
	{item_status_id:text(select) {label Status} {options $item_status_options} }
	{template_id:text(select) {label "Print Template"} {options $template_options} }
	{investment_id:text(select) {label Investment} {options $investment_options} }

	{effective_date:text(text) {label "Effective Date"} {html {size 20}} }
	{payment_days:text(text) {label "Payment Days"} {html {size 10}} }
	
	{amount:text(text) {label "Amount"} {html {size 20}} }
	{currency:text(select) {label "Currency"} {options $currency_options} }

	{vat:text(text) {label "VAT"} {html {size 20}} }
	{tax:text(text) {label "TAX"} {html {size 20}} }

	{description:text(textarea),optional {label "Description"} {html {rows 5 cols 40}}}
	{note:text(textarea),optional {label "Note"} {html {rows 5 cols 40}}}
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select	ci.*
	from	im_cost_items ci
	where	ci.item_id = :item_id

} -new_data {

    db_dml cost_insert "
	insert into im_cost_vars (
		item_id,
		var_object_type,
		package_name,
		var_name,
		var_type,
		var_type_category,
		include_null_category_p,
		var_type_sql,
		category_id,
		sort_order,
		editable_p
	) values (
		:item_id,
		:var_object_type,
		:package_name,
		:var_name,
		:var_type,
		:var_type_category,
		:include_null_category_p,
		:var_type_sql,
		:category_id,
		:sort_order,
		:editable_p
	)
"

} -edit_data {

    db_dml cost_update "
	update  im_cost_vars set
		var_object_type		= :var_object_type,
		package_name		= :package_name,
		var_name		= :var_name,
		var_type		= :var_type,
		var_type_category	= :var_type_category,
		include_null_category_p	= :include_null_category_p,
		var_type_sql		= :var_type_sql,
		category_id		= :category_id,
		sort_order		= :sort_order,
		editable_p		= :editable_p
	where
		item_id = :item_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

