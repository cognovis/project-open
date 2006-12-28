
# /packages/calendar/www/cal-item-create.tcl

ad_page_contract {
    
    Creation of new recurrence for cal item
    
    @author Ben Adida (ben@openforce.net)
    @creation-date 10 Mar 2002
    @cvs-id $Id$
} {
    cal_item_id
    {return_url "./"}
    {days_of_week:multiple ""}
} 


auth::require_login
ad_require_permission $cal_item_id cal_item_write

calendar::item::get -cal_item_id $cal_item_id -array cal_item

set dow_string ""
foreach dow [list [list "#calendar.Sunday#" 0] [list "#calendar.Monday#" 1] [list "#calendar.Tuesday#" 2] [list "#calendar.Wednesday#" 3] [list "#calendar.Thursday#" 4] [list "#calendar.Friday#" 5] [list "#calendar.Saturday#" 6]] {
        if {[lindex $dow 1] == [expr "$cal_item(day_of_week) -1"]} {
                set checked_html "CHECKED"
        } else {
                set checked_html ""
        }

        set dow_string "$dow_string <INPUT TYPE=checkbox name=days_of_week value=[lindex $dow 1] $checked_html id=\"cal_item:elements:interval_type:days_of_week\" >[lindex $dow 0] &nbsp;\n"
}

set recurrance_options [list \
                            [list [_ calendar.day_s] day] \
                            [list "$dow_string [_ calendar.of_the_week]" week] \
                            [list "[_ calendar.day] $cal_item(day_of_month) [_ calendar.of_the_month]" month_by_date] \
                            [list "[_ calendar.same] $cal_item(pretty_day_of_week) [_ calendar.of_the_month]" month_by_day] \
                            [list [_ calendar.year] year]]



ad_form -name cal_item  -export {return_url} -form {
    {cal_item_id:key}

    {every_n:integer,optional
        {label "[_ calendar.Repeat_every]"}
        {value 1}
        {html {size 4}} 
    }

    {interval_type:text(radio)
        {label ""}
        {options $recurrance_options}
    }

    {recur_until:text,text
        {label "[_ calendar.lt_Repeat_this_event_unt]"}
	{html {id sel1}}
	{after_html {<input type='reset' value=' ... ' onclick=\"return showCalendar('sel1', 'y-m-d');\"> \[<b>y-m-d </b>\]
        }}

    }

    {submit:text(submit) {label "[_ calendar.Add_Recurrence]"}}

} -validate {
    {recur_until
        {
            [calendar::item::dates_valid_p -start_date $cal_item(start_date) -end_date $recur_until]
        }
       {[_ calendar.start_time_before_end_time]}
    }
} -edit_data {

    # To support green calendar
    set recur_until [split $recur_until "-"]
    lappend recur_until ""
    lappend recur_until ""
    lappend recur_until ""
    lappend recur_until "DD MONTH YYYY"
 
    calendar::item::add_recurrence \
        -cal_item_id $cal_item_id \
        -interval_type $interval_type \
        -every_n $every_n \
        -days_of_week $days_of_week \
        -recur_until [calendar::to_sql_datetime -date $recur_until -time "" -time_p 0]
} -edit_request {
    set aux [template::util::date::from_ansi $cal_item(start_date)]
    set recur_until [lindex $aux 0]
    append recur_until "-"
    append recur_until [lindex $aux 1]
    append recur_until "-"
    append recur_until [lindex $aux 2]
    set interval_type week
} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
} -has_submit 1


ad_return_template

