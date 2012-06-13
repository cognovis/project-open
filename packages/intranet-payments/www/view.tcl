# /packages/intranet-payments/view.tcl

ad_page_contract {
    Purpose: form to enter payments for a project

    @param company_id Must have this if we're adding a payment
    @param payment_id Must have this if we're editing a payment

    @author frank.bergmann@project-open.com
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
set page_title "[_ intranet-payments.Payment]"
set context_bar [im_context_bar $page_title]
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
	ci.cost_name,
	ci.customer_id,
	c.company_name,
	pro.company_name as provider_name,
	to_char(p.start_block,'Month DD, YYYY') as start_block,
        im_category_from_id(p.payment_type_id) as payment_type
from
	im_companies c,
	im_companies pro,
	im_payments p,
	im_costs ci
where
	p.cost_id = ci.cost_id
	and ci.customer_id = c.company_id
	and ci.provider_id = pro.company_id
	and p.payment_id = :payment_id
"