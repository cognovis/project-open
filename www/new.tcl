# /packages/intranet-payments/www/new.tcl

ad_page_contract {
    Purpose: form to enter payments for a project

    @param group_id Must have this if we're adding a payment
    @param payment_id Must have this if we're editing a payment

    @author fraber@fraber.de
    @creation-date August 2003
} {
    { cost_id "" }
    { invoice_id "" }
    { return_url "" }
    { payment_id "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_title "<#_ Payments#>"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set amp "&"

ns_log Notice "intranet-payments/new: return_url=$return_url"

if {![im_permission $user_id add_payments]} {
    ad_return_complaint "<#_ Insufficient Privileges#>" "
    <li><#_ You don't have sufficient privileges to see this page.#>"    
}

# default for old-style payments
if {"" == $cost_id} { set cost_id $invoice_id }
if {"" == $cost_id} {
    ad_return_complaint 1 "<li><#_ No cost/invoice item specified#>"
}

# ---------------------------------------------------------------
# Extract Payment Values (New vs. Edit)
# ---------------------------------------------------------------

if {"" == $payment_id} {

    # We are creating a new Payment

    set add_delete_text 0
    set payment_id [db_nextval "im_payments_id_seq"]
    set page_title "<#_ New payment#>" 
    set context_bar [ad_context_bar $page_title]
    set button_name "<#_ Add payment#>"
    set invoice_html [im_costs_select cost_id $cost_id "" [list "Deleted" "In Process"]]

    set cost_name [db_string cost_name "select cost_name from im_costs where cost_id=:cost_id"]

    # Set the provider to the "Internal" company - this organization
    set provider_id [im_company_internal]
    set amount ""
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set payment_type_id 0
    set received_date [db_string today "select to_char(sysdate, 'YYYY-MM-DD') from dual"]
    set note ""

    # Let's default start_block to something close to today
    if { ![db_0or1row nearest_start_block_select {
	select to_char(min(sb.start_block),'Month DD, YYYY') as start_block
	  from im_start_blocks sb
	where sb.start_block >= trunc(sysdate)}] } {
	    ad_return_error "<#_ Start block error#>" "<#_ The intranet start blocks are either undefined or we do not have a start block for this week or later into the future.#>"
	    return
    }
	   
} else {

    # We are editing an already existing payment
        db_0or1row get_payment_info "
select
        p.*,
	ci.cost_name,
	cus.company_name,
	pro.company_name as provider_name,
	to_char(p.start_block,'Month DD, YYYY') as start_block
from
	im_companies cus,
	im_companies pro,
	im_payments p,
	im_costs ci
where
	p.cost_id = ci.cost_id(+)
	and ci.customer_id = cus.company_id(+)
	and ci.provider_id = pro.company_id(+)
	and p.payment_id = :payment_id
"

    set add_delete_text 1
    set page_title "<#_ Edit payment#>"
    set context_bar [ad_context_bar [list /intranet-payments/ "<#_ Payments#>"] $page_title]
    set button_name "<#_ Update#>"
}

set letter "none"
set next_page_url ""
set previous_page_url ""
set navbar [im_costs_navbar $letter "/intranet-payments/index" $next_page_url $previous_page_url [list letter] "payments_list"]

ns_log Notice "intranet-payments/new: return_url2=$return_url"

set export_form_vars [export_form_vars payment_id provider_id return_url]

