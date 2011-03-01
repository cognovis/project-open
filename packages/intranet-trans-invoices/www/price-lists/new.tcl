# /packages/intranet-trans-invoices/www/price-lists/new.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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

if {![im_permission $user_id add_costs]} {
    ad_return_complaint 1 "[_ intranet-trans-invoices.lt_You_have_insufficient_1]"
    return
}

set action_url "new"
set focus "price.var_name"
set page_title "[_ intranet-trans-invoices.New_Price]"
set context [im_context_bar $page_title]

if {![info exists uom_id] || "" == $uom_id} { set uom_id [im_uom_s_word] }

if {"" == $currency} {
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set uom_options [db_list_of_lists uom_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet UoM'
		and (enabled_p = 't' OR enabled_p is null)
	order by category
"]

set task_type_options [db_list_of_lists uom_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet Project Type'
		and (enabled_p = 't' OR enabled_p is null)
	order by category
"]
set task_type_options [linsert $task_type_options 0 [list "" ""]]

set language_options [db_list_of_lists language_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet Translation Language'
		and (enabled_p = 't' OR enabled_p is null)
	order by category
"]
set language_options [linsert $language_options 0 [list "" ""]]

set subject_area_options [db_list_of_lists subject_area_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet Translation Subject Area'
		and (enabled_p = 't' OR enabled_p is null)
	order by category
"]
set subject_area_options [linsert $subject_area_options 0 [list "" ""]]

set file_type_options [db_list_of_lists file_type_options "
	select	category, category_id 
	from	im_categories
	where	category_type = 'Intranet Translation File Type'
		and (enabled_p = 't' OR enabled_p is null)
	order by category
"]
set file_type_options [linsert $file_type_options 0 [list "" ""]]



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
	{uom_id:text(select) {label "[_ intranet-trans-invoices.Unit_of_Measure]"} {options $uom_options} }
	{task_type_id:text(select),optional {label "[_ intranet-trans-invoices.Task_Type]"} {options $task_type_options} }
	{source_language_id:text(select),optional {label "[_ intranet-trans-invoices.Source_Language]"} {options $language_options} }
	{target_language_id:text(select),optional {label "[_ intranet-trans-invoices.Target_Language]"} {options $language_options} }
	{subject_area_id:text(select),optional {label "[_ intranet-trans-invoices.Subject_Area]"} {options $subject_area_options} }
	{file_type_id:text(select),optional {label "[_ intranet-trans-invoices.File_Type]" } {options $file_type_options} }
	{amount:float(text) {label "[_ intranet-trans-invoices.Amount]"} {html {size 10}}}
	{min_price:float(text),optional {label "[lang::message::lookup {} intranet-trans-invoices.Minimum_Amount {Minimum Amount}]"} {html {size 10}}}
	{currency:text(select) {label "[_ intranet-trans-invoices.Currency]"} {options $currency_options} }
	{note:text(textarea),optional {label "[_ intranet-core.Note]"} {html {cols 50}}}
    }


ad_form -extend -name price -on_request {
    # Populate elements from local variables

} -select_query {

	select	p.*,
		price as amount
	from	im_trans_prices p
	where	p.price_id = :price_id

} -new_data {

    db_dml price_insert "
insert into im_trans_prices (
	price_id,
	uom_id,
	company_id,
	task_type_id,
	target_language_id,
	source_language_id,
	subject_area_id,
	file_type_id,
	currency,
	price,
	min_price,
	note
) values (
	:price_id,
	:uom_id,
	:company_id,
	:task_type_id,
	:target_language_id,
	:source_language_id,
	:subject_area_id,
	:file_type_id,
	:currency,
	:amount,
	:min_price,
	:note
)"

} -edit_data {

    db_dml price_update "
	update im_trans_prices set 
	uom_id = :uom_id,
	task_type_id = :task_type_id,
	target_language_id = :target_language_id,
	source_language_id = :source_language_id,
	subject_area_id = :subject_area_id,
	file_type_id = :file_type_id,
	currency = :currency,
	price = :amount,
	min_price = :min_price,
	note = :note
	where price_id = :price_id
    "

} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}
