# /www/intranet/payments/delete.tcl

ad_page_contract {

    Confirms deletion of payment

    @param payment_id What we're deleting

    @author mbryzek@arsdigita.com
    @creation-date Sun Aug 13 16:57:20 2000
    @cvs-id delete.tcl,v 1.1.2.2 2000/09/22 01:38:41 kevin Exp

} {
    payment_id:naturalnum,notnull
}

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_payments]} {
    ad_return_complaint 1 "<li>[_ intranet-invoices.lt_You_have_insufficient]"
    return
}


db_0or1row get_payment_info \
	"select ug.group_name as project_name, ug.group_id,
                to_char(p.start_block,'Month DD, YYYY') as start_block, 
                p.fee, p.fee_type
           from user_groups ug, im_project_payments p
          where p.group_id = ug.group_id
            and p.payment_id = :payment_id"
 
set page_title "[_ intranet-payments.lt_Confirm_payment_delet]"
set context_bar [im_context_bar [list [im_url_stub]/projects/ "[_ intranet-payments.Projects]"] [list [im_url_stub]/projects/view?[export_url_vars group_id] "[_ intranet-payments.One_project]"] [list index?[export_url_vars group_id] [_ intranet-payments.Payments]] [list project-payment-new?[export_url_vars group_id] "[_ intranet-payments.Edit_payment]"] "[_ intranet-payments.Delete_payment]"]
set fee_str "\$[util_commify_number $fee]"
set page_body "
[_ intranet-payments.lt_Do_you_really_want_to]
<p>
[im_yes_no_table delete-2 project-payment-new [list payment_id group_id]]
"

#doc_return  200 text/html [im_return_template]

