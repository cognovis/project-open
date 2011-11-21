# /packages/intranet-overtime/tcl/intranet-overtime-procs.tcl
#
# Copyright (c) 2003-20011 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
# Author: klaus.hofeditz@project-open.com

ad_library {
    Definitions for the intranet timesheet

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
}

# ---------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

# ad_proc -public im_absence_type_vacation {} { return 5000 }

# ---------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------


ad_proc -public im_overtime_balance_component {
    -user_id_from_search:required
} {
    Returns a HTML component showing the number of days left
    for the user
} {
    set current_user_id [ad_get_user_id]
    # This is a sensitive field, so only allows this for the user himself
    # and for users with HR permissions.

    set read_p 0
    if {$user_id_from_search == $current_user_id} { set read_p 1 }
    if {[im_permission $current_user_id view_hr]} { set read_p 1 }
    if {!$read_p} { return "" }

    set params [list \
		    [list user_id_from_search $user_id_from_search] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-overtime/lib/overtime-balance-component"]
    return [string trim $result]
}

ad_proc -public im_rwh_balance_component {
    -user_id_from_search:required
} {
    Returns a HTML component showing the number of days left
    for the user
} {
    set current_user_id [ad_get_user_id]
    # This is a sensitive field, so only allows this for the user himself
    # and for users with HR permissions.

    set read_p 0
    if {$user_id_from_search == $current_user_id} { set read_p 1 }
    if {[im_permission $current_user_id view_hr]} { set read_p 1 }
    if {!$read_p} { return "" }

    set params [list \
                    [list user_id_from_search $user_id_from_search] \
                    [list return_url [im_url_with_query]] \
		    ]

    set result [ad_parse_template -params $params "/packages/intranet-overtime/lib/rwh-balance-component"]
    return [string trim $result]
}

ad_proc im_timesheet_absences_sum_tmp { 
    -user_id:required
    {-number_days 7} 
} {
    Returns the total number of absences multiplied by 8 hours per absence.
} {
    set hours_per_absence [parameter::get -package_id [im_package_timesheet2_id] -parameter "TimesheetHoursPerAbsence" -default 8]

    set num_absences [db_string absences_sum "
	select	count(*)
	from	im_user_absences a,
		im_day_enumerator(now()::date - '7'::integer, now()::date) d
	where	owner_id = :user_id
		and a.start_date <= d.d
		and a.end_date >= d.d
    "]

    return [expr $num_absences * $hours_per_absence]
}

ad_proc -public -callback absence_on_change -impl intranet-overtime  {
    {-absence_id:required}
    {-absence_type_id:required}
    {-user_id:required}
    {-start_date:required}
    {-end_date:required}
    {-duration_days:required}
    {-transaction_type:required}
} {
    Update overtime balance
} {

	ns_log NOTICE "Callback: Executing callback 'intranet-overtime-procs.tcl::absence_on_change' "

    if { "add" == $transaction_type } {
        set operator "-"
        set comment  [lang::message::lookup "" intranet-overtime.Added_Overtime "New absence 'overtime'"]
    } elseif { "remove" == $transaction_type } {
        set operator "+"
        set comment  [lang::message::lookup "" intranet-overtime.Subtracted_Overtime "Removed absence 'overtime'"]
		db_1row get_duration_days "select owner_id as user_id, duration_days, absence_type_id from im_user_absences where absence_id = $absence_id"
    } else {
		ad_return_error "" "Error: Wrong transaction type"
    }

    set overtime_absence_type_id [db_string get_data "select category_id from im_categories where category = 'Overtime'" -default 0]
	ns_log NOTICE "Callback intranet-overtime-procs.tcl::absence_on_change: absence_type_id: $absence_type_id overtime_absence_type_id: $overtime_absence_type_id"  
    if { $absence_type_id == $overtime_absence_type_id  } {
		db_transaction {
			# set overtime_booking_id [db_string nextval "select nextval('im_overtime_bookings_seq');"]
			ns_log NOTICE "Callback: update im_employees set overtime_balance = (select overtime_balance from im_employees where employee_id = $user_id) $operator :duration_days where employee_id = $user_id"
			db_dml update_overtime_balance "
                 update im_employees set overtime_balance = (select overtime_balance from im_employees where employee_id = $user_id) $operator $duration_days where employee_id = $user_id
			"
			# db_dml update_overtime_balance "
            #    insert into im_overtime_bookings
            #            (overtime_booking_id, booking_date, user_id, comment, days)
            #    values
            #            ($overtime_booking_id, now(), :user_id_from_form, $comment, :duration_days)
        	# "
		} on_error {
			ad_return_complaint 1 "<br>Error:<br>$errmsg<br><br>"
			return
		}
	}
}

