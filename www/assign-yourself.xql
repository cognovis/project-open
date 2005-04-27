<?xml version="1.0"?>
<queryset>

<fullquery name="task_info">      
      <querytext>
      
    select t.case_id, 
           t.workflow_key, 
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

 
<fullquery name="move_assignees">      
      <querytext>
      
    insert into wf_case_assignments
    (case_id, transition_key, workflow_key, party_id)
    select :case_id, :transition_key, :workflow_key, ta.party_id
    from   wf_task_assignments ta
    where  task_id = :task_id
    and not exists (select 1 from wf_case_assignments ca
                    where ca.party_id = ta.party_id
                    and   ca.workflow_key = :workflow_key
                    and   ca.case_id = :case_id
                    and   ca.transition_key = :transition_key)

      </querytext>
</fullquery>

 
<fullquery name="delete_self_case">      
      <querytext>
      
    delete from wf_case_assignments
    where  workflow_key   = :workflow_key
    and    case_id        = :case_id
    and    transition_key = :transition_key
    and    party_id       = :user_id

      </querytext>
</fullquery>

 
<fullquery name="delete_self_task">      
      <querytext>
      
    delete from wf_task_assignments
    where  party_id = :user_id
    and    task_id  = :task_id

      </querytext>
</fullquery>

 
</queryset>
