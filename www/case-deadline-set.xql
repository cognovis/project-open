<?xml version="1.0"?>
<queryset>

<fullquery name="transition_name_select">      
      <querytext>
      
select transition_name
from wf_transitions
where transition_key = :transition_key
      and workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="deadline_select">      
      <querytext>
      
    select deadline
      from wf_case_deadlines
     where case_id = :case_id
       and transition_key = :transition_key
       and workflow_key = :workflow_key

      </querytext>
</fullquery>

 
</queryset>
