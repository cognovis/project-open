# /packages/intranet-overtime/www/booking.tcl
#
# Copyright (C) 2011 ]project-open[
#

ad_page_contract {
    @param
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    user_id_from_form
    comment
    overtime
    { type "overtime" }
}

# ---------------------------------------------------------------
# Defaults and Settings & Security  
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

# Planned units a number?
if {![string is double $overtime]} {
        ad_return_complaint 1 "
            <b>[lang::message::lookup "" intranet-core.Not_a_number "Value is not a number"]</b>:<br>
            [lang::message::lookup "" intranet-core.Not_a_number_msg "
                The value for you have provided for 'Overtime' ('$overtime') is not a number.<br>
                Please enter something like '1' or '0.5'.
	"]
        "
        ad_script_abort
}

if {![im_permission $user_id "view_hr"]} {
    ad_return_complaint 1 "[_ intranet-core.lt_Insufficient_Privileg]"
}

if {[catch { 
	     set overtime_booking_id [db_string nextval "select nextval('im_overtime_bookings_seq');"]
	     db_dml insert_inq "
                insert into im_overtime_bookings
                        (overtime_booking_id, booking_date, user_id, comment, days)
                values
                        ($overtime_booking_id, now(), :user_id_from_form, :comment, :overtime)
             "
             db_dml update_balance "
                update im_employees set overtime_balance = (select overtime_balance from im_employees where employee_id = :user_id_from_form) + :overtime where employee_id = :user_id_from_form 
             "
	   } errmsg 
]} {ad_return_complaint 1 "<br>Error when inserting overtime record, please get in touch with your System Administrator:<br>$errmsg<br><br>"}

ad_returnredirect "/intranet/users/view?user_id=$user_id_from_form"