# /packages/intranet-timesheet2-invoices/www/price-lists/new.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create or edit an entry in the price list
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    price_id:integer,optional
    company_id:integer
    {return_url "/intranet/companies/"}
    { currency "" }
    edit_p:optional
    message:optional
    { form_mode "edit" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

set action_url "new"
set focus "price.var_name"
set page_title "[_ intranet-timesheet2-invoices.New_Price]"
set context [im_context_bar $page_title]


if {"" == $currency} {
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set uom_options [db_list_of_lists uom_options "
select category, category_id
from im_categories
where category_type = 'Intranet UoM'
"]

set task_type_options [db_list_of_lists uom_options "
select category, category_id
from im_categories
where category_type = 'Intranet Project Type'
"]
set task_type_options [linsert $task_type_options 0 [list "" ""]]

set language_options [db_list_of_lists uom_options "
select category, category_id
from im_categories
where category_type = 'Intranet Translation Language'
"]
set language_options [linsert $language_options 0 [list "" ""]]

set material_options [db_list_of_lists uom_options "
select category, category_id
from im_categories
where category_type = 'Intranet Translation Subject Area'
"]
set material_options [linsert $material_options 0 [list "" ""]]

set include_empty 0
set currency_options [im_currency_options $include_empty]

ad_form \
    -name price \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	price_id:key(im_trans_prices_seq)
	{company_id:text(hidden)}
	{uom_id:text(select) {label "[_ intranet-timesheet2-invoices.Unit_of_Measure]"} {options $uom_options} }
	{task_type_id:text(select),optional {label "[_ intranet-timesheet2-invoices.Task_Type]"} {options $task_type_options} }
	{material_id:text(select),optional {label "[_ intranet-timesheet2-invoices.Material]"} {options $material_options} }
	{amount:text(text) {label "[_ intranet-timesheet2-invoices.Amount]"} {html {size 10}}}
	{currency:text(select) {label "[_ intranet-timesheet2-invoices.Currency]"} {options $currency_options} }
    }


ad_form -extend -name price -on_request {
    # Populate elements from local variables

} -select_query {

	select	p.*
	from	im_trans_prices p
	where	p.price_id = :price_id

} -new_data {

    db_dml price_insert "
insert into im_trans_prices (
	price_id,
	uom_id,
	company_id,
	task_type_id,
	material_id,
	currency,
	price
) values (
	:price_id,
	:uom_id,
	:company_id,
	:task_type_id,
	:material_id,
	:currency,
	:amount
)"

} -edit_data {

    db_dml price_update "
	update im_prices set
	        package_name    = :package_name,
	        label           = :label,
	        name            = :name,
	        url             = :url,
	        sort_order      = :sort_order,
	        parent_price_id  = :parent_price_id
	where
		price_id = :price_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}
