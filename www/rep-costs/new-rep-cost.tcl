# /packages/intranet-hr/www/new-repeated-item.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new cost item from a repeating cost such
    as employee salaries, rent or other fixed costs

    @author frank.bergmann@project-open.com
} {
    { rep_cost_id:integer }
    { start_block }
    { return_url "/intranet-hr/index"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "Create Employee Cost Item"
set context [ad_context_bar $page_title]

if {![im_permission $user_id view_cost_items]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-cost/costs/new"
set focus "cost.var_name"

# ------------------------------------------------------------------
# Create the next cost item for the given employee
# ------------------------------------------------------------------

if {![exists_and_not_null cost_id]} {
    # New variable: setup some reasonable defaults

    set page_title "New Cost Item from Repeated Cost"
    set context [ad_context_bar $page_title]
    set effective_date $start_block
    set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultProviderBillPaymentDays" "" 60]
    set vat 0
    set tax 0

    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set form_mode "edit"
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

db_1row get_rep_cost_info "
select	*
from	im_repeating_costs
where	cost_id=:rep_cost_id
"

append cost_name " - $start_block"
set cost_id [im_new_object_id]
set cause_object_id $rep_cost_id

set project_options [im_cost_project_options]
set customer_options [im_cost_customer_options]
set provider_options [im_cost_provider_options]
set cost_type_options [im_cost_type_options]
set cost_status_options [im_cost_status_options]
set investment_options [im_cost_investment_options]
set template_options [im_cost_template_options]
set currency_options [im_cost_currency_options]


ad_form \
    -name cost \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	{cost_id:text(hidden) }
	{cost_name:text(text) {label Name} {html {size 40}}}
	{project_id:text(select) {label Project} {options $project_options} }
	{customer_id:text(select) {label "Customer<br><small>(Who pays?)</small>"} {options $customer_options} }
	{provider_id:text(select) {label "Provider<br><small>(Who gets the money?)</small>"} {options $provider_options} }

	{cost_type_id:text(select) {label Type} {options $cost_type_options} }
	{cost_status_id:text(select) {label Status} {options $cost_status_options} }
	{template_id:text(select) {label "Print Template"} {options $template_options} }
	{investment_id:text(select),optional {label Investment} {options $investment_options} }

	{effective_date:text(text) {label "Effective Date"} {html {size 20}} }
	{payment_days:text(text) {label "Payment Days"} {html {size 10}} }
	
	{amount:text(text) {label "Amount"} {html {size 20}} }
	{currency:text(select) {label "Currency"} {options $currency_options} }

	{vat:text(text) {label "VAT"} {html {size 20}} }
	{tax:text(text) {label "TAX"} {html {size 20}} }

	{cause_object_id:text(hidden) }

	{description:text(textarea),nospell,optional {label "Description"} {html {rows 5 cols 40}}}
	{note:text(textarea),nospell,optional {label "Note"} {html {rows 5 cols 40}}}
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select	ci.*,
		im_category_from_id(ci.cost_status_id) as cost_status
	from	im_costs ci
	where	ci.cost_id = :cost_id

} -new_data {

    db_dml cost_insert "
declare
	v_cost_id	integer;
begin
        v_cost_id := im_cost.new (
                cost_id         => :cost_id,
                creation_user   => :user_id,
                creation_ip     => '[ad_conn peeraddr]',
                cost_name       => :cost_name,
		project_id	=> :project_id,
                customer_id     => :customer_id,
                provider_id     => :provider_id,
                cost_status_id  => :cost_status_id,
                cost_type_id    => :cost_type_id,
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

    db_dml cost_update_aux "
        update  im_costs set
                cause_object_id	= :cause_object_id
 	where
		cost_id = :cost_id
    "

} -edit_data {

    db_dml cost_update "
	update  im_costs set
                cost_name       = :cost_name,
		project_id	= :project_id,
                customer_id     = :customer_id,
                provider_id     = :provider_id,
                cost_status_id  = :cost_status_id,
                cost_type_id    = :cost_type_id,
                template_id     = :template_id,
                effective_date  = :effective_date,
                payment_days    = :payment_days,
		amount		= :amount,
                currency        = :currency,
                vat             = :vat,
                tax             = :tax,
		cause_object_id = :cause_object_id,
                description     = :description,
                note            = :note
	where
		cost_id = :cost_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

