# /packages/intranet-payments/www/new.tcl

ad_page_contract {
    Purpose: form to enter payments for a project

    @param group_id Must have this if we're adding a payment
    @param payment_id Must have this if we're editing a payment

    @author fraber@fraber.de
    @creation-date August 2003
} {
    { return_url "" }
    { payment_id "" }
    { invoice_id "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_title "Payments"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"

# Needed for im_view_columns, defined in intranet-views.tcl
set amp "&"

if {![im_permission $user_id add_payments]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

# ---------------------------------------------------------------
# Extract Payment Values (New vs. Edit)
# ---------------------------------------------------------------

if {[empty_string_p $payment_id]} {

    # We are creating a new Payment

    set add_delete_text 0
    set payment_id [db_nextval "im_payments_id_seq"]
    set page_title "New payment" 
    set context_bar [ad_context_bar $page_title]
    set button_name "Add payment"
    set invoice_html [im_invoices_select invoice_id $invoice_id "" [list "Deleted" "In Process"]]

    # Set the provider to the "Internal" customer - this organization
    set provider_id [im_customer_internal]
    set amount ""
    set currency "EUR"
    set payment_type_id 0
    set received_date [db_string today "select to_char(sysdate, 'YYYY-MM-DD') from dual"]
    set note ""

    # Let's default start_block to something close to today
    if { ![db_0or1row nearest_start_block_select {
	select to_char(min(sb.start_block),'Month DD, YYYY') as start_block
	  from im_start_blocks sb
	where sb.start_block >= trunc(sysdate)}] } {
	    ad_return_error "Start block error" "The intranet start blocks are either undefined or we do not have a start block for this week or later into the future."
	    return
    }
	   
} else {

    # We are editing an already existing payment
        db_0or1row get_payment_info "
select
        p.*,
	i.invoice_nr,
	c.customer_name,
	to_char(p.start_block,'Month DD, YYYY') as start_block
from
	im_customers c,
	im_payments p,
	im_invoices i
where
	p.invoice_id=i.invoice_id(+)
	and i.customer_id = c.customer_id(+)
	and p.payment_id = :payment_id
"

    set add_delete_text 1
    set page_title "Edit payment"
    set context_bar [ad_context_bar [list /intranet-invoices/ "Invoices"] $page_title]
    set button_name "Update"

    set invoice_html "
<input type=hidden name=invoice_id value=$invoice_id>
<A HREF=/intranet-invoices/view?invoice_id=$invoice_id>$invoice_nr</A>
"

}

set letter "none"
set next_page_url ""
set previous_page_url ""
set navbar [im_invoices_navbar $letter "/intranet-payments/index" $next_page_url $previous_page_url [list letter]]
