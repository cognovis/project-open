# /packages/intranet-payments/view.tcl

ad_page_contract {
    Purpose: form to enter payments for a project

    @param customer_id Must have this if we're adding a payment
    @param payment_id Must have this if we're editing a payment

    @author fraber@fraber.de
    @creation-date August 2003
} {
    payment_id
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_title "Payment"
set context_bar [ad_context_bar_ws $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]

# Needed for im_view_columns, defined in intranet-views.tcl
set amp "&"

if {![im_permission $user_id view_payments]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

# ---------------------------------------------------------------
# Extract Payment Values
# ---------------------------------------------------------------

# We are editing an already existing payment

db_0or1row get_payment_info "
select
        p.*,
	i.invoice_nr,
	i.customer_id,
	c.customer_name,
	to_char(p.start_block,'Month DD, YYYY') as start_block,
        im_category_from_id(p.payment_type_id) as payment_type
from
	im_customers c,
	im_payments p,
	im_invoices i
where
	p.invoice_id=i.invoice_id(+)
	and i.customer_id = c.customer_id(+)
	and p.payment_id = :payment_id
"

# ---------------------------------------------------------------
# Format the page
# ---------------------------------------------------------------

set table_html "
	  <tr> 
	    <td colspan=2 class=rowtitle>Payment Details</td>
	  </tr>
	  <tr> 
	    <td>Invoice Nr</td>
	    <td><A href=/intranet-invoices/view?invoice_id=$invoice_id>$invoice_nr</A></td>
	  </tr>
	  <tr> 
	    <td>Client</td>
	    <td><A href=/intranet/customers/view?customer_id=$customer_id>$customer_name</A></td>
	  </tr>
	  <tr> 
	    <td>Amount</td>
	    <td>$amount $currency</td>
	  </tr>
	  <tr> 
	    <td>Received</td>
	    <td>$received_date</td>
	  </tr>
          <tr>
            <td>Payment Type</td>
            <td>$payment_type</td>
          </tr>
          <tr>
            <td>Note</td>
            <td>$note</td>
          </tr>
	  <tr> 
	    <td valign=top> </td>
	    <td><input type=submit value=Edit name=submit></td>
	  </tr>
"

# ---------------------------------------------------------------
# Join the parts together
# ---------------------------------------------------------------

set page_body "
[im_invoices_navbar "none" "/intranet-invoices/index" "" "" [list]]

<form action=new method=POST>
[export_form_vars payment_id invoice_id return_url]

<table border=0>
$table_html
</table>

</form>
"

doc_return  200 text/html [im_return_template]
