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
set cal_item(no_time_p) [dt_no_time_p -start_time $cal_item(start_time) -end_time $cal_item(end_time)]

set date $cal_item(start_date)
ad_return_template
