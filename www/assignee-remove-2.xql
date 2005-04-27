<?xml version="1.0"?>
<queryset>

<fullquery name="task_info">      
      <querytext>
      
    select t.case_id, 
           t.transition_key, 
           c.object_id, 
           wcti.access_privilege
    from   wf_tasks t, wf_cases c, wf_context_transition_info wcti
    where  wcti.context_key = c.context_key
    and    wcti.workflow_key = t.workflow_key
    and    wcti.transition_key = t.transition_key
    and    c.case_id = t.case_id
    and    t.task_id = :task_id

      </querytext>
</fullquery>

 
<fullquery name="this_user_is_assigned_p">      
      <querytext>
       
    select count(*) from wf_user_tasks  where task_id = :task_id and user_id = :user_id

      </querytext>
</fullquery>

 
</queryset>
