ad_page_contract {
    Update task attributes.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 19, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    {context_key "default"}
    return_url 
    enable_callback
    enable_custom_arg
    fire_callback
    fire_custom_arg
    time_callback
    time_custom_arg
    deadline_callback
    deadline_custom_arg
    deadline_attribute_name
    hold_timeout_callback
    hold_timeout_custom_arg
    notification_callback
    notification_custom_arg
    unassigned_callback
    unassigned_custom_arg 
}


set num_rows [db_string num_rows "select count(*) from wf_context_transition_info where workflow_key = :workflow_key and transition_key = :transition_key and context_key = :context_key"]

if { $num_rows == 0 } {
    db_dml insert_actions {
        insert into wf_context_transition_info
        (workflow_key, 
         transition_key, 
         context_key, 
         enable_callback,
         enable_custom_arg,
         fire_callback,
         fire_custom_arg,
         time_callback,
         time_custom_arg,
         deadline_callback,
         deadline_custom_arg,
         deadline_attribute_name,
         hold_timeout_callback,
         hold_timeout_custom_arg,
         notification_callback,
         notification_custom_arg,
         unassigned_callback,
         unassigned_custom_arg)
        values 
        (:workflow_key, 
         :transition_key, 
         :context_key, 
         :enable_callback,
         :enable_custom_arg,
         :fire_callback,
         :fire_custom_arg,
         :time_callback,
         :time_custom_arg,
         :deadline_callback,
         :deadline_custom_arg,
         :deadline_attribute_name,
         :hold_timeout_callback,
         :hold_timeout_custom_arg,
         :notification_callback,
         :notification_custom_arg,
         :unassigned_callback,
         :unassigned_custom_arg)
    }
} else {
    db_dml update_actions {
        update wf_context_transition_info set 
        enable_callback = :enable_callback,
        enable_custom_arg = :enable_custom_arg,
        fire_callback = :fire_callback,
        fire_custom_arg = :fire_custom_arg,
        time_callback = :time_callback,
        time_custom_arg = :time_custom_arg,
        deadline_callback = :deadline_callback,
        deadline_custom_arg = :deadline_custom_arg,
        deadline_attribute_name = :deadline_attribute_name,
        hold_timeout_callback = :hold_timeout_callback,
        hold_timeout_custom_arg = :hold_timeout_custom_arg,
        notification_callback = :notification_callback,
        notification_custom_arg = :notification_custom_arg,
        unassigned_callback = :unassigned_callback,
        unassigned_custom_arg = :unassigned_custom_arg
        where workflow_key = :workflow_key and transition_key = :transition_key and context_key = :context_key
    }
}


ad_returnredirect $return_url






