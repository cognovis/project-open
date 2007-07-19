# /packages/intranet-hr/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Demo page to show indicators
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { form_mode "edit" }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-dashboard.Dashboard]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]

set form_id "indicators"
set action_url "index"

# ---------------------------------------------------------------
# Indicators
# ---------------------------------------------------------------

set invoice_age [db_string invoice_age "
select
	to_char(extract(epoch from avg(now() - ica.effective_date)) / 3600 / 24, '999D9') as age
from
	im_costs_aggreg ica
where
	-- only customer invoices
	ica.cost_type_id = 3700
	-- not in paid, deleted, filed
	and ica.cost_status_id not in (3810, 3812, 3814)
"]

set bill_age [db_string invoice_age "
select
	to_char(extract(epoch from avg(now() - ica.effective_date)) / 3600 / 24, '999D9') as age
from
	im_costs_aggreg ica
where
	-- only customer invoices
	ica.cost_type_id = 3704
	-- not in paid, deleted, filed
	and ica.cost_status_id not in (3810, 3812, 3814)
"]


set sales_price_sword ""
catch {set sales_price_sword [db_string sales_price_sword "
select
	round(sum(item_units * price_per_unit) / sum(item_units), 4)
from
	( select
		iii.item_units,
		iii.price_per_unit,
		iii.item_uom_id,
		ica.cost_id
	from
		im_invoice_items iii,
		im_costs_aggreg ica
	where
		-- join conditions
		iii.invoice_id = ica.cost_id
		-- take only last X days
		and ica.due_date > to_date(to_char(now(), 'YYYY-MM-DD'), 'YYYY-MM-DD') -90
		-- provider bills
		and ica.cost_type_id = 3700
		-- only source-words
		and iii.item_uom_id = 324
	) i
"]} errmsg


set purchase_price_sword ""
catch {set purchase_price_sword [db_string purchase_price_sword "
select
	round(sum(item_units * price_per_unit) / sum(item_units), 4)
from
	( select
		iii.item_units,
		iii.price_per_unit,
		iii.item_uom_id,
		ica.cost_id
	from
		im_invoice_items iii,
		im_costs_aggreg ica
	where
		-- join conditions
		iii.invoice_id = ica.cost_id
		-- take only last X days
		and ica.due_date > to_date(to_char(now(), 'YYYY-MM-DD'), 'YYYY-MM-DD') -90
		-- provider bills
		and ica.cost_type_id = 3704
		-- only source-words
		and iii.item_uom_id = 324
	) i
"]} errmsg


ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {return_url} \
    -form {
        {invoice_age:text(text),optional
	    {label "[_ intranet-dashboard.Average_Invoice_Age]"} 
	    {help_text "Average age of open customer invoices. <a href=index>Details</a>" }
	}
        {bill_age:text(text),optional
	    {label "[_ intranet-dashboard.Average_Bill_Age]"} 
	    {help_text "Average age of open provider bills. <a href=index>Details</a>" }
	}
        {sales_price_sword:text(text),optional
	    {label "[_ intranet-dashboard.Average_Sales_Price_S_Word]"} 
	    {help_text "Average sales price for Source-Words in the last 90 days. <a href=index>Details</a>" }
	}
        {purchase_price_sword:text(text),optional
	    {label "[_ intranet-dashboard.Average_Purchase_Price_S_Word]"} 
	    {help_text "Average purchase price for Source-Words in the last 90 days. <a href=index>Details</a>" }
	}
}

template::element::set_value $form_id invoice_age $invoice_age
template::element::set_value $form_id bill_age $bill_age
template::element::set_value $form_id purchase_price_sword $purchase_price_sword
template::element::set_value $form_id sales_price_sword $sales_price_sword


