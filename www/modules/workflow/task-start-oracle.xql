<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="workflow_checkout">      
      <querytext>
      
      begin
      content_workflow.checkout(
          task_id      => :task_id,             
          hold_timeout => $hold_timeout_sql,
          user_id      => :user_id,
          ip_address   => :ip_address,
          msg          => :msg
      );
      end;
    
      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
  select content_workflow.can_start( :task_id, :user_id ) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_task_info">      
      <querytext>
      
  select
    c.object_id, tr.transition_name,
    content_item.get_title(c.object_id) title,
    tk.holding_user as holding_user, 
    to_char(tk.hold_timeout,'Mon. DD, YYYY') hold_timeout,
    content_workflow.get_holding_user_name(tk.task_id) holding_user_name
  from
    wf_tasks tk,
    wf_transitions tr,
    wf_cases c
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.case_id = c.case_id

      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
      select content_workflow.can_start( :task_id, :user_id ) from dual
      </querytext>
</fullquery>

 
</queryset>
