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
    { item_id:integer,optional }
    { return_url "/intranet-cost/index"}
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "Edit Cost"
set context [ad_context_bar $page_title]

if {![im_permission $user_id view_cost_items]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-cost/cost-items/new"
set focus "cost.var_name"

# ------------------------------------------------------------------
# Get everything about the cost
# ------------------------------------------------------------------

if {![exists_and_not_null item_id]} {
    # New variable: setup some reasonable defaults

    set page_title "New Cost Item"
    set context [ad_context_bar $page_title]
    set effective_date [db_string get_today "select sysdate from dual"]
    set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultProviderBillPaymentDays" "" 60]
    set vat 0
    set tax 0

    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set form_mode "edit"
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
	{customer_id:text(select) {label "Customer<br><small>(Who pays?)</small>"} {options $customer_options} }
	{provider_id:text(select) {label "Provider<br><small>(Who gets the money?)</small>"} {options $provider_options} }

	{item_type_id:text(select) {label Type} {options $item_type_options} }
	{item_status_id:text(select) {label Status} {options $item_status_options} }
	{template_id:text(select) {label "Print Template"} {options $template_options} }
	{investment_id:text(select),optional {label Investment} {options $investment_options} }

	{effective_date:text(text) {label "Effective Date"} {html {size 20}} }
	{payment_days:text(text) {label "Payment Days"} {html {size 10}} }
	
	{amount:text(text) {label "Amount"} {html {size 20}} }
	{currency:text(select) {label "Currency"} {options $currency_options} }

	{vat:text(text) {label "VAT"} {html {size 20}} }
	{tax:text(text) {label "TAX"} {html {size 20}} }

	{description:text(textarea),nospell,optional {label "Description"} {html {rows 5 cols 40}}}
	{note:text(textarea),nospell,optional {label "Note"} {html {rows 5 cols 40}}}
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select	ci.*,
		im_category_from_id(ci.item_status_id) as item_status
	from	im_cost_items ci
	where	ci.item_id = :item_id

} -new_data {

    db_dml cost_insert "
declare
	v_item_id	integer;
begin
        v_item_id := im_cost_item.new (
                item_id         => :item_id,
                creation_user   => :user_id,
                creation_ip     => '[ad_conn peeraddr]',
                item_name       => :item_name,
		project_id	=> :project_id,
                customer_id     => :customer_id,
                provider_id     => :provider_id,
                item_status_id  => :item_status_id,
                item_type_id    => :item_type_id,
                template_id     => :template_id,
                effective_date  => :effective_date,
                payment_days    => :payment_days,
		amount		=> :amount,
                currency        => :currency,
                vat             => :vat,
                tax             => :tax,
                description     => :description,
                note            => :note
        );
end;"

} -edit_data {

    db_dml cost_update "
	update  im_cost_items set
                item_name       = :item_name,
		project_id	= :project_id,
                customer_id     = :customer_id,
                provider_id     = :provider_id,
                item_status_id  = :item_status_id,
                item_type_id    = :item_type_id,
                template_id     = :template_id,
                effective_date  = :effective_date,
                payment_days    = :payment_days,
		amount		= :amount,
                currency        = :currency,
                vat             = :vat,
                tax             = :tax,
                description     = :description,
                note            = :note
	where
		item_id = :item_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

