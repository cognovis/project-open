<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="tokens">      
      <querytext>
      
    select tok.token_id, 
           tok.place_key,
           tok.locked_task_id,
           ta.transition_key
    from   wf_tokens tok,
           wf_tasks ta
    where  tok.case_id = :case_id
    and    ta.task_id (+) = tok.locked_task_id
    and    tok.state in ('free', 'locked')

      </querytext>
</fullquery>

 
</queryset>
