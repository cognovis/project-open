<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="workflow_approve">      
      <querytext>

        select content_workflow__approve(
                       :task_id,
                       :user_id,
                       :ip_address,
                       :msg
                 );
            
      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
  select content_workflow__can_approve( :task_id, :user_id ) 

      </querytext>
</fullquery>

 
<fullquery name="get_task_info">      
      <querytext>
      
  select
    c.object_id, content_item__get_title(c.object_id,'f') as title, 
    tr.transition_name
  from
    wf_tasks tk, wf_cases c,
    wf_transitions tr
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.workflow_key = tr.workflow_key
  and
    tk.workflow_key = 'publishing_wf'
  and
    c.case_id = tk.case_id
  and
    content_workflow__can_approve( tk.task_id, :user_id ) = 't'

      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
             select content_workflow__can_approve( :task_id, :user_id ) 
      </querytext>
</fullquery>

 
</queryset>
