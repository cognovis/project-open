<?xml version="1.0"?>
<queryset>

<fullquery name="tasks">      
      <querytext>

    select task_id, transition_key, state, case_id
    from   wf_tasks
    where  case_id = :case_id
    order by case when state = 'started' then 1 when state = 'enabled' then 2 when state = 'finished' then 3 else 4 end

      </querytext>
</fullquery>

 
<fullquery name="live_tokens">      
      <querytext>
      
    select token_id, place_key, case_id, state, locked_task_id
    from   wf_tokens
    where  case_id = :case_id
    and    state in ('free', 'locked')

      </querytext>
</fullquery>

 
<fullquery name="enabled_transitions">      
      <querytext>
      
    select case_id, transition_key, transition_name, trigger_type
    from   wf_enabled_transitions
    where  case_id = :case_id

      </querytext>
</fullquery>

 
</queryset>
