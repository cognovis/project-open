<?xml version="1.0"?>
<queryset>

<fullquery name="num_rows">      
      <querytext>
      select count(*) from wf_context_transition_info where workflow_key = :workflow_key and transition_key = :transition_key and context_key = :context_key
      </querytext>
</fullquery>

 
<fullquery name="insert_actions">      
      <querytext>
      
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
    
      </querytext>
</fullquery>

 
<fullquery name="update_actions">      
      <querytext>
      
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
    
      </querytext>
</fullquery>

 
</queryset>
