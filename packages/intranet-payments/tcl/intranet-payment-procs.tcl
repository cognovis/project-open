# /packages/intranet-payments/tcl/intranet-payment-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Invoices

    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
}

ad_proc im_payment_type_select { select_name { default "" } } {
} {
    return [im_category_select "Intranet Payment Type" $select_name $default]
}

ad_proc -public im_payment_create_payment {
    {-cost_id ""}
    {-payment_type_id ""}
    {-note ""}
    {-actual_amount ""}
} {
    Generate a new payment
} {

    # ---------------------------------------------------------------
    # Defaults & Security
    # ---------------------------------------------------------------
    
    # User id already verified by filters
    if {
	[catch {
	    set user_id [ad_conn user_id]
	    set peeraddr [ns_conn peeraddr]
	}]
    } {
	set user_id [im_sysadmin_user_default]
	set peeraddr "0.0.0.0"
    }

    set payment_id [db_nextval "im_payments_id_seq"]
    set received_date [db_string today "select to_char(sysdate, 'YYYY-MM-DD') from dual"]

    # --------------------------
    # Get the values from cost item
    # --------------------------
    
    db_1row cost_info "select cost_type_id, customer_id, provider_id, (amount * (1 + coalesce(vat,0)/100 + coalesce(tax,0)/100)) as amount, currency from im_costs where cost_id = :cost_id"
    if {$actual_amount eq ""} {
	set actual_amount $amount
    }

    if {[im_cost_type_is_invoice_or_quote_p $cost_type_id]} {
	set company_id $customer_id
	set provider_id [im_company_internal]
    } else {
	set company_id $provider_id
	set customer_id [im_company_internal]
    }

    if {$payment_type_id eq ""} {
	set payment_method_id [db_string payment_method "select payment_method_id from im_invoices where invoice_id = :cost_id" -default ""]
	if {$payment_method_id eq ""} {
	    set payment_type_id [db_string default_payment_method "select default_payment_method_id from im_companies where company_id = :customer_id" -default 0]
	} else {
	    set payment_type_id $payment_method_id
	}
    }
    
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
		:customer_id,
		:provider_id,
	        :actual_amount, 
		:currency,
		:received_date,
		:payment_type_id,
	        :note, 
		(select sysdate from dual), 
		:user_id, 
		:peeraddr
    )" 

    # ---------------------------------------------------------------
    # Mark invoice as paid
    # ---------------------------------------------------------------
    
    db_dml mark_invoice_as_paid "
	update im_costs set
		cost_status_id = [im_cost_status_paid]
	where cost_id = :cost_id
    "
    
    # ---------------------------------------------------------------
    # Update Cost Items
    # ---------------------------------------------------------------
    
    # Update paid_amount
    im_cost_update_payments $cost_id 

    # Record the payment
    callback im_payment_after_create -payment_id $payment_id -payment_method_id $payment_type_id
    
    return $payment_id
}