# /www/intranet/payments/delete.tcl

ad_page_contract {

    Deletes specified payment

    @param group_id Group this payment belongs to. We need this to
    redirect to the right place on a double-click (Because on the double
    click the payment will already be deleted and thus the group id will
    not be available)
    @param payment_id What we're deleting

    @author mbryzek@arsdigita.com
    @creation-date Sun Aug 13 16:57:20 2000
    @cvs-id delete-2.tcl,v 1.1.2.1 2000/08/16 21:28:40 mbryzek Exp

} {
    group_id:naturalnum,notnull
    payment_id:naturalnum,notnull
}


set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_payments]} {
    ad_return_complaint 1 "<li>[_ intranet-invoices.lt_You_have_insufficient]"
    return
}

db_dml delete_payment \
	"delete from im_project_payments p where p.payment_id = :payment_id"

ad_returnredirect index?[export_url_vars group_id]
