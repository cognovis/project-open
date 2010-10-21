# packages/calendar/tcl/test/cal-item-procs.tcl
ad_library {
    Tests for calendar::item API
}

aa_register_case -cats api cal_item_edit_recurrence {
    Test editing a recurring calendar item/event
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            # create a test calendar
            set calendar_id [calendar::create [ad_conn user_id] t]

            # create a recurrning calendar item
            set ci_start_date [clock format [clock seconds] -format "%Y-%m-%d"]
            set ci_end_date [clock format [clock scan "tomorrow" -base [clock seconds]] -format "%Y-%m-%d"]
            set recur_until [clock format [clock scan "10 days" -base [clock seconds]] -format "%Y-%m-%d"]
            set ci_name "name"
            set ci_description "description"
            set cal_item_id \
                [calendar::item::new \
                     -start_date $ci_start_date \
                     -end_date $ci_end_date \
                     -name $ci_name \
                     -description $ci_description \
                     -calendar_id $calendar_id]

            calendar::item::get \
                -cal_item_id $cal_item_id -array cal_item
            aa_true "Name is correct" [string equal $ci_name $cal_item(name)]
            aa_true "Description is correct" [string equal $ci_description $cal_item(description)]
            # edit the time of the event
            set recurrence_id \
                [calendar::item::add_recurrence \
                     -cal_item_id $cal_item_id \
                     -interval_type "day" \
                     -every_n 1 \
                     -days_of_week "" \
                     -recur_until $recur_until]
          
            aa_log "Recurrence_id = '${recurrence_id}'" 

            # compare recurrent events
            set passed 1
            set recurrence_event_ids [list]
            set name ""
            set recurrence_event_ids [db_list q "select cal_item_id as cal_item_id from acs_events, cal_items where cal_item_id=event_id and recurrence_id=:recurrence_id" ]
            foreach event_id $recurrence_event_ids {
                 calendar::item::get -cal_item_id $event_id -array cal_item
                set passed [expr {$passed && [string equal $ci_name $cal_item(name)]}]
# for some reason the description is not set                

                set passed [expr {$passed && [string equal $ci_description $cal_item(description)]}]
                lappend recurrence_event_ids $event_id
            }
            aa_true "Name correct on all recurrences" $passed
            # aa_log $recurrence_event_ids
            # update time only 
            set ci_start_date [clock format [clock scan "1 month" -base [clock scan $ci_start_date]] -format "%Y-%m-%d"]
            set ci_end_date [clock format [clock scan "1 month" -base [clock scan $ci_end_date]] -format "%Y-%m-%d"]
    
            calendar::item::edit \
                -cal_item_id $cal_item_id \
                -start_date $ci_start_date \
                -end_date $ci_end_date \
                -name $ci_name \
                -description $ci_description \
                -edit_all_p t
           
            set passed 1

            foreach event_id $recurrence_event_ids {
                 calendar::item::get -cal_item_id $event_id -array cal_item
                set passed [expr {$passed && [string equal $ci_name $cal_item(name)]}]
# for some reason the description is not set                
                set passed [expr {$passed && [string equal $ci_description $cal_item(description)]}]
            }
            aa_true "Name correct on all recurrences 2" $passed

            # Update name to be unique per instance
            # aa_log "Recurrence event_ids $recurrence_event_ids"
            foreach event_id $recurrence_event_ids {
                calendar::item::get -cal_item_id $event_id -array cal_item
                set new_names($event_id) "name $event_id"
                calendar::item::edit \
                    -cal_item_id $event_id \
                    -start_date $cal_item(start_date) \
                    -end_date $cal_item(end_date) \
                    -name $new_names($event_id) \
                    -description $cal_item(description)
            }
            set passed 1

            foreach event_id $recurrence_event_ids {
                 calendar::item::get -cal_item_id $event_id -array cal_item
                set passed [expr {$passed && [string equal $new_names($event_id) $cal_item(name)]}]
# for some reason the description is not set                
                set passed [expr {$passed && [string equal $ci_description $cal_item(description)]}]
            }
            aa_true "New individual names are correct" $passed
            
            # don't edit name!
            calendar::item::get -cal_item_id $cal_item_id -array cal_item
            calendar::item::edit \
                -cal_item_id $cal_item_id \
                -start_date $ci_start_date \
                -end_date $ci_end_date \
                -name $cal_item(name) \
                -description $cal_item(description) \
                -edit_all_p t

            set passed 1
            foreach event_id $recurrence_event_ids {
                 calendar::item::get -cal_item_id $event_id -array cal_item
                set passed [expr {$passed && [string equal $new_names($event_id) $cal_item(name)]}]
                set passed [expr {$passed && [string equal $ci_description $cal_item(description)]}]
            }
            aa_true "Edited item and New individual names are correct" $passed

            calendar::item::edit \
                -cal_item_id $cal_item_id \
                -start_date $ci_start_date \
                -end_date $ci_end_date \
                -name "New Name" \
                -description $cal_item(description) \
                -edit_all_p t

            set passed 1
            foreach event_id $recurrence_event_ids {
                 calendar::item::get -cal_item_id $event_id -array cal_item
                set passed [expr {$passed && [string equal "New Name" $cal_item(name)]}]
                set passed [expr {$passed && [string equal $ci_description $cal_item(description)]}]
            }
            aa_true "Edited item name and New individual names are updated" $passed


        }
}