# /packages/intranet-payments/wwwnew.tcl

ad_page_contract {
    Purpose: form to enter payments for a project

    @param project_id Must have this if we're adding a payment
    @param payment_id Must have this if we're editing a payment

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id project-payment-new.tcl,v 3.7.2.6 2000/09/22 01:38:42 kevin Exp
} {
    { project_id:integer "" }
    { payment_id:integer "" }
}

if { [empty_string_p $payment_id] && [empty_string_p $project_id] } {
    ad_return_complaint 1 "Either project_id or payment_id must be specified"
    return
}

# ToDo: No parameter FeeTypes
set user_id [ad_maybe_redirect_for_registration]
set fee_type_list [ad_parameter FeeTypes intranet]

if {[empty_string_p $payment_id]} {
    set project_name [db_string get_project_name "select p.project_name from im_projects where project_id=:project_id"]
    
    set add_delete_text 0
    set payment_id [db_nextval "im_project_payment_id_seq"]
    set page_title "Add payment for $project_name" 
    set context_bar [im_context_bar [list [im_url_stub]/projects/ "Projects"] [list [im_url_stub]/projects/view?[export_url_vars project_id] "One project"] [list index?[export_url_vars project_id] Payments] "Add payment"]
    set button_name "Add payment"
    
    # Let's default start_block to something close to today
    if { ![db_0or1row nearest_start_block_select {
select 
	to_char(min(sb.start_block),'Month DD, YYYY') as start_block
from 
	im_start_blocks sb
where 
	sb.start_block >= trunc(sysdate)
    }]} {
	ad_return_error "Start block error" "The intranet start blocks are either undefined or we do not have a start block for this week or later into the future."
	return
    }
   
} else {
    db_0or1row get_payment_info "
select 
	ug.group_name as project_name, 
	ug.project_id,
	to_char(p.start_block,'Month DD, YYYY') as start_block, 
        p.fee, p.fee_type, p.note
from 
	user_groups ug, im_project_payments p
where 
	p.project_id = ug.project_id
	and p.payment_id = :payment_id"
 
    set add_delete_text 1
    set page_title "Edit payment for $project_name"
    set context_bar [im_context_bar [list [im_url_stub]/projects/ "Projects"] [list [im_url_stub]/projects/view?[export_url_vars project_id] "One project"] [list index?[export_url_vars project_id] Payments] "Edit payment"]
    set button_name "Update"
}

set block_select_options [db_html_select_options -select_option $start_block start_date_list "select to_char(start_block,'Month DD, YYYY'), start_block from im_start_blocks order by start_block asc"] 


set fee_options [ad_generic_optionlist $fee_type_list $fee_type_list [value_if_exists fee_type]]

set note_quoted [ad_quotehtml [value_if_exists note]]

set delete_link ""
if {$add_delete_text} {
    set delete_link "
<ul>
  <li> <a href=delete?[export_url_vars payment_id]>Delete this payment</a>
</ul>
"
}