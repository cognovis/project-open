ad_page_contract {
    
    Viewing Calendar Information. Currently offers list, day, week, month view.
    
    @author Dirk Gomez (openacs@dirkgomez.de)
    @author Ben Adida (ben@openforce.net)
    @creation-date May 29, 2002
    @cvs-id $Id$
} {
    {view {[parameter::get -parameter DefaultView -default day]}}
    {date ""}
    {sort_by ""}
    {start_date ""}
    {period_days:integer {[parameter::get -parameter ListView_DefaultPeriodDays -default 31]}}
} -validate {
    valid_date -requires { date } {
        if {![string equal $date ""]} {
            if {[catch {set date [clock format [clock scan $date] -format "%Y-%m-%d"]} err]} {
                ad_complain "Your input was not valid. It has to be in the form YYYYMMDD."
            }
        }
    }
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

# HAM : try to create a return url back here after creating a new item
set return_url [ad_urlencode [ad_return_url]]

set admin_p [permission::permission_p -object_id $package_id -privilege calendar_admin]

set show_calendar_name_p [parameter::get -parameter Show_Calendar_Name_p -default 1]

set date [calendar::adjust_date -date $date]

if {$view == "list"} {
    if {[empty_string_p $start_date]} {
        set start_date $date
    }

    set ansi_list [split $start_date "- "]
    set ansi_year [lindex $ansi_list 0]
    set ansi_month [string trimleft [lindex $ansi_list 1] "0"]
    set ansi_day [string trimleft [lindex $ansi_list 2] "0"]
    set end_date [dt_julian_to_ansi [expr [dt_ansi_to_julian $ansi_year $ansi_month $ansi_day ] + $period_days]]
}

set notification_chunk [notification::display::request_widget \
                            -type calendar_notif \
                            -object_id $package_id \
                            -pretty_name [ad_conn instance_name] \
                            -url [ad_conn url] \
                           ]


ad_return_template 
