if {![exists_and_not_null base_url]} {
    set base_url [ad_conn url]
}

if {![exists_and_not_null date]} {
    set date [dt_sysdate]
} 

if {[exists_and_not_null page_num]} {
    set page_num_formvar [export_form_vars page_num]
    set page_num "&page_num=$page_num"
} else {
    set page_num_formvar ""
    set page_num ""
}

# Determine whether we need to pass on the period_days variable from the list view
if {[string equal $view list]} {
    if {![exists_and_not_null period_days] || [string equal $period_days [parameter::get -parameter ListView_DefaultPeriodDays -default 31]]} {
	set url_stub_period_days ""
    } else {
	set url_stub_period_days "&period_days=${period_days}"
    }
} else {
    set url_stub_period_days ""
}

array set message_key_array {
    list #acs-datetime.List#
    day #acs-datetime.Day#
    week #acs-datetime.Week#
    month #acs-datetime.Month#
}

# Create row with existing views
multirow create views name text active_p url
foreach viewname {list day week month} {
    if { [string equal $viewname $view] } {
        set active_p t
    } else {
        set active_p f
    }
    if {[string equal $viewname list]} {
	multirow append views [lang::util::localize $message_key_array($viewname)] $viewname $active_p \
	    "[export_vars -base $base_url {date {view $viewname}}]${page_num}${url_stub_period_days}"
    } else {
	multirow append views [lang::util::localize $message_key_array($viewname)] $viewname $active_p \
	    "[export_vars -base $base_url {date {view $viewname}}]${page_num}"
    }
}

set list_of_vars [list]

# Get the current month, day, and the first day of the month
if {[catch {
    dt_get_info $date
} errmsg]} {
    set date [dt_sysdate]
    dt_get_info $date
}

set now        [clock scan $date]
    set date_list [dt_ansi_to_list $date]
    set year [dt_trim_leading_zeros [lindex $date_list 0]]
    set month [dt_trim_leading_zeros [lindex $date_list 1]]
    set day [dt_trim_leading_zeros [lindex $date_list 2]]

set months_list [dt_month_names]
set curr_month_idx  [expr [dt_trim_leading_zeros [clock format $now -format "%m"]]-1]
if [string equal $view month] {
    set curr_year [clock format $now -format "%Y"]
    set prev_year [clock format [clock scan "1 year ago" -base $now] -format "%Y-%m-%d"]
    set next_year [clock format [clock scan "1 year" -base $now] -format "%Y-%m-%d"]
    set prev_year_url "$base_url?view=$view&date=[ad_urlencode $prev_year]${page_num}${url_stub_period_days}"
    set next_year_url "$base_url?view=$view&date=[ad_urlencode $next_year]${page_num}${url_stub_period_days}"

    set now         [clock scan $date]

    multirow create months name current_month_p new_row_p url

    for {set i 0} {$i < 12} {incr i} {

        set month [lindex $months_list $i]

        # show 3 months in a row

        if {($i != 0) && ([expr $i % 3] == 0)} {
            set new_row_p t
        } else {
            set new_row_p f
        }

        if {$i == $curr_month_idx} {
            set current_month_p t 
        } else {
            set current_month_p f
        }
        set target_date [clock format \
                             [clock scan "[expr $i-$curr_month_idx] month" -base $now] -format "%Y-%m-%d"]
        multirow append months $month $current_month_p $new_row_p  \
            "[export_vars -base $base_url {{date $target_date} view}]${page_num}${url_stub_period_days}"
        
    }
} else {
    set curr_month [lindex $months_list $curr_month_idx ]
    set prev_month [clock format [clock scan "1 month ago" -base $now] -format "%Y-%m-%d"]
    set next_month [clock format [clock scan "1 month" -base $now] -format "%Y-%m-%d"]
    set prev_month_url "$base_url?view=$view&date=[ad_urlencode $prev_month]${page_num}${url_stub_period_days}"
    set next_month_url "$base_url?view=$view&date=[ad_urlencode $next_month]${page_num}${url_stub_period_days}"
    
    set first_day_of_week [lc_get firstdayofweek]
    set week_days [lc_get abday]
    multirow create days_of_week day_short
    for {set i 0} {$i < 7} {incr i} {
        multirow append days_of_week [lindex $week_days [expr [expr $i + $first_day_of_week] % 7]]
    }


    multirow create days day_number beginning_of_week_p end_of_week_p today_p active_p url

    set day_of_week 1

    # Calculate number of active days
    set active_days_before_month [expr [expr [dt_first_day_of_month $year $month]] -1 ]
    set active_days_before_month [expr [expr $active_days_before_month + 7 - $first_day_of_week] % 7]

    set calendar_starts_with_julian_date [expr $first_julian_date_of_month - $active_days_before_month]
    set day_number [expr $days_in_last_month - $active_days_before_month + 1]

    for {set julian_date $calendar_starts_with_julian_date} {$julian_date <= [expr $last_julian_date + 7]} {incr julian_date} {
        if {$julian_date > $last_julian_date_in_month && [string equal $end_of_week_p t] } {
            break
        }
        set today_p f
        set active_p t

        if {$julian_date < $first_julian_date_of_month} {
            set active_p f
        } elseif {$julian_date > $last_julian_date_in_month} {
            set active_p f
        } 
        set ansi_date [dt_julian_to_ansi $julian_date]
        
        if {$julian_date == $first_julian_date_of_month} {
            set day_number 1
        } elseif {$julian_date == [expr $last_julian_date_in_month +1]} {
            set day_number 1
        }

        if {$julian_date == $julian_date_today} {
            set today_p t
        }

        if { $day_of_week == 0} {
            set beginning_of_week_p t
        } else {
            set beginning_of_week_p f
        }

        if { $day_of_week == 7 } {
            set day_of_week 0
            set end_of_week_p t
        } else {
            set end_of_week_p f
        }

        multirow append days $day_number $beginning_of_week_p $end_of_week_p $today_p $active_p \
            "[export_vars -base $base_url {{date $ansi_date} view}]${page_num}${url_stub_period_days}"
        incr day_number
        incr day_of_week
    }
}

set today_url "$base_url?view=day&date=[ad_urlencode [dt_sysdate]]${page_num}${url_stub_period_days}"

if { $view == "day" && [dt_sysdate] == $date } {
    set today_p t
} else {
    set today_p f
}


set form_vars ""
foreach var $list_of_vars {
    append form_vars "<INPUT TYPE=hidden name=[lindex $var 0] value=[lindex $var 1]>"
}
