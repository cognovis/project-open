# /packages/intranet-overtime/www/overtime-balance-component.tcl
#
# Copyright (c) 2003-20011 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
# Author: klaus.hofeditz@project-open.com


# ---------------------------------------------------------------
# 1. Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set date_format "YYYY-MM-DD"
set package_key "intranet-overtime"
set view_absences_p [im_permission $current_user_id "view_absences"]
set view_absences_all_p [im_permission $current_user_id "view_absences_all"]
set add_absences_p [im_permission $current_user_id "add_absences"]

set today [db_string today "select now()::date"]

if {!$view_absences_p && !$view_absences_all_p} { 
    return ""
}

set page_title [lang::message::lookup "" intranet-overtime.OvertimeBalance "Overtime Balance"]
set absence_base_url "/intranet-timesheet2/absences"
set return_url [im_url_with_query]
set user_view_url "/intranet/users/view"


set current_year [db_string current_year "select to_char(now(), 'YYYY')"]

set start_of_year "$current_year-01-01"
set end_of_year "$current_year-12-31"

set overtime_absence_id [db_string get_data "select category_id from im_categories where category = 'Overtime'" -default 0]

if { "0" == $overtime_absence_id } {
    ad_return_complaint 1 "No absence type 'Overtime' found, please verify installation or add absence type manually."
}

# ------------------------------------------------------------------
# User Info
# ------------------------------------------------------------------

db_0or1row user_info "
	select	u.user_id,
		e.*,
		im_name_from_user_id(u.user_id) as user_name
	from	cc_users u
		LEFT OUTER JOIN im_employees e ON e.employee_id = u.user_id
	where	u.user_id = :user_id_from_search
"

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

list::create \
    -name overtime_balance \
    -multirow overtime_balance_multirow \
    -key absence_id \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {
    } -elements {
	booking_date_pretty {
            label "[lang::message::lookup {} intranet-core.Date Date]"
	}
	user_name {
        label "[lang::message::lookup {} intranet-core.User User]" 
	}
	days_absence {
        label "[lang::message::lookup {} intranet-overtime.Days_Absence \"Days<br>Abs.\"]"
		display_template { <span style='display: inline-block; text-align: center; width: 100%;'>@overtime_balance_multirow.days_absence@</span> }
	}
    days_booking {
        label "[lang::message::lookup {} intranet-overtime.Days:Booked \"Days<br>booked \"]"
		display_template { <span style='display: inline-block; text-align: center; width: 100%;'>@overtime_balance_multirow.days_booking@</span> }
    }
	comment {
            label "[lang::message::lookup {} intranet-core.Comment \"Comment\"]"
    }
	}

set overtime_sql "
	select
		comment, 
		coalesce(days,0) as days,
		to_char(booking_date, :date_format) as booking_date_pretty,
		im_name_from_user_id(user_id) as user_name,
		0 as absence_p
	from
		im_overtime_bookings
	where
		user_id = :user_id_from_search and
		booking_date <= :end_of_year and
		booking_date >= :start_of_year 
	UNION 
		select 
			absence_name as comment, 
			duration_days as days, 
			to_char(start_date, 'YYYY-MM-DD') as booking_date_pretty,
			im_name_from_user_id(owner_id) as user_name,
			1 as absence_p
		from 
			im_user_absences
		where 
			owner_id = :user_id_from_search and
			start_date <= :end_of_year and
			end_date >= :start_of_year and 
			absence_type_id = $overtime_absence_id
    order by
   	     booking_date_pretty;
"


set overtime_days_left 0 
set overtime_days_taken 0

set overtime_days_balance [db_string get_data "select overtime_balance from im_employees where employee_id = :user_id_from_search" -default 0]

db_multirow -extend { days_absence days_booking } overtime_balance_multirow overtime_balance $overtime_sql {
	if { $absence_p } {
		set overtime_days_taken [expr $overtime_days_taken + $days]
		set overtime_days_left [expr $overtime_days_left - $days]
		set days_absence $days 	
		set days_booking -

	} else {
		set overtime_days_left [expr $overtime_days_left + $days]
		set days_booking $days			
		set days_absence -
	}
}

ad_return_template
