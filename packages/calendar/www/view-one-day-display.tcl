# FIXME from sloanspace calendar, they have added a system_type attribute to
# cal_items table, which can be null, class, community, or personal
# this is used to figure out which CSS class to use, for now we set to 
# empty string to use generic cal-Item css class DAVEB 20070121
set system_type ""

#Expects:
#  date (required but empty string okay): YYYY-MM-DD
#  show_calendar_name_p (optional): 0 or 1
#  start_display_hour (optional): 0-23
#  end_display_hour (optional): 0-23

#Display constants, should match up with default styles in calendar.css.
set hour_height_inside 43
set hour_height_sep 3
set hour_height_units px
set bump_right_base 0
set bump_right_delta 155
set bump_right_units px

set current_date $date
set pretty_date [lc_time_fmt $current_date %Q]

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


multirow create items \
    all_day_p \
    style_class \
    event_name \
    event_url \
    description \
    calendar_name \
    weekday \
    start_date \
    end_date \
    start_time \
    end_time \
    top \
    height \
    style \
    num_attachments

set previous_intervals [list]

# Loop through the items without time

set additional_limitations_clause " and to_char(start_date, 'HH24:MI') = to_char(end_date, 'HH24:MI')"
if { [exists_and_not_null cal_system_type] } {
    append additional_limitations_clause " and system_type = :cal_system_type "
}
set additional_select_clause ""
set order_by_clause " order by name"
set interval_limitation_clause [db_map dbqd.calendar.www.views.day_interval_limitation] 

#AG: the "select_all_day_items" query is identical to "select_items"
#just without the Oracle +ORDERED hint, which speeds every other
#query but slows this one.
db_foreach dbqd.calendar.www.views.select_all_day_items {} {


    # Localize
    set pretty_weekday [lc_time_fmt $ansi_start_date "%A"]
    set pretty_start_date [lc_time_fmt $ansi_start_date "%x"]
    set pretty_end_date [lc_time_fmt $ansi_end_date "%x"]
    set pretty_start_time [lc_time_fmt $ansi_start_date "%X"]
    set pretty_end_time [lc_time_fmt $ansi_end_date "%X"]
    
    set event_url [export_vars -base [site_node::get_url_from_object_id -object_id $cal_package_id]cal-item-view {return_url {cal_item_id $item_id}}]

    #height will be overwritten once we know how the vertical hour span.
    multirow append items 1 "calendar-${system_type}Item" \
        $name \
        $event_url \
        $description \
        $calendar_name \
        $pretty_weekday \
        $pretty_start_date \
        $pretty_end_date \
        $pretty_start_time \
        $pretty_end_time \
        0 \
        0 \
        "left: ${bump_right_base}${bump_right_units};" \
	$num_attachments

    incr bump_right_base $bump_right_delta
}

set additional_limitations_clause " and to_char(start_date, 'HH24:MI') <> to_char(end_date, 'HH24:MI')"
if { [exists_and_not_null cal_system_type] } {
    append additional_limitations_clause " and system_type = :cal_system_type "
}
set order_by_clause " order by to_char(start_date,'HH24:MI')"
set day_items_per_hour {}

set adjusted_start_display_hour $start_display_hour
set adjusted_end_display_hour $end_display_hour

db_foreach dbqd.calendar.www.views.select_items {} {

    set ansi_start_date [lc_time_system_to_conn $ansi_start_date]
    set ansi_end_date [lc_time_system_to_conn $ansi_end_date]

    # Localize
    set pretty_weekday [lc_time_fmt $ansi_start_date "%A"]
    set pretty_start_date [lc_time_fmt $ansi_start_date "%x"]
    set pretty_end_date [lc_time_fmt $ansi_end_date "%x"]
    set pretty_start_time [lc_time_fmt $ansi_start_date "%X"]
    set pretty_end_time [lc_time_fmt $ansi_end_date "%X"]

    set start_time [lc_time_fmt $ansi_start_date "%X"]
    set end_time [lc_time_fmt $ansi_end_date "%X"]

    scan [lc_time_fmt $ansi_start_date "%H"] %d start_hour 
    scan [lc_time_fmt $ansi_end_date "%H"] %d end_hour 

    if { $start_hour < $adjusted_start_display_hour && \
             [string equal \
                  [string range $ansi_start_date 0 9] \
                  [string range $ansi_end_date 0 9]] } {
        set adjusted_start_display_hour $start_hour
    }

    if { $end_hour > $adjusted_end_display_hour && \
             [string equal \
                  [string range $ansi_start_date 0 9] \
                  [string range $ansi_end_date 0 9]] } {
        set adjusted_end_display_hour $end_hour
    }

    set top [expr ($start_hour * ($hour_height_inside+$hour_height_sep)) \
                 + ($start_minutes*$hour_height_inside/60)]
    set bottom [expr ($end_hour * ($hour_height_inside+$hour_height_sep)) \
                 + ($end_minutes*$hour_height_inside/60)]
    set height [expr $bottom - $top - 2]

    set bump_right $bump_right_base
    foreach {previous_start previous_end} $previous_intervals {
        if { ($start_seconds >= $previous_start && $start_seconds < $previous_end) || ($previous_start >= $start_seconds && $previous_start < $end_seconds) } {
                incr bump_right $bump_right_delta
        }
    }

    set event_url [export_vars -base [site_node::get_url_from_object_id -object_id $cal_package_id]cal-item-view {return_url {cal_item_id $item_id}}]

    multirow append items 0 "calendar-${system_type}Item" \
        "$name ($start_time - $end_time)" \
        $event_url \
        $description \
        $calendar_name \
        $pretty_weekday \
        $pretty_start_date \
        $pretty_end_date \
        $pretty_start_time \
        $pretty_end_time \
        $top \
        $height \
        "left: ${bump_right}${bump_right_units};" \
	$num_attachments
    
    lappend previous_intervals $start_seconds $end_seconds
}

#Now correct the top attribute for the adjusted start.
set num_items [multirow size items]
for {set i 1} {$i <= $num_items } {incr i} {
    if { [multirow get items $i all_day_p] } {
        multirow set items $i height \
            [expr ($adjusted_end_display_hour-$adjusted_start_display_hour+1)*($hour_height_inside+$hour_height_sep)]
    } else {
        set currval [multirow get items $i top]
        multirow set items $i top \
            [expr $currval - ($adjusted_start_display_hour*($hour_height_inside+$hour_height_sep))]
    }
}

db_1row dbqd.calendar.www.views.select_day_info {}


set dates [lc_time_fmt $date "%q"]
set curr_day_name [lc_time_fmt $date "%A"]
set curr_month [lc_time_fmt $date "%B"]
set curr_day [lc_time_fmt $date "%d"]
set curr_year [lc_time_fmt $date "%Y"]

#Calendar grid.
set grid_start $adjusted_start_display_hour
set grid_first_hour [lc_time_fmt "$current_date $grid_start:00:00" "%X"]
set grid_hour $grid_start
set grid_first_add_url [export_vars -base ${calendar_url}cal-item-new \
                           {{date $current_date} {start_time $grid_hour}}]
incr grid_start

multirow create grid hour add_url
for { set grid_hour $grid_start } { $grid_hour <= $adjusted_end_display_hour } { incr grid_hour } {
    set localized_grid_hour [lc_time_fmt "$current_date $grid_hour:00:00" "%X"]
    multirow append grid $localized_grid_hour \
        [export_vars -base ${calendar_url}cal-item-new {{date $current_date} {start_time $grid_hour}}]
}

if { [info exists export] && [string equal $export print] } {
    set print_html [template::adp_parse [acs_root_dir]/packages/calendar/www/view-print-display [list &items items show_calendar_name_p $show_calendar_name_p]]
    ns_return 200 text/html $print_html
    ad_script_abort
}
