# /www/intranet/payments/payment-negation.tcl

ad_page_contract {
    Purpose: toggles the paid_p column for a specified payment

    @param return_url
    @param payment_id

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id payment-negation.tcl,v 3.2.6.5 2000/08/16 21:24:58 mbryzek Exp
} {
    return_url
    payment_id:integer
}



db_dml payment_update \
 "update im_project_payments 
  set paid_p = logical_negation(paid_p), received_date = sysdate 
  where payment_id= :payment_id"

db_release_unused_handles

ad_returnredirect $return_url

