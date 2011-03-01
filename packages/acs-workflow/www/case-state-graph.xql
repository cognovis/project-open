<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_key_from_case_id">      
      <querytext>
       select workflow_key from wf_cases where case_id = :case_id 
      </querytext>
</fullquery>

 
<fullquery name="tokens">      
      <querytext>

    select tok.token_id, 
           tok.place_key,
           tok.locked_task_id,
           ta.transition_key
    from   wf_tokens tok left outer join wf_tasks ta on (ta.task_id = tok.locked_task_id)
    where  tok.case_id = :case_id
    and    tok.state in ('free', 'locked')

      </querytext>
</fullquery>

 
</queryset>
