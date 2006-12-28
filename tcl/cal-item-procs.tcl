# /packages/calendar/tcl/cal-item-procs.tcl

ad_library {

    Utility functions for Calendar Applications

    @author Dirk Gomez (openacs@dirkgomez.de)
    @author Gary Jin (gjin@arsdigita.com)
    @author Ben Adida (ben@openforce.net)
    @creation-date Jan 11, 2001
    @cvs-id $Id$

}

namespace eval calendar {}
namespace eval calendar::item {}

ad_proc -private calendar::item::dates_valid_p {
    {-start_date:required}
    {-end_date:required}
} {
    A sanity check that the start time is before the end time. 
} {
    set dates_valid_p [db_string dates_valid_p_select {}]

    if {[string equal $dates_valid_p 1]} {
        return 1
    } else {
        return 0
    }
}

ad_proc -public calendar::item::new {
    {-start_date:required}
    {-end_date:required}
    {-name:required}
    {-description:required}
    {-calendar_id:required}
    {-item_type_id ""}
} {
    if {[dates_valid_p -start_date $start_date -end_date $end_date]} {
        set creation_ip [ad_conn peeraddr]
        set creation_user [ad_conn user_id]

        set activity_id [db_exec_plsql insert_activity {} ]
        
        # Convert from user timezone to system timezone
        set start_date [lc_time_conn_to_system $start_date]
        set end_date [lc_time_conn_to_system $end_date]        
        
        set timespan_id [db_exec_plsql insert_timespan {}]
        
        # create the cal_item
        # we are leaving the name and description fields in acs_event
        # blank to abide by the definition that an acs_event is an acs_activity
        # with added on temperoal information
        
        # by default, the cal_item permissions 
        # are going to be inherited from the calendar permissions
        set cal_item_id [db_exec_plsql cal_item_add {}]

        assign_permission  $cal_item_id  $creation_user read
        assign_permission  $cal_item_id  $creation_user write
        assign_permission  $cal_item_id  $creation_user delete
        assign_permission  $cal_item_id  $creation_user admin

        calendar::do_notifications -mode New -cal_item_id $cal_item_id
        return $cal_item_id

    } else {
        ad_return_complaint 1 [_ calendar.start_time_before_end_time]
        ad_script_abort
    }
}

ad_proc -public calendar::item::get {
    {-cal_item_id:required}
    {-array:required}
    {-normalize_time_to_utc 0}
} {
    Get the data for a calendar item

} {
    upvar $array row

    if {[calendar::attachments_enabled_p]} {
        set query_name select_item_data_with_attachment
    } else {
        set query_name select_item_data
    }

    db_1row $query_name {} -column_array row
    if {$normalize_time_to_utc} {
	set row(start_date_ansi) [lc_time_local_to_utc $row(start_date_ansi)]
	set row(end_date_ansi) [lc_time_local_to_utc $row(end_date_ansi)]
    } else {
	set row(start_date_ansi) [lc_time_system_to_conn $row(start_date_ansi)]
	set row(end_date_ansi) [lc_time_system_to_conn $row(end_date_ansi)]
    }

    if { $row(start_date_ansi) ==  $row(end_date_ansi) && [string equal [lc_time_fmt $row(start_date_ansi) "%T"] "00:00:00"]} {
        set row(time_p) 0
    } else {
        set row(time_p) 1
    }

    # Localize
    set row(start_time) [lc_time_fmt $row(start_date_ansi) "%X"]

    # Unfortunately, SQL has weekday starting at 1 = Sunday
    set row(start_date) [lc_time_fmt $row(start_date_ansi) "%Y-%m-%d"]
    set row(end_date) [lc_time_fmt $row(end_date_ansi) "%Y-%m-%d"]

    set row(day_of_week) [expr [lc_time_fmt $row(start_date_ansi) "%w"] + 1]
    set row(pretty_day_of_week) [lc_time_fmt $row(start_date_ansi) "%A"]
    set row(day_of_month) [lc_time_fmt $row(start_date_ansi) "%d"]
    set row(pretty_short_start_date) [lc_time_fmt $row(start_date_ansi) "%x"]
    set row(full_start_date) [lc_time_fmt $row(start_date_ansi) "%x"]
    set row(full_end_date) [lc_time_fmt $row(end_date_ansi) "%x"]

    set row(end_time) [lc_time_fmt $row(end_date_ansi) "%X"]
}

ad_proc -public calendar::item::add_recurrence {
    {-cal_item_id:required}
    {-interval_type:required}
    {-every_n:required}
    {-days_of_week ""}
    {-recur_until ""}
} {
    Adds a recurrence for a calendar item
} {
    db_transaction {
        set recurrence_id [db_exec_plsql create_recurrence {}]
        
        db_dml update_event {}
        
        db_exec_plsql insert_instances {}
        
        # Make sure they're all in the calendar!
        db_dml insert_cal_items {}
    }
}


ad_proc -public calendar::item::edit {
    {-cal_item_id:required}
    {-start_date:required}
    {-end_date:required}
    {-name:required}
    {-description:required}
    {-item_type_id ""}
    {-edit_all_p 0}
    {-calendar_id ""}
} {
    Edit the item

} {
    if {[dates_valid_p -start_date $start_date -end_date $end_date]} {
        if {$edit_all_p} {
            set recurrence_id [db_string select_recurrence_id {}]

            # If the recurrence id is NULL, then we stop here and just do the normal update
            if {![empty_string_p $recurrence_id]} {
                calendar::item::edit_recurrence \
                    -event_id $cal_item_id \
                    -start_date $start_date \
                    -end_date $end_date \
                    -name $name \
                    -description $description \
                    -item_type_id $item_type_id \
                    -calendar_id $calendar_id

                return
            }
        }

        # Convert from user timezone to system timezone
        set start_date [lc_time_conn_to_system $start_date]
        set end_date [lc_time_conn_to_system $end_date]        

        db_dml update_event {}

        # update the time interval based on the timespan id

        db_1row get_interval_id {}

        db_transaction {
            # call edit procedure
            db_exec_plsql update_interval {}
            
            # Update the item_type_id and calendar_id
            set colspecs [list]
            lappend colspecs "item_type_id = :item_type_id"
            if { ![empty_string_p $calendar_id] } {
                lappend colspecs "on_which_calendar = :calendar_id"

                db_dml update_context_id {
                    update acs_objects
                    set    context_id = :calendar_id
                    where  object_id = :cal_item_id
                }
            }
            
            db_dml update_item_type_id "
            update cal_items
            set    [join $colspecs ", "]
            where  cal_item_id= :cal_item_id
        "

        calendar::do_notifications -mode Edited -cal_item_id $cal_item_id
        }
    } else {
        ad_return_complaint 1 [_ calendar.start_time_before_end_time]
        ad_script_abort
    }
}

ad_proc -public calendar::item::delete {
    {-cal_item_id:required}
} {
    Delete the calendar item
} {
    db_exec_plsql delete_cal_item {}
}

ad_proc calendar::item::assign_permission { cal_item_id 
                                     party_id
                                     permission 
                                     {revoke ""}
} {
    update the permission of the specific cal_item
    if revoke is set to revoke, then we revoke all permissions
} {
    if { ![string equal $revoke "revoke"] } {
	if { ![string equal $permission "cal_item_read"] } {
            permission::grant -object_id $cal_item_id -party_id $party_id -privilege cal_item_read
	}
        permission::grant -object_id $cal_item_id -party_id $party_id -privilege $permission
    } elseif { [string equal $revoke "revoke"] } {
        permission::revoke -object_id $cal_item_id -party_id $party_id -privilege $permission

    }
}

ad_proc -public calendar::item::delete_recurrence {
    {-recurrence_id:required}
} {
    delete a recurrence
} {
    db_exec_plsql delete_cal_item_recurrence {}
}


ad_proc -public calendar::item::edit_recurrence {
    {-event_id:required}
    {-start_date:required}
    {-end_date:required}
    {-name:required}
    {-description:required}
    {-item_type_id ""}
    {-calendar_id ""}
} {
    edit a recurrence
} {
    set recurrence_id [db_string select_recurrence_id {}]
    
    db_transaction {
        db_exec_plsql recurrence_timespan_update {}

        db_dml recurrence_events_update {}
        
        set colspecs [list]
        lappend colspecs {item_type_id = :item_type_id}
        if { ![empty_string_p $calendar_id] } {
            lappend colspecs {on_which_calendar = :calendar_id}

            db_dml update_context_id {
                update acs_objects
                set    context_id = :calendar_id
                where  object_id in (select event_id from acs_events where recurrence_id = :recurrence_id)
            }
        }

        db_dml recurrence_items_update {}
    }
}

ad_proc -public calendar_item_add_recurrence {
    {-cal_item_id:required}
    {-interval_type:required}
    {-every_n:required}
    {-days_of_week ""}
    {-recur_until ""}
} {
    Adds a recurrence for a calendar item
} {
    # We do things in a transaction
    db_transaction {
        set recurrence_id [db_exec_plsql create_recurrence {}]
        
        db_dml update_event "update acs_events set recurrence_id= :recurrence_id where event_id= :cal_item_id"

        db_exec_plsql insert_instances {}
        
        # Make sure they're all in the calendar!
        db_dml insert_cal_items "
        insert into cal_items (cal_item_id, on_which_calendar)
        select event_id, (select on_which_calendar as calendar_id from cal_items where cal_item_id = :cal_item_id) from acs_events where recurrence_id= :recurrence_id and event_id <> :cal_item_id"
    }
}
