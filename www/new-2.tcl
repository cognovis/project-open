# /packages/intranet-payments/www/new-2.tcl

ad_page_contract {
    Purpose: records payments

    @param group_id 
    @param payment_id 
    @param fee 
    @param fee_type 
    @param due_date 
    @param received_date 
    @param note 
    @param mark_document_as_paid_p Set the status of the financial document
           to "paid" after registering the payment
    @author frank.bergmann@project-open.com
    @creation-date Aug 2003
} {
    { cost_id:integer "" }
    provider_id:integer
    payment_id:integer
    amount
    currency
    received_date
    payment_type_id
    note
    { mark_document_as_paid_p:integer 0 }
    { return_url "/intranet-payments/" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_payments]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

if { ![ad_var_type_check_number_p $amount] } {
    ad_return_complaint 1 "
    <li>The value \"amount\" entered from previous page must be a valid number."
    return
}

if { $amount < 0 } {
    ad_return_complaint 1 "
    <li>The value \"amount\" entered from previous page must be non-negative."
    return
}

if {"" == $cost_id } {
    ad_return_complaint 1 "
    <li>You have not specified an invoice for this payment."
    return
}

# set note [db_nullify_empty_string $note]

set company_id [db_string get_company_from_invoice "select customer_id from im_costs where cost_id=:cost_id" -default 0]

set provider_id [db_string get_provider_from_invoice "select provider_id from im_costs where cost_id=:cost_id" -default 0]

# Default Currency
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]


# ---------------------------------------------------------------
# Insert data into the DB
# ---------------------------------------------------------------
set last_modified_date [db_string "get current date" "select sysdate from dual"]
set modified_ip_address [ns_conn peeraddr]
db_dml payment_update "
	update
		im_payments 
	set
		cost_id =		:cost_id,
		amount =		:amount,
		currency =		:currency,
		received_date =		:received_date,
		payment_type_id = 	:payment_type_id,
		note =			:note,
	        last_modified =         :last_modified_date,
		last_modifying_user = 	:user_id,
		modified_ip_address = 	:modified_ip_address
	where
		payment_id = :payment_id
"


if {[db_resultrows] == 0} {
    
    db_dml new_payment_insert "
	insert into im_payments ( 
		payment_id, 
		cost_id,
		company_id,
		provider_id,
		amount, 
		currency,
		received_date,
		payment_type_id,
		note, 
		last_modified, 
		last_modifying_user, 
		modified_ip_address
    ) values ( 
		:payment_id, 
		:cost_id,
		:company_id,
		:provider_id,
	        :amount, 
		:currency,
		:received_date,
		:payment_type_id,
	        :note, 
		(select sysdate from dual), 
		:user_id, 
		'[ns_conn peeraddr]' 
    )" 
}


# ---------------------------------------------------------------
# Mark invoice as paid
# ---------------------------------------------------------------


if {$mark_document_as_paid_p} {
    db_dml mark_invoice_as_paid "
	update im_costs set
		cost_status_id = [im_cost_status_paid]
	where cost_id = :cost_id
    "
}

# ---------------------------------------------------------------
# Update Cost Items
# ---------------------------------------------------------------

# Update paid_amount
im_cost_update_payments $cost_id 

ad_returnredirect $return_url
