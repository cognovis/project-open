if {[info exists url_stub_callback]} {
    # This parameter is only set if this file is called from .LRN.
    # This way I make sure that for the time being this adp/tcl
    # snippet is backwards-compatible.
    set portlet_mode_p 1
} else {
    set portlet_mode_p 0 
}

if {![info exists base_url]} { set base_url "" }

if {[info exists portlet_mode_p] && $portlet_mode_p} {
    if {![info exists return_url]} {
	set return_url [ad_urlencode "../"]
    }
    set item_template "\${url_stub}cal-item-view?show_cal_nav=0&return_url=${return_url}&action=edit&cal_item_id=\$item_id"
    set url_stub_callback "calendar_portlet_display::get_url_stub"
    set page_num_formvar [export_form_vars page_num]
    set page_num_urlvar "&page_num=$page_num"
} else {
    set item_template "\${base_url}cal-item-view?cal_item_id=\$item_id"
    set url_stub_callback ""
    set page_num_formvar ""
    set page_num_urlvar ""
}


if { ![info exists show_calendar_name_p] } {
    set show_calendar_name_p 1
}

if {[exists_and_not_null calendar_id_list]} {
    set calendars_clause [db_map dbqd.calendar.www.views.openacs_in_portal_calendar] 
} else {
    set calendars_clause [db_map dbqd.calendar.www.views.openacs_calendar] 
}

if {[empty_string_p $date]} {
    # Default to todays date in the users (the connection) timezone
    set server_now_time [dt_systime]
    set user_now_time [lc_time_system_to_conn $server_now_time]
    set date [lc_time_fmt $user_now_time "%x"]
}

if {![info exists package_id]} { set package_id [ad_conn package_id] }
set user_id [ad_conn user_id]

set start_date $date

set first_day_of_week [lc_get firstdayofweek]
set first_us_weekday [lindex [lc_get -locale en_US day] $first_day_of_week]
set last_us_weekday [lindex [lc_get -locale en_US day] [expr [expr $first_day_of_week + 6] % 7]]

db_1row select_weekday_info {}
db_1row select_week_info {}
    
set current_weekday 0

#s/item_id/url
multirow create items \
    event_name \
    event_url \
    calendar_name \
    status_summary \
    start_date \
    day_of_week \
    start_date_weekday \
    start_time \
    end_time \
    no_time_p \
    add_url \
    day_url


# Convert date from user timezone to system timezone
set first_weekday_of_the_week_tz [lc_time_conn_to_system "$first_weekday_of_the_week 00:00:00"]
set last_weekday_of_the_week_tz [lc_time_conn_to_system "$last_weekday_of_the_week 00:00:00"]

set order_by_clause " order by to_char(start_date, 'J'), to_char(start_date,'HH24:MI')"
set interval_limitation_clause [db_map dbqd.calendar.www.views.week_interval_limitation]
set additional_limitations_clause ""
set additional_select_clause " , (to_date(start_date,'YYYY-MM-DD HH24:MI:SS')  - to_date(:first_weekday_of_the_week_tz,         'YYYY-MM-DD HH24:MI:SS')) as day_of_week"

db_foreach dbqd.calendar.www.views.select_items {} {

    # Replace $ (variable dollars) by harmless "X"
    regsub {\$} $name X name

    # Convert from system timezone to user timezone
    set ansi_start_date [lc_time_system_to_conn $ansi_start_date]
    set ansi_end_date [lc_time_system_to_conn $ansi_end_date]

    set start_date_weekday [lc_time_fmt $ansi_start_date "%A"]

    set start_date [lc_time_fmt $ansi_start_date "%x"]
    set end_date [lc_time_fmt $ansi_end_date "%x"]

    set start_time [lc_time_fmt $ansi_start_date "%X"]
    set end_time [lc_time_fmt $ansi_end_date "%X"]

    # need to add dummy entries to show all days
    for {  } { $current_weekday < $day_of_week } { incr current_weekday } {
        set ansi_this_date [dt_julian_to_ansi [expr $first_weekday_julian + $current_weekday]]
        multirow append items \
            "" \
            "" \
            "" \
            "" \
            [lc_time_fmt $ansi_this_date "%x"] \
            $current_weekday \
            [lc_time_fmt $ansi_this_date %A] \
            "" \
            "" \
            "" \
            "${base_url}cal-item-new?date=${ansi_this_date}&start_time=&end_time=&return_url=$return_url" \
            "${base_url}?view=day&date=$ansi_this_date&page_num_urlvar"
    }

    set ansi_this_date [dt_julian_to_ansi [expr $first_weekday_julian + $current_weekday]]
    if {[string equal $start_time "12:00 AM"] && [string equal $end_time "12:00 AM"]} {
        set no_time_p t
    } else {
        set no_time_p f
    }

    # In case we need to dispatch to a different URL (ben)
    if {![empty_string_p $url_stub_callback]} {
        # Cache the stuff
        if {![info exists url_stubs($calendar_id)]} {
            set url_stubs($calendar_id) [$url_stub_callback $calendar_id]
        }
        
        set url_stub $url_stubs($calendar_id)
    }

    multirow append items \
        $name \
        [subst $item_template] \
        $calendar_name \
        $status_summary \
        $start_date \
        $day_of_week \
        $start_date_weekday \
        $start_time \
        $end_time \
        $no_time_p \
        "${base_url}?view=day&date=$ansi_start_date&page_num_urlvar" \
        "${base_url}cal-item-new?date=${ansi_this_date}&start_time=&end_time=&return_url=$return_url" 
    set current_weekday $day_of_week
}

if {$current_weekday < 7} {
    # need to add dummy entries to show all hours
    for {  } { $current_weekday < 7 } { incr current_weekday } {
	set ansi_this_date [dt_julian_to_ansi [expr $first_weekday_julian + $current_weekday]]
	multirow append items \
            "" \
            "" \
            "" \
            "" \
            [lc_time_fmt $ansi_this_date "%x"] \
            $current_weekday \
            [lc_time_fmt $ansi_this_date %A] \
            "" \
            "" \
            "" \
            "${base_url}cal-item-new?date=${ansi_this_date}&start_time=&end_time=&return_url=$return_url" \
            "${base_url}?view=day&date=$ansi_this_date&page_num_urlvar" 
    }
}

# Navigation Bar
set dates "[lc_time_fmt $first_weekday_date "%q"] - [lc_time_fmt $last_weekday_date "%q"]"
if {$portlet_mode_p} {
    set previous_week_url "?$page_num_urlvar&view=week&date=[ad_urlencode [dt_julian_to_ansi [expr $first_weekday_julian - 7]]]"
    set next_week_url "?$page_num_urlvar&view=week&date=[ad_urlencode [dt_julian_to_ansi [expr $first_weekday_julian + 7]]]"
} else {
    set previous_week_url "${base_url}?view=week&date=[ad_urlencode [dt_julian_to_ansi [expr $first_weekday_julian - 7]]]"
    set next_week_url "${base_url}?view=week&date=[ad_urlencode [dt_julian_to_ansi [expr $first_weekday_julian + 7]]]"
}

