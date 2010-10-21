#
# A script that assumes
#
# cal_item_id
#
# This will pull out information about the event and 
# display it with some options.
#

ad_page_contract {
    Confirm Deletion
} {
    cal_item_id
}

auth::require_login

calendar::item::get -cal_item_id $cal_item_id -array cal_item

# no time?
set cal_item(no_time_p) [expr {!$cal_item(time_p)}]

set date $cal_item(start_date)

# Header stuff
template::head::add_css -href "/resources/calendar/calendar.css" -media all
template::head::add_css -alternate -href "/resources/calendar/calendar-hc.css" -title "highContrast"


set view_url [export_vars -base "view" {{view day} {date $cal_item(start_date)}}]

if {  $cal_item(recurrence_id) ne "" } {
    set delete_one [export_vars -base "cal-item-delete" {cal_item_id {confirm_p 1}}]
    set delete_all [export_vars -base "cal-item-delete-all-occurrences" {{recurrence_id $cal_item(recurrence_id)}}]
} else {
    set delete_confirm [export_vars -base "cal-item-delete" {cal_item_id {confirm_p 1}}]
    set delete_cancel [export_vars -base "cal-item-view" {cal_item_id}]
}

ad_return_template
