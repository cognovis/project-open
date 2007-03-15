if {![info exists add_p] || [string equal "" $add_p]} {
    set add_p t
}
if {![info exists link_day_p] || [string equal "" $link_day_p]} {
    set link_day_p t
}
if {![info exists date] || [empty_string_p $date]} {
    # Default to todays date in the users (the connection) timezone
    set server_now_time [dt_systime]
    set user_now_time [lc_time_system_to_conn $server_now_time]
    set date $user_now_time
}

dt_get_info $date

if {[info exists url_stub_callback]} {
    # This parameter is only set if this file is called from .LRN.
    # This way I make sure that for the time being this adp/tcl
    # snippet is backwards-compatible.
    set portlet_mode_p 1
}

set url_stub_callback ""
set page_num_urlvar ""

if { [info exists calendar_id_list] } {
    if {[llength $calendar_id_list] > 1} {
	set force_calendar_id [calendar::have_private_p -return_id 1 -calendar_id_list $calendar_id_list -party_id [ad_conn user_id]]
    } else {
	set force_calendar_id [lindex $calendar_id_list 0]
    }

    calendar::get -calendar_id $force_calendar_id -array force_calendar
    set base_url [apm_package_url_from_id $force_calendar(package_id)]
} else {
    set base_url ""
}

if {![info exists return_url]} {
    set return_url [ad_urlencode "../"]
}

if {[info exists portlet_mode_p] && $portlet_mode_p} {
    set page_num_urlvar "&page_num=$page_num"
    if {![info exists return_url]} {
	set return_url [ad_urlencode "../"]
    }
    set item_template "\${url_stub}cal-item-view?show_cal_nav=0&return_url=${return_url}&action=edit&cal_item_id=\$item_id"
    set prev_month_template "?view=month&date=\[ad_urlencode \$prev_month\]&page_num=$page_num"
    set next_month_template "?view=month&date=\[ad_urlencode \$next_month\]&page_num=$page_num"
    set url_stub_callback "calendar_portlet_display::get_url_stub"
} elseif {![info exists item_template] || [string equal "" $item_template]} {
    # allow item_template to be passed in as a parameter
    set item_template "cal-item-view?cal_item_id=\$item_id"
} 
# allow prev_month_template and next_month_template to be passed in
if {![info exists prev_month_template] || [string equal "" $prev_month_template]} {
    set prev_month_template "view?view=month&date=\[ad_urlencode \$prev_month\]"
}
if {![info exists next_month_template] || [string equal "" $next_month_template]} {
    set next_month_template "view?view=month&date=\[ad_urlencode \$next_month\]"
}

if { ![info exists show_calendar_name_p] } {
    set show_calendar_name_p 1
}

if { ![info exists show_calendar_name_p] } {
    set show_calendar_name_p 1
}

if {[exists_and_not_null calendar_id_list]} {
    set calendars_clause [db_map dbqd.calendar.www.views.openacs_in_portal_calendar] 
} else {
    set calendars_clause [db_map dbqd.calendar.www.views.openacs_calendar] 
}

set date_list [dt_ansi_to_list $date]
set this_year [dt_trim_leading_zeros [lindex $date_list 0]]
set this_month [dt_trim_leading_zeros [lindex $date_list 1]]
set this_day [dt_trim_leading_zeros [lindex $date_list 2]]

set month_string [lindex [dt_month_names] [expr $this_month - 1]]

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]
set today_date [dt_sysdate]    

set previous_month_url "[subst $prev_month_template]"
set next_month_url "[subst $next_month_template]"

set first_day_of_week [lc_get firstdayofweek]
set last_day_of_week [expr [expr $first_day_of_week + 7] % 7]

set week_days [lc_get abday]
multirow create weekday_names weekday_short
for {set i 0} {$i < 7} {incr i} {
    multirow append weekday_names [lindex $week_days [expr [expr $i + $first_day_of_week] % 7]]
}


# Get the beginning and end of the month in the system timezone
set first_date_of_month [dt_julian_to_ansi $first_julian_date_of_month]
set first_date_of_month_system [lc_time_conn_to_system "$first_date_of_month 00:00:00"]
set last_date_in_month [dt_julian_to_ansi $last_julian_date_in_month]
set last_date_in_month_system [lc_time_conn_to_system "$last_date_in_month 23:59:59"]

set day_number $first_day

set today_ansi_list [dt_ansi_to_list $today_date]
set today_julian_date [dt_ansi_to_julian [lindex $today_ansi_list 0] [lindex $today_ansi_list 1] [lindex $today_ansi_list 2]]


# Create the multirow that holds the calendar information
# NOTE: added show_calendarname_p to determine if we want to show the calendar name in [ ]
multirow create items \
    event_name \
    event_url \
    calendar_name \
    status_summary \
    ansi_start_time \
    day_number \
    beginning_of_week_p \
    end_of_week_p \
    today_p \
    outside_month_p \
    time_p \
    add_url \
    day_url

# Calculate number of greyed days and then add them to the calendar mulitrow
set greyed_days_before_month [expr [expr [dt_first_day_of_month $this_year $this_month]] -1 ]
set greyed_days_before_month [expr [expr $greyed_days_before_month + 7 - $first_day_of_week] % 7]

for {set current_day 0} {$current_day < $greyed_days_before_month} {incr current_day} {
    if {$current_day == 0} {
        set beginning_of_week_p t
    } else {
        set beginning_of_week_p f
    }
    multirow append items \
	"" \
	"" \
	"" \
	"" \
	"" \
	"" \
	$beginning_of_week_p \
	f \
	"" \
	t \
	"" \
	"" \
	"" 
}

set current_day $first_julian_date_of_month

set order_by_clause " order by ansi_start_date, ansi_end_date"
set additional_limitations_clause ""
set additional_select_clause ""
set interval_limitation_clause [db_map dbqd.calendar.www.views.month_interval_limitation]

db_foreach dbqd.calendar.www.views.select_items {} {

    # Replace $ (variable dollars) by harmless "X"
    regsub {\$} $name X name


    # Convert from system timezone to user timezone
    set ansi_start_date [lc_time_system_to_conn $ansi_start_date]
    set ansi_end_date [lc_time_system_to_conn $ansi_end_date]

    if { [string equal $ansi_start_date $ansi_end_date] && \
      [string equal [lc_time_fmt $ansi_start_date "%T"] "00:00:00"] } {
        set time_p 0
    } else {
        set time_p 1
    }
    
    set ansi_start_time [lc_time_fmt $ansi_start_date "%X"]
    set ansi_end_time [lc_time_fmt $ansi_end_date "%X"]

    set julian_start_date [dt_ansi_to_julian_single_arg $ansi_start_date]

    if {$current_day < $julian_start_date} {
        for {} {$current_day < $julian_start_date} {incr current_day} {
            array set display_information \
                [calendar::get_month_multirow_information \
                     -current_day $current_day \
                     -today_julian_date $today_julian_date \
                     -first_julian_date_of_month $first_julian_date_of_month]
	    if {$link_day_p} {
		set day_link "?view=day&date=[dt_julian_to_ansi $current_day]&$page_num_urlvar"
	    } else {
		set day_link ""
	    }
            multirow append items \
		"" \
		"" \
		"" \
		"" \
                "" \
		$display_information(day_number) \
                $display_information(beginning_of_week_p) \
                $display_information(end_of_week_p) \
                $display_information(today_p) \
		f \
		0 \
                "${base_url}cal-item-new?date=[dt_julian_to_ansi $current_day]&start_time=&end_time&return_url=$return_url" \
		$day_link 

        } 
    }

    if {[string equal $ansi_start_time "00:00"] && [string equal $ansi_end_time "00:00"]} {
        set ansi_start_time "--"
    }

    # reset url stub
    set url_stub ""
    
    # In case we need to dispatch to a different URL (ben)
    if {![empty_string_p $url_stub_callback]} {
        # Cache the stuff
        if {![info exists url_stubs($calendar_id)]} {
            set url_stubs($calendar_id) [$url_stub_callback $calendar_id]
	}
        
        set url_stub $url_stubs($calendar_id)
    }
    
    array set display_information \
        [calendar::get_month_multirow_information \
             -current_day $current_day \
             -today_julian_date $today_julian_date \
             -first_julian_date_of_month $first_julian_date_of_month]
    if {$link_day_p} {
	set day_link "?view=day&date=[dt_julian_to_ansi $current_day]&$page_num_urlvar"
    } else {
	set day_link ""
    }
    multirow append items \
	$name \
	[subst $item_template] \
	$calendar_name \
	"" \
        $ansi_start_time \
	$display_information(day_number) \
        $display_information(beginning_of_week_p) \
        $display_information(end_of_week_p) \
        $display_information(today_p) \
	f \
	$time_p \
        "${base_url}cal-item-new?date=[dt_julian_to_ansi $current_day]&start_time=&end_time&return_url=$return_url" \
	$day_link 

}

# Add cells for remaining days inside the month
for {} {$current_day <= $last_julian_date_in_month} {incr current_day} {
    array set display_information \
        [calendar::get_month_multirow_information \
             -current_day $current_day \
             -today_julian_date $today_julian_date \
             -first_julian_date_of_month $first_julian_date_of_month]

    if {$link_day_p} {
	set day_link "?view=day&date=[dt_julian_to_ansi $current_day]&$page_num_urlvar"
    } else {
	set day_link ""
    }

    multirow append items \
	"" \
	"" \
	"" \
	"" \
	"" \
        $display_information(day_number) \
	$display_information(beginning_of_week_p) \
        $display_information(end_of_week_p) \
	$display_information(today_p) \
	f \
        0 \
	"${base_url}cal-item-new?date=[dt_julian_to_ansi $current_day]&start_time=&end_time&return_url=$return_url" \
	$day_link 

}

# Add cells for remaining days outside the month
set remaining_days [expr [expr $first_day_of_week + 6 - $current_day % 7] % 7]

if {$remaining_days > 0} {
    for {} {$current_day <= [expr $last_julian_date_in_month + $remaining_days]} {incr current_day} {
        multirow append items \
	    "" \
	    "" \
	    "" \
	    "" \
	    "" \
	    "" \
	    f \
	    f \
	    "" \
	    t \
	    0 \
	    "" \
	    "" 

    }
}
