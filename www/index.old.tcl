# /www/intranet/payments/index.tcl

ad_page_contract {
    Purpose: shows all payments for a specific project

    @param group_id Group id of the project we're looking at 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id index.tcl,v 3.7.6.6 2000/09/22 01:38:41 kevin Exp
} {
    { group_id:integer "" }
}

if { [empty_string_p $group_id] } {
    # Have to select a project before coming to this page 
    ad_returnredirect [im_url_stub]/projects/
    return
}

set project_name [db_string get_project_name "select 
group_name from user_groups 
where group_id = :group_id
"]


set payment_text ""

db_foreach payment_records \
           "select 
             start_block, fee, fee_type, note,
             decode(paid_p, 't', 'Yes', 'No') as paid_p, 
             group_id, payment_id from im_project_payments 
            where group_id = :group_id 
            order by start_block desc" {
 
    append payment_text "<tr>
    <td>[util_IllustraDatetoPrettyDate $start_block]</td>
    <td>$fee_type</td>
    <td>[util_commify_number $fee]</td>
    <td>$paid_p <a href=payment-negation?[export_url_vars payment_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]>toggle</a></td>
    <td>$note</td>
    <td><a href=project-payment-new?[export_url_vars payment_id]>Edit</a></td></tr>
    <tr><td colspan=6><p>&nbsp;</td></tr>
    "
}

db_release_unused_handles

if {$payment_text == ""} {
    set payment_text "There are no payments recorded."
} else {
    set payment_text "
<table cellspacing=5>
<tr>
 <th align=left>Start of work period
 <th align=left>Fee type
 <th align=left>Fee
 <th align=left>Paid?
 <th align=left>Note
 <th align=left>Edit
$payment_text
</table>
"
}



set page_title "Payments for $project_name"
set context_bar [ad_context_bar [list "[im_url_stub]/projects/" "Projects"] [list "[im_url_stub]/projects/view?[export_url_vars group_id]" $project_name] "Payments"]

doc_return  200 text/html "
[im_header]

Start of work period is the start of actual development.  Typically,
a monthly fee for a given month is due the 15th of the following month.
For example, if the \"start of work period\" is November 1st, the fee for
this is due on December 15th.

$payment_text
<p>
<table width=100%>
<tr>
 <td><a href=project-payment-new?[export_url_vars group_id]>Add a payment</a>
 <td align=right><a href=project-payments-audit?[export_url_vars group_id]>Audit Trail</a>
</table>
[im_footer]
"
