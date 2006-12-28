# /www/intranet/payments/project-payment-new-2.tcl

ad_page_contract {
    Purpose: records payments

    @param group_id 
    @param payment_id 
    @param start_block 
    @param fee 
    @param fee_type 
    @param due_date 
    @param received_date 
    @param note 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id project-payment-new-2.tcl,v 3.9.2.6 2000/08/16 21:24:58 mbryzek Exp
} {
    group_id:integer
    payment_id:integer
    { start_block "" }
    { fee "" }
    { fee_type "" }
    { due_date "" }
    { received_date "" }
    { note "" }
}



set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set required_vars [list \
	[list start_block "Missing starting date"] \
	[list fee_type "Missing fee type"] \
	[list fee "Missing fee"]]

regsub "," $fee "" fee

set errors [im_verify_form_variables $required_vars]
if { ![empty_string_p $errors] } {
    ad_return_complaint 1 $errors
    return
}

if { ![ad_var_type_check_number_p $fee] } {
    ad_return_complaint 1 "<li>The value \"fee\" entered from previous page must be a valid number."
    return
}

if { $fee < 0 } {
    ad_return_complaint 1 "<li>The value \"fee\" entered from previous page must be non-negative."
    return
}


set start_block [db_nullify_empty_string $start_block]
set fee         [db_nullify_empty_string $fee]
set fee_type    [db_nullify_empty_string $fee_type]
set note        [db_nullify_empty_string $note]

db_dml payment_update "update im_project_payments set 
    start_block = to_date(:start_block,'Month DD, YYYY'),
    fee = :fee,
    fee_type = :fee_type,
    last_modified = sysdate,
    last_modifying_user = :user_id,
    modified_ip_address = '[ns_conn peeraddr]',
    note = :note
    where payment_id = :payment_id" 


if {[db_resultrows] == 0} {
    db_dml new_payment_insert \
	    "insert into im_project_payments 
                    ( payment_id, group_id, start_block, fee, fee_type,  
                      note, last_modified, last_modifying_user, modified_ip_address)
             values ( :payment_id, :group_id, to_date(:start_block,'Month DD, YYYY'), 
                      :fee, :fee_type, 
                      :note, sysdate, :user_id, '[ns_conn peeraddr]' )" 
}


ad_returnredirect "index.tcl?[export_url_vars group_id]"

ns_conn close

# email the people in the intranet billing group

set project_name [db_string get_project_name \
	"select group_name from user_groups where group_id = :group_id"]

db_1row get_user_info "
	select	im_name_from_user_id(u.user_id) as editing_user, 
		email as editing_email
	from	users 
	where	user_id = :user_id
"

set message "

A payment for $project_name has been changed by $editing_user.

Work starting: $start_block
Type:  $fee_type
Note: $note

To view online: [im_url]/payments/index?[export_url_vars group_id]

"

# ToDo: No BillingGroupShortName

db_foreach people_to_notify \
	"select email, first_names, last_name 
         from users, user_group_map
         where users.user_id = user_group_map.user_id 
         and group_id = (select group_id from user_groups 
                         where short_name = '[ad_parameter BillingGroupShortName "" ""]')" {
    ns_log Notice "Sending email to $email"
    ns_sendmail $email "$editing_email" "Change to $project_name payment plan." "$message"
}

db_release_unused_handles