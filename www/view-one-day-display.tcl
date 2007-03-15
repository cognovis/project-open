if {[info exists url_stub_callback]} {
    # This parameter is only set if this file is called from .LRN.
    # This way I make sure that for the time being this adp/tcl
    # snippet is backwards-compatible.
    set portlet_mode_p 1
} else {
    set portlet_mode_p 0 
}

set current_date $date
if {![info exists return_url]} {
    set return_url [ad_urlencode "../"]
}

if {[info exists portlet_mode_p] && $portlet_mode_p} {
    set item_template "\${url_stub}cal-item-view?show_cal_nav=0&return_url=${return_url}&action=edit&cal_item_id=\$item_id"
    set url_stub_callback "calendar_portlet_display::get_url_stub"
    set hour_template "calendar/cal-item-new?date=$current_date&start_time=\$day_current_hour&return_url=$return_url"
} else {
    set item_template "cal-item-view?cal_item_id=\$item_id"
    set url_stub_callback ""
    set hour_template {cal-item-new?date=$current_date&start_time=$day_current_hour&return_url=$return_url}
}

if { ![info exists show_calendar_name_p] } {
    set show_calendar_name_p 1
}

if { ![info exists start_display_hour]} {
    set start_display_hour 0
}

if { ![info exists end_display_hour]} {
    set end_display_hour 23
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
    set date [lc_time_fmt $user_now_time "%F"]
}


set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

# Loop through the items without time
multirow create items_without_time \
    event_name \
    event_url \
    calendar_name \
    status_summary 

set additional_limitations_clause " and to_char(start_date, 'HH24:MI') = '00:00' and  to_char(end_date, 'HH24:MI') = '00:00'"
set additional_select_clause ""
set order_by_clause " order by name"
set interval_limitation_clause [db_map dbqd.calendar.www.views.day_interval_limitation] 

#AG: the "select_all_day_items" query is identical to "select_items"
#just without the Oracle +ORDERED hint, which speeds every other
#query but slows this one.
db_foreach dbqd.calendar.www.views.select_items {} {

    # Replace $ (variable dollars) by harmless "X"
    regsub {\$} $name X name

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

    
    set event_url [subst $item_template]
    multirow append items_without_time $name $event_url $calendar_name $status_summary 
}


set day_current_hour 0
set localized_day_current_hour ""
set item_add_without_time [subst $hour_template]

# Now items with time
multirow create items \
    event_name \
    event_url \
    calendar_name \
    status_summary \
    add_url \
    localized_current_hour \
    current_hour \
    start_time \
    end_time \
    colspan \
    rowspan 

for {set i 0 } { $i < 24 } { incr i } {
    set items_per_hour($i) 0
}


set additional_limitations_clause " and (to_char(start_date, 'HH24:MI') <> '00:00' or to_char(end_date, 'HH24:MI') <> '00:00')"
set order_by_clause " order by to_char(start_date,'HH24')"
set day_items_per_hour {}

db_foreach dbqd.calendar.www.views.select_items {} {


    set ansi_start_date [lc_time_system_to_conn $ansi_start_date]
    set ansi_end_date [lc_time_system_to_conn $ansi_end_date]

    set start_time [lc_time_fmt $ansi_start_date "%X"]
    set end_time [lc_time_fmt $ansi_end_date "%X"]

    if {($start_hour == $end_hour) || ($end_minutes > 0)} {
        incr end_hour
    }

    for { set item_current_hour $start_hour } { $item_current_hour < $end_hour } { incr item_current_hour } {
        set item_current_hour [expr [string trimleft $item_current_hour 0]+0]

        if { $start_hour == $item_current_hour } {

            lappend day_items_per_hour \
                [list $item_current_hour $name $item_id $calendar_name $status_summary $start_hour $end_hour $start_time $end_time $calendar_id]
        } else {
            lappend day_items_per_hour \
                [list $item_current_hour {} $item_id $calendar_name $status_summary $start_hour $end_hour $start_time $end_time $calendar_id]
        }
        incr items_per_hour($item_current_hour)
    }
}

set day_items_per_hour [lsort -command calendar::compare_day_items_by_current_hour $day_items_per_hour]
set day_current_hour $start_display_hour

# Get the maximum items per hour
set max_items_per_hour 0
for {set i $start_display_hour } { $i < $end_display_hour } { incr i } {
    if {$items_per_hour($i) > $max_items_per_hour} {
        set max_items_per_hour $items_per_hour($i)
    }
}

foreach this_item $day_items_per_hour {
    set item_start_hour [expr [string trimleft [lindex $this_item 5] 0]+0]
    set item_end_hour [expr [string trimleft [lindex $this_item 6] 0]+0]
    set rowspan [expr $item_end_hour - $item_start_hour]
    if {$item_start_hour > $day_current_hour && \
            $item_start_hour >= $start_display_hour} {
        # need to add dummy entries to show all hours

        for {  } { $day_current_hour < $item_start_hour } { incr day_current_hour } {
	    set localized_day_current_hour [lc_time_fmt "$current_date $day_current_hour:00:00" "%X"]
            multirow append items \
                "" \
                "" \
                "" \
                "" \
                [subst $hour_template] \
                $localized_day_current_hour \
                $day_current_hour \
                0 \
                0 \
                "" \
                "" 
        }
    }

    set day_current_hour [lindex $this_item 0]
    set localized_day_current_hour [lc_time_fmt "$current_date $day_current_hour:00:00" "%X"]

    # reset url stub
    set url_stub ""

    # In case we need to dispatch to a different URL (ben)
    if {![empty_string_p $url_stub_callback]} {
        # Cache the stuff
     
	if {![info exists url_stubs([lindex $this_item 9])]} {
            set url_stubs([lindex $this_item 9]) [$url_stub_callback [lindex $this_item 9]]
        }
        
	    set url_stub $url_stubs([lindex $this_item 9])
    }


    set item [lindex $this_item 1]
    set item_id [lindex $this_item 2]

    set current_hour_link [subst $hour_template]

    multirow append items \
        $item \
        [subst $item_template] \
        [lindex $this_item 3] \
        [lindex $this_item 4] \
        $current_hour_link \
        $localized_day_current_hour \
        $day_current_hour \
        [lindex $this_item 7] \
        [lindex $this_item 8] \
        0 \
        $rowspan 

    set day_current_hour [expr [lindex $this_item 0] +1 ]
}

if {$day_current_hour < $end_display_hour } {
    # need to add dummy entries to show all hours
    for {  } { $day_current_hour < $end_display_hour } { incr day_current_hour } {
	set localized_day_current_hour [lc_time_fmt "$current_date $day_current_hour:00:00" "%X" [ad_conn locale]]
        multirow append items \
            "" \
            "" \
            "" \
            "" \
            "[subst $hour_template]" \
            $localized_day_current_hour \
            $day_current_hour \
            "" \
            0 \
            0     
    }
}

db_1row dbqd.calendar.www.views.select_day_info {}

if {$portlet_mode_p} {
    set previous_week_url "?page_num=$page_num&date=[ns_urlencode $yesterday]"
    set next_week_url "?page_num=$page_num&&date=[ns_urlencode $tomorrow]"
} else {
    set previous_week_url "view?view=day&date=[ns_urlencode $yesterday]"
    set next_week_url "view?view=day&date=[ns_urlencode $tomorrow]"
}
set dates [lc_time_fmt $date "%q"]
