# /packages/intranet-cost/www/new.tcl
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
    { rep_cost_id:integer,optional }
    { return_url "/intranet-cost/rep-costs/index"}
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "<#_ Edit Repeating Cost#>"
set context [im_context_bar $page_title]
set today [db_string birthday_today "select sysdate from dual"]
set internal_id [im_company_internal]

if {![im_permission $user_id view_costs]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-cost/rep-costs/new"
set focus "cost.var_name"

# ------------------------------------------------------------------
# Get everything about the cost
# ------------------------------------------------------------------

if {![exists_and_not_null rep_cost_id]} {
    # New variable: setup some reasonable defaults

    set page_title "<#_ New Repeating Cost Item#>"
    set context [im_context_bar $page_title]
    set effective_date [db_string get_today "select sysdate from dual"]
    set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultProviderBillPaymentDays" "" 60]
    set customer_id [im_company_internal]
    set cost_status_id [im_cost_status_created]
    set amount 0
    set vat 0
    set tax 0

    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set form_mode "edit"
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set project_options [im_project_options]
set customer_options [im_company_options -include_empty_p 0 -status "Active" -type "CustOrIntl"]
set provider_options [im_company_options -include_empty_p 0 -status "Active" -type "Provider"]
set cost_type_options [im_cost_type_options]
set cost_status_options [im_cost_status_options]
set investment_options [im_investment_options]
set template_options [im_cost_template_options]
set currency_options [im_currency_options]

set cost_name_label [_ intranet-cost.Name]
set project_label [_ intranet-cost.Project]
set customer_label [_ intranet-cost.Customer]
set wp_label [_ intranet-cost.Who_pays]
set provider_label [_ intranet-cost.Provider]
set wg_label [_ intranet-cost.Who_gets_the_money]
set type_label [lang::message::lookup "" intranet-cost.Type "Type"]
set status_label [_ intranet-cost.Status]
set investment_label [_ intranet-cost.Investment]
set amount_label [_ intranet-cost.Amount]
set currency_label [_ intranet-cost.Currency]
set vat_label [_ intranet-cost.VAT]
set tax_label [_ intranet-cost.TAX]
set desc_label [_ intranet-cost.Description]
set note_label [_ intranet-cost.Note]
ad_form \
    -name cost \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	rep_cost_id:key
	{cost_name:text(text) {label $cost_name_label} {html {size 40}}}
	{project_id:text(select),optional {label $project_label} {options $project_options} }
	{customer_id:text(select) {label "$customer_label<br><small>($wp_label)</small>"} {options $customer_options} }
	{provider_id:text(select) {label "$provider_label<br><small>($wg_label)</small>"} {options $provider_options} }

	{cost_type_id:text(select) {label $type_label} {options $cost_type_options} }
	{cost_status_id:text(select) {label $status_label} {options $cost_status_options} }
	{investment_id:text(select),optional {label $investment_label} {options $investment_options} }

	{amount:text(text) {label $amount_label} {html {size 20}} }
	{currency:text(select) {label $currency_label} {options $currency_options} }

	{vat:text(text) {label $vat_label} {html {size 20}} }
	{tax:text(text) {label $tax_label} {html {size 20}} }

        {payment_days:text(hidden),optional }
        {template_id:text(hidden),optional }
        {effective_date:text(hidden),optional }
        {cause_object_id:text(hidden),optional }

	{description:text(textarea),nospell,optional {label $desc_label} {html {rows 5 cols 40}}}
	{note:text(textarea),nospell,optional {label $note_label} {html {rows 5 cols 40}}}
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select
		cr.start_date,
		cr.end_date,
		ci.*,
		im_category_from_id(ci.cost_status_id) as cost_status
	from	
		im_costs ci,
		im_repeating_costs cr
	where
		cr.rep_cost_id = :rep_cost_id
		and ci.cost_id = cr.rep_cost_id

} -new_data {

    # find start_block for start-block
    set start_block [db_string temp_start_block_statement "
	select	max(start_block) 
	from	im_start_months
	where	start_block <= :effective_date
    "]

    db_dml cost_insert "
declare
	v_cost_id	integer;
begin
        v_cost_id := im_cost.new (
                cost_id         => :rep_cost_id,
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
                cause_object_id		= :cause_object_id,
		start_block		= :start_block
        where
                cost_id = :rep_cost_id
    "


} -edit_data {

    # find start_block for start-block
    set start_block [db_string temp_start_block_statement "
	select	max(start_block) 
	from	im_start_months
	where	start_block <= :effective_date
    "]

    set exists [db_string exists_cost "select count(*) from im_costs where cost_id=:rep_cost_id"]
    if {!$exists} {
	db_dml cost_insert "
declare
        v_cost_id       integer;
begin
        v_cost_id := im_cost.new (
                cost_id         => :rep_cost_id,
                creation_user   => :user_id,
                creation_ip     => '[ad_conn peeraddr]',
                cost_name       => :cost_name,
                project_id      => :project_id,
                customer_id     => :customer_id,
                provider_id     => :provider_id,
                cost_status_id  => :cost_status_id,
                cost_type_id    => :cost_type_id,
                template_id     => :template_id,
                effective_date  => :effective_date,
                payment_days    => :payment_days,
                amount          => :amount,
                currency        => :currency,
                vat             => :vat,
                tax             => :tax,
                description     => :description,
                note            => :note
        );
end;"
    }

    db_dml cost_update "
	update  im_costs set
                cost_name       	= :cost_name,
		project_id		= :project_id,
                customer_id     	= :customer_id,
                provider_id     	= :provider_id,
                cost_status_id  	= :cost_status_id,
                cost_type_id    	= :cost_type_id,
                template_id     	= :template_id,
                effective_date  	= :effective_date,
		start_block		= :start_block,
                payment_days    	= :payment_days,
		amount			= :amount,
                currency        	= :currency,
                vat             	= :vat,
                tax             	= :tax,
                cause_object_id		= :cause_object_id,
                description     	= :description,
                note            	= :note
	where
		cost_id = :rep_cost_id
"
} -on_submit {

	ns_log Notice "new: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

