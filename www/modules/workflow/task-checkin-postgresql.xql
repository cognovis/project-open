<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="workflow_checkin">      
      <querytext>

        select content_workflow__checkin(
          :task_id,             
          :user_id,
          :ip_address,
          :msg
      );
      
    
      </querytext>
</fullquery>

 
<fullquery name="check_valid">      
      <querytext>
      
  select content_workflow__can_approve( :task_id, :user_id ) 

      </querytext>
</fullquery>

 
<fullquery name="get_task_info">      
      <querytext>
      
  select
    c.object_id, tr.transition_name,
    content_item__get_title(c.object_id, 'f') as title,
    tk.holding_user as holding_user, 
    to_char(tk.hold_timeout,'Mon. DD, YYYY') as hold_timeout,
    content_workflow__get_holding_user_name(tk.task_id) as holding_user_name
  from
    wf_tasks tk, wf_transitions tr, wf_cases c
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.case_id = c.case_id

      </querytext>
</fullquery>

 
<fullquery name="get_task_status">      
      <querytext>
      
      select content_workflow__can_approve( :task_id, :user_id ) 
    
      </querytext>
</fullquery>

 
</queryset>
