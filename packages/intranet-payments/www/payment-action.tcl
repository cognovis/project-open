# /packages/intranet-payments/www/payment-action
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Takes commands from the /intranet/payment/index
    page and deletes payments where marked

    @param return_url the url to return to
    @param group_id group id
    @author frank.bergmann@project-open.com
} {
    payment_id:multiple,optional
    { cost_id "" }
    { del "" }
    { add "" }
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_payments]} {
    ad_return_complaint 1 "<li>[_ intranet-payments.lt_You_have_insufficient]"
    return
}

if {"" != $del} {
    ns_log Notice "payment-action: delete payments: $payment_id"

    foreach pid $payment_id {
	
	db_dml delete_payment "delete from im_payments where payment_id=:pid"
    }
   
    # Update the cost_id amount
    im_cost_update_payments $cost_id

    ad_returnredirect $return_url
    return
}

if {"" != $add} {
    ns_log Notice "payment-action: add payment"
    ad_returnredirect "/intranet-payments/new?[export_url_vars cost_id return_url]"
}

ad_return_complaint 1 "<li>[_ intranet-payments.No_command_specified]"
