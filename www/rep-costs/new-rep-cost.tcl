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
    rep_cost_id:integer
    start_block
    { return_url "/intranet-hr/index"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "<#_ Create Employee Cost Item#>"
set context [im_context_bar $page_title]
set today [db_string birthday_today "select to_char(sysdate,'YYYY-MM-DD') from dual"]

if {![im_permission $user_id view_costs]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-cost/rep-costs/new-rep-cost"
set focus "cost.var_name"

# ------------------------------------------------------------------
# Setup Cost Item Variables
# ------------------------------------------------------------------

set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultProviderBillPaymentDays" "" 60]
set vat 0
set tax 0

set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set form_mode "edit"


set org_start_block $start_block

db_1row get_rep_cost_info "
select	
	cr.start_date,
	cr.end_date,
	ci.*
from
	im_repeating_costs cr,
	im_costs ci
where
	cr.rep_cost_id = :rep_cost_id
	and cr.rep_cost_id = ci.cost_id
"

if {"" == $start_block} { set start_block $org_start_block }

# ad_return_complaint 1 "<li>start_block = $start_block"

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

append cost_name " - $start_block"
set cost_id [im_new_object_id]
set cause_object_id $rep_cost_id
set effective_date $start_block
if {![exists_and_not_null payment_days]} { set payment_days 0 }
if {![exists_and_not_null tax]} { set tax 0 }
if {![exists_and_not_null vat]} { set vat 0 }

set project_options [im_project_options]
set customer_options [im_customer_options]
set provider_options [im_provider_options]
set cost_type_options [im_cost_type_options]
set cost_status_options [im_cost_status_options]
set investment_options [im_investment_options]
set template_options [im_cost_template_options]
set currency_options [im_currency_options]

set name_label "<#_ Name#>"
set project_label "<#_ Project#>"
set customer_label "<#_ Customer#>"
set wp_label "<#_ Who pays?#>"
set provider_label "<# Provider#>"
set wg_label "<#_ Who gets the money?#>"
set type_label "[intranet-cost.Type]"
set status_label "<#_ Status#>"
set investement_label "<#_ Investment#>"
set effective_date_label "<#_ Effective Date#>"
set start_block_label "<#_ Start Block#>"
set amount_label "<#_ Amount#>"
set currency_label "<#_ Currency#>"
set vat_label "<#_ VAT#>"
set tax_label "<#_ TAX#>"
set cause_object_label "<#_ Cause Object#>"
set desc_label "<#_ Description#>"
set note_label "<#_ Note#>"

ad_form \
    -name cost \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {

	{cost_name:text(text) {label $name_label} {html {size 40}}}
	{project_id:text(select),optional {label $project_label} {options $project_options} }
	{customer_id:text(select),optional {label "$customer_label<br><small>($wp_label)</small>"} {options $customer_options} }
	{provider_id:text(select),optional {label "$provider_label<br><small>($wg_label)</small>"} {options $provider_options} }

	{cost_type_id:text(select) {label $type_label} {options $cost_type_options} }
	{cost_status_id:text(select) {label $status_label} {options $cost_status_options} }
	{investment_id:text(select),optional {label $investment_label} {options $investment_options} }
	{effective_date:text(text) {label $effective_date_label} {html {size 20}} }
	{start_block:text(text) {label $start_block_label} {html {size 20}}}

	{amount:text(text) {label $amount_label} {html {size 20}} }
	{currency:text(select) {label $curruncy_label} {options $currency_options} }

	{vat:text(text),optional {label $vat_label} {html {size 20}} }
	{tax:text(text),optional {label $tax_label} {html {size 20}} }

	{payment_days:text(hidden) }
	{cause_object_id:text(text) {label $cause_object_label} {html {size 20}}}
	{rep_cost_id:text(hidden) }

	{description:text(textarea),nospell,optional {label $desc_label} {html {rows 5 cols 40}}}
	{note:text(textarea),nospell,optional {label $note_label} {html {rows 5 cols 40}}}
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select	ci.*,
		im_category_from_id(ci.cost_status_id) as cost_status
	from	im_costs ci
	where	ci.cost_id = :cost_id

} -after_submit {

    set cost_id [im_cost::new \
	-cost_name $cost_name \
	-cost_type_id $cost_type_id \
	-cost_status_id $cost_status_id \
    ]

    db_dml cost_update "
        update  im_costs set
                cause_object_id	= :cause_object_id,
                vat = :vat,
                tax = :tax,
		project_id = :project_id,
                customer_id = :customer_id,
                provider_id = :provider_id,
                effective_date = :effective_date,
		start_block = :start_block,
                payment_days = :payment_days,
		amount = :amount,
                currency = :currency,
                description = :description,
                note = :note
 	where
		cost_id = :cost_id
    "

	ad_returnredirect $return_url
	ad_script_abort
}

